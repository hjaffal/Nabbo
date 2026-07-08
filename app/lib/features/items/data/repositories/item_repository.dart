import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activity/data/models/activity_event_model.dart';
import '../../../activity/data/repositories/activity_repository.dart';
import '../models/item_model.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(
    FirebaseFirestore.instance,
    ref.read(activityRepositoryProvider),
  );
});

class ItemRepository {
  final FirebaseFirestore _firestore;
  final ActivityRepository _activityRepo;

  ItemRepository(this._firestore, this._activityRepo);

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  CollectionReference _itemsRef(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('items');

  /// Watch all items for the Feed (pending + confirmed, ordered by date)
  Stream<List<ItemModel>> watchFeedItems(String householdId) {
    return _itemsRef(householdId)
        .where('status', whereIn: ['pendingReview', 'confirmed'])
        .snapshots()
        .map((snapshot) {
      final items = <ItemModel>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(ItemModel.fromFirestore(doc));
        } catch (e) {
          // Skip documents that fail to parse
        }
      }
      // Sort: pendingReview first, then by date ascending
      items.sort((a, b) {
        if (a.status == ItemStatus.pendingReview &&
            b.status != ItemStatus.pendingReview) return -1;
        if (a.status != ItemStatus.pendingReview &&
            b.status == ItemStatus.pendingReview) return 1;
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });
      return items;
    });
  }

  /// Watch pending review items only
  Stream<List<ItemModel>> watchPendingItems(String householdId) {
    return _itemsRef(householdId)
        .where('status', isEqualTo: 'pendingReview')
        .snapshots()
        .map((snapshot) {
      final items = <ItemModel>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(ItemModel.fromFirestore(doc));
        } catch (_) {}
      }
      items.sort((a, b) => (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000)));
      return items;
    });
  }

  /// Get items linked to a source message
  Stream<List<ItemModel>> watchItemsBySource(
      String householdId, String sourceMessageId) {
    return _itemsRef(householdId)
        .where('sourceMessageId', isEqualTo: sourceMessageId)
        .snapshots()
        .map((snapshot) {
      final items = <ItemModel>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(ItemModel.fromFirestore(doc));
        } catch (_) {}
      }
      return items;
    });
  }

  /// Get a single item
  Future<ItemModel?> getItem(String householdId, String itemId) async {
    final doc = await _itemsRef(householdId).doc(itemId).get();
    if (!doc.exists) return null;
    return ItemModel.fromFirestore(doc);
  }

  /// Approve an item (status change only — for action: create)
  Future<void> approve(String householdId, String itemId) async {
    await _itemsRef(householdId).doc(itemId).update({
      'status': 'confirmed',
      'updatedAt': Timestamp.now(),
    });
    // Record activity event
    final item = await getItem(householdId, itemId);
    if (item != null) {
      final actorName = await _activityRepo.resolveActorName(householdId);
      _activityRepo.recordEvent(householdId, ActivityEventModel(
        id: '',
        householdId: householdId,
        activityType: ActivityType.approval,
        actorId: _currentUid,
        actorName: actorName,
        title: item.title,
        childId: item.childId,
        childName: item.childName,
        relatedItemId: itemId,
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Approve a change proposal (action: update) — apply changes to target item, delete proposal
  Future<void> approveUpdate(String householdId, String proposalId, String targetItemId, Map<String, dynamic> changes) async {
    // Apply changes to target
    final updates = Map<String, dynamic>.from(changes);
    updates['updatedAt'] = Timestamp.now();
    await _itemsRef(householdId).doc(targetItemId).update(updates);
    // Delete the proposal
    await _itemsRef(householdId).doc(proposalId).delete();
  }

  /// Approve a cancel proposal (action: cancel) — cancel the target item, delete proposal
  Future<void> approveCancel(String householdId, String proposalId, String targetItemId, {String? cancelDate, bool isRecurring = false}) async {
    if (isRecurring && cancelDate != null) {
      // Cancel single occurrence via exception
      await _itemsRef(householdId).doc(targetItemId).update({
        'exceptions': FieldValue.arrayUnion([
          {'date': cancelDate, 'status': 'cancelled'}
        ]),
        'updatedAt': Timestamp.now(),
      });
    } else {
      // Cancel the entire item
      await _itemsRef(householdId).doc(targetItemId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    }
    // Delete the proposal
    await _itemsRef(householdId).doc(proposalId).delete();
  }

  /// Mark an item as completed
  Future<void> complete(String householdId, String itemId) async {
    final item = await getItem(householdId, itemId);
    await _itemsRef(householdId).doc(itemId).update({
      'status': 'completed',
      'updatedAt': Timestamp.now(),
    });
    if (item != null) {
      final actorName = await _activityRepo.resolveActorName(householdId);
      _activityRepo.recordEvent(householdId, ActivityEventModel(
        id: '',
        householdId: householdId,
        activityType: ActivityType.completion,
        actorId: _currentUid,
        actorName: actorName,
        title: item.title,
        childId: item.childId,
        childName: item.childName,
        relatedItemId: itemId,
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Cancel an item
  Future<void> cancel(String householdId, String itemId) async {
    final item = await getItem(householdId, itemId);
    await _itemsRef(householdId).doc(itemId).update({
      'status': 'cancelled',
      'updatedAt': Timestamp.now(),
    });
    if (item != null) {
      final actorName = await _activityRepo.resolveActorName(householdId);
      _activityRepo.recordEvent(householdId, ActivityEventModel(
        id: '',
        householdId: householdId,
        activityType: ActivityType.cancellation,
        actorId: _currentUid,
        actorName: actorName,
        title: item.title,
        childId: item.childId,
        childName: item.childName,
        relatedItemId: itemId,
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Update any fields on an item (edit flow)
  Future<void> updateItem(
      String householdId, String itemId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _itemsRef(householdId).doc(itemId).update(updates);
  }

  /// Delete an item permanently
  Future<void> deleteItem(String householdId, String itemId) async {
    final item = await getItem(householdId, itemId);
    await _itemsRef(householdId).doc(itemId).delete();
    if (item != null) {
      final actorName = await _activityRepo.resolveActorName(householdId);
      _activityRepo.recordEvent(householdId, ActivityEventModel(
        id: '',
        householdId: householdId,
        activityType: ActivityType.cancellation,
        actorId: _currentUid,
        actorName: actorName,
        title: item.title,
        childId: item.childId,
        childName: item.childName,
        relatedItemId: itemId,
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Cancel a single occurrence of a recurring item
  Future<void> cancelOccurrence(
      String householdId, String itemId, String date) async {
    await _itemsRef(householdId).doc(itemId).update({
      'exceptions': FieldValue.arrayUnion([
        {'date': date, 'status': 'cancelled'}
      ]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Override a single occurrence of a recurring item
  Future<void> overrideOccurrence(String householdId, String itemId,
      String date, Map<String, dynamic> overrides) async {
    await _itemsRef(householdId).doc(itemId).update({
      'exceptions': FieldValue.arrayUnion([
        {'date': date, 'overrides': overrides}
      ]),
      'updatedAt': Timestamp.now(),
    });
  }
}
