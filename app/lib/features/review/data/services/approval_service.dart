import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/extracted_item_model.dart';

final approvalServiceProvider = Provider<ApprovalService>((ref) {
  return ApprovalService(FirebaseFirestore.instance);
});

/// Commits an approved ExtractedItem into the proper Firestore collection
/// (events, tasks, deadlines, payments, forms, etc.)
class ApprovalService {
  final FirebaseFirestore _firestore;

  ApprovalService(this._firestore);

  /// Approve an item: update its status and commit to the household plan
  Future<void> approveAndCommit(
    String householdId,
    ExtractedItemModel item, {
    String? ownerId,
    String? ownerName,
  }) async {
    final batch = _firestore.batch();

    // 1. Update the extracted item status
    final itemRef = _firestore
        .collection('households')
        .doc(householdId)
        .collection('extractedItems')
        .doc(item.id);

    batch.update(itemRef, {
      'reviewStatus': 'approved',
      'reviewedAt': Timestamp.now(),
      if (ownerId != null) 'assignedOwnerId': ownerId,
      if (ownerName != null) 'assignedOwnerName': ownerName,
    });

    // 1b. Check if all extracted items for this source are reviewed
    //     If so, mark the source message as 'approved' so it leaves the Feed
    if (item.sourceMessageId != null) {
      final sourceRef = _firestore
          .collection('households')
          .doc(householdId)
          .collection('sourceMessages')
          .doc(item.sourceMessageId);
      batch.update(sourceRef, {'processingStatus': 'approved'});
    }

    // 2. Create the committed object in the appropriate collection
    final committedData = _buildCommittedObject(item, ownerId, ownerName);
    final collection = _getCollectionName(item.itemType);

    if (collection != null && committedData != null) {
      final committedRef = _firestore
          .collection('households')
          .doc(householdId)
          .collection(collection)
          .doc();

      batch.set(committedRef, {
        ...committedData,
        'sourceExtractedItemId': item.id,
        'sourceMessageId': item.sourceMessageId,
        'affectedMemberId': item.affectedMemberId,
        'affectedMemberName': item.affectedMemberName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'householdId': householdId,
        'createdAt': Timestamp.now(),
        'status': 'confirmed',
      });
    }

    await batch.commit();
  }

  String? _getCollectionName(ExtractedItemType type) => switch (type) {
        ExtractedItemType.event => 'events',
        ExtractedItemType.task => 'tasks',
        ExtractedItemType.deadline => 'deadlines',
        ExtractedItemType.payment => 'payments',
        ExtractedItemType.form => 'forms',
        ExtractedItemType.checklist => 'checklists',
        ExtractedItemType.requiredItem => 'requiredItems',
        ExtractedItemType.change => 'changes',
        ExtractedItemType.risk => 'risks',
        ExtractedItemType.locationUpdate => 'events', // treat location updates as event updates
        ExtractedItemType.routineSuggestion => 'tasks', // treat routine suggestions as tasks
      };

