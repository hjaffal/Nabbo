import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/extracted_item_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(FirebaseFirestore.instance);
});

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository(this._firestore);

  CollectionReference _extractedItemsRef(String householdId) => _firestore
      .collection('households')
      .doc(householdId)
      .collection('extractedItems');

  /// Watch all pending review items, sorted by urgency
  Stream<List<ExtractedItemModel>> watchPendingItems(String householdId) {
    return _extractedItemsRef(householdId)
        .where('reviewStatus', isEqualTo: ReviewStatus.pendingReview.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExtractedItemModel.fromFirestore(doc))
            .toList());
  }

  /// Get a single extracted item
  Future<ExtractedItemModel?> getExtractedItem(
      String householdId, String itemId) async {
    final doc = await _extractedItemsRef(householdId).doc(itemId).get();
    if (!doc.exists) return null;
    return ExtractedItemModel.fromFirestore(doc);
  }

  /// Approve an item
  Future<void> approveItem(String householdId, String itemId) async {
    await _extractedItemsRef(householdId).doc(itemId).update({
      'reviewStatus': ReviewStatus.approved.name,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Dismiss an item
  Future<void> dismissItem(
      String householdId, String itemId, String? reason) async {
    await _extractedItemsRef(householdId).doc(itemId).update({
      'reviewStatus': ReviewStatus.dismissed.name,
      'dismissalReason': reason,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Snooze an item
  Future<void> snoozeItem(
      String householdId, String itemId, DateTime until) async {
    await _extractedItemsRef(householdId).doc(itemId).update({
      'reviewStatus': ReviewStatus.snoozed.name,
      'snoozeUntil': Timestamp.fromDate(until),
    });
  }

  /// Assign owner to an item
  Future<void> assignOwner(
    String householdId,
    String itemId, {
    required String ownerId,
    required String ownerName,
  }) async {
    await _extractedItemsRef(householdId).doc(itemId).update({
      'assignedOwnerId': ownerId,
      'assignedOwnerName': ownerName,
      'reviewStatus': ReviewStatus.assigned.name,
    });
  }

  /// Mark item as already handled
  Future<void> markHandled(String householdId, String itemId) async {
    await _extractedItemsRef(householdId).doc(itemId).update({
      'reviewStatus': ReviewStatus.alreadyHandled.name,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update extracted item fields (edit flow)
  Future<void> updateItemFields(
    String householdId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    updates['reviewStatus'] = ReviewStatus.editedAndApproved.name;
    updates['reviewedAt'] = Timestamp.fromDate(DateTime.now());
    await _extractedItemsRef(householdId).doc(itemId).update(updates);
  }

  /// Get all items for a source message
  Future<List<ExtractedItemModel>> getItemsForSourceMessage(
      String householdId, String sourceMessageId) async {
    final snapshot = await _extractedItemsRef(householdId)
        .where('sourceMessageId', isEqualTo: sourceMessageId)
        .get();
    return snapshot.docs
        .map((doc) => ExtractedItemModel.fromFirestore(doc))
        .toList();
  }

  /// Get snoozed items that are due
  Stream<List<ExtractedItemModel>> watchSnoozedItemsDue(String householdId) {
    return _extractedItemsRef(householdId)
        .where('reviewStatus', isEqualTo: ReviewStatus.snoozed.name)
        .where('snoozeUntil',
            isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExtractedItemModel.fromFirestore(doc))
            .toList());
  }
}
