import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../household/data/models/family_member_model.dart';
import '../models/activity_event_model.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(FirebaseFirestore.instance);
});

class ActivityRepository {
  final FirebaseFirestore _firestore;

  ActivityRepository(this._firestore);

  CollectionReference _eventsRef(String householdId) => _firestore
      .collection('households')
      .doc(householdId)
      .collection('activityEvents');

  /// Records an activity event with deduplication.
  /// Fire-and-forget: errors are swallowed and printed to debug console only.
  Future<void> recordEvent(
      String householdId, ActivityEventModel event) async {
    try {
      // Deduplication: skip if same activityType + relatedItemId exists within last 5 seconds
      if (event.relatedItemId != null) {
        final fiveSecondsAgo =
            DateTime.now().subtract(const Duration(seconds: 5));
        final duplicates = await _eventsRef(householdId)
            .where('activityType', isEqualTo: event.activityType.name)
            .where('relatedItemId', isEqualTo: event.relatedItemId)
            .where('createdAt',
                isGreaterThan: Timestamp.fromDate(fiveSecondsAgo))
            .get();

        if (duplicates.docs.isNotEmpty) {
          return; // Skip duplicate
        }
      }

      final data = event.toJson();
      data.remove('id');
      // Ensure createdAt is stored as a Firestore Timestamp
      data['createdAt'] = Timestamp.fromDate(event.createdAt ?? DateTime.now());

      await _eventsRef(householdId).add(data);
    } catch (e) {
      debugPrint('ActivityRepository.recordEvent error: $e');
    }
  }

  /// Watches activity events for a household, ordered by most recent first.
  Stream<List<ActivityEventModel>> watchEvents(String householdId,
      {int limit = 50}) {
    return _eventsRef(householdId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityEventModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Loads more activity events after the given timestamp (for pagination).
  Future<List<ActivityEventModel>> loadMore(
      String householdId, DateTime lastCreatedAt,
      {int limit = 50}) async {
    final snapshot = await _eventsRef(householdId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(lastCreatedAt)])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ActivityEventModel.fromFirestore(doc))
        .toList();
  }

  /// Resolves the actor name for the current user in the household.
  /// Finds the primary parent member, falls back to FirebaseAuth displayName.
  Future<String> resolveActorName(String householdId) async {
    final membersSnapshot = await _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .get();

    final members = membersSnapshot.docs
        .map((doc) => FamilyMemberModel.fromFirestore(doc))
        .toList();

    final primaryParent = members.cast<FamilyMemberModel?>().firstWhere(
          (m) => m!.role == MemberRole.primaryParent,
          orElse: () => null,
        );

    if (primaryParent != null) {
      return primaryParent.name;
    }

    return FirebaseAuth.instance.currentUser?.displayName ?? 'Parent';
  }
}