  Map<String, dynamic>? _buildCommittedObject(
    ExtractedItemModel item,
    String? ownerId,
    String? ownerName,
  ) {
    // Extract field values from the extracted fields list
    final fields = <String, String?>{};
    for (final f in item.extractedFields) {
      fields[f.name.toLowerCase()] = f.value;
    }

    switch (item.itemType) {
      case ExtractedItemType.event:
        return {
          'title': fields['event'] ?? fields['title'] ?? item.operationalSummary,
          'location': fields['location'],
          'startDateTime': _parseDateTime(fields['date'], fields['time']),
          'endDateTime': null,
          'recurrence': fields['recurrence'],
        };

      case ExtractedItemType.task:
        return {
          'title': fields['task'] ?? fields['title'] ?? item.operationalSummary,
          'description': item.operationalSummary,
          'dueDate': _parseDateTime(fields['due date'] ?? fields['date'], fields['time']),
          'priority': fields['priority'] ?? 'medium',
        };

      case ExtractedItemType.deadline:
        return {
          'title': fields['deadline'] ?? fields['title'] ?? item.operationalSummary,
          'dueDateTime': _parseDateTime(fields['due date'] ?? fields['date'], fields['time']),
          'urgencyLevel': fields['urgency'] ?? 'medium',
        };

      case ExtractedItemType.payment:
        return {
          'title': fields['payment'] ?? fields['title'] ?? item.operationalSummary,
          'amount': double.tryParse(fields['amount'] ?? ''),
          'currency': fields['currency'] ?? 'EUR',
          'dueDate': _parseDateTime(fields['due date'] ?? fields['date'], null),
          'paymentMethod': fields['method'] ?? fields['payment method'],
          'paymentLink': fields['link'] ?? fields['payment link'],
        };

      case ExtractedItemType.form:
        return {
          'title': fields['form'] ?? fields['title'] ?? item.operationalSummary,
          'requiredAction': fields['action'] ?? fields['required action'] ?? 'submit',
          'dueDate': _parseDateTime(fields['due date'] ?? fields['date'], null),
          'submissionMethod': fields['method'] ?? fields['submission method'],
        };

      case ExtractedItemType.checklist:
        return {
          'title': fields['checklist'] ?? fields['title'] ?? item.operationalSummary,
          'items': item.extractedFields
              .where((f) => f.name.toLowerCase().contains('item'))
              .map((f) => {'name': f.value, 'isCompleted': false})
              .toList(),
        };

      case ExtractedItemType.requiredItem:
        return {
          'name': fields['item'] ?? fields['name'] ?? item.operationalSummary,
          'quantity': fields['quantity'] ?? '1',
          'category': fields['category'],
          'neededByDateTime': _parseDateTime(fields['date'], fields['time']),
          'packedStatus': 'notReady',
        };

      case ExtractedItemType.change:
        return {
          'changeType': item.changeType ?? fields['change type'],
          'previousValue': item.previousValue ?? fields['previous'],
          'newValue': item.newValue ?? fields['new'],
          'relatedObjectType': item.relatedObjectType,
          'relatedObjectId': item.relatedObjectId,
          'impactLevel': 'medium',
          'reviewStatus': 'confirmed',
        };

      case ExtractedItemType.risk:
        return {
          'title': fields['risk'] ?? fields['title'] ?? item.operationalSummary,
          'description': item.operationalSummary,
          'type': item.riskType ?? fields['type'],
          'severity': item.riskSeverity ?? fields['severity'] ?? 'medium',
          'suggestedAction': item.suggestedActions.isNotEmpty
              ? item.suggestedActions.first
              : null,
        };

      default:
        return {'title': item.operationalSummary};
    }
  }

  /// Try to parse a date/time from extracted field strings
  Timestamp? _parseDateTime(String? date, String? time) {
    if (date == null) return null;

    try {
      // Try direct ISO parse
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return Timestamp.fromDate(parsed);

      // Try relative dates
      final now = DateTime.now();
      final lower = date.toLowerCase().trim();

      if (lower == 'today') return Timestamp.fromDate(now);
      if (lower == 'tomorrow') {
        return Timestamp.fromDate(now.add(const Duration(days: 1)));
      }

      // Try day names
      final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final dayIndex = days.indexOf(lower);
      if (dayIndex != -1) {
        final currentDay = now.weekday; // 1=Mon, 7=Sun
        var daysUntil = (dayIndex + 1) - currentDay;
        if (daysUntil <= 0) daysUntil += 7;
        return Timestamp.fromDate(now.add(Duration(days: daysUntil)));
      }

      // Try "next [day]"
      if (lower.startsWith('next ')) {
        final dayName = lower.substring(5);
        final idx = days.indexOf(dayName);
        if (idx != -1) {
          final currentDay = now.weekday;
          var daysUntil = (idx + 1) - currentDay;
          if (daysUntil <= 0) daysUntil += 7;
          return Timestamp.fromDate(now.add(Duration(days: daysUntil)));
        }
      }
    } catch (_) {}

    return null;
  }
}
