import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deadline_model.dart';

final deadlineRepositoryProvider = Provider<DeadlineRepository>((ref) {
  return DeadlineRepository(FirebaseFirestore.instance);
});

class DeadlineRepository {
  final FirebaseFirestore _firestore;
  DeadlineRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('deadlines');

  Future<DeadlineModel> create(
      String householdId, DeadlineModel deadline) async {
    final docRef = _ref(householdId).doc();
    final data = deadline.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<DeadlineModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return DeadlineModel.fromFirestore(doc);
  }

  Stream<List<DeadlineModel>> watchAll(String householdId) {
    return _ref(householdId).orderBy('dueDateTime').snapshots().map(
        (s) => s.docs.map((d) => DeadlineModel.fromFirestore(d)).toList());
  }

  Future<List<DeadlineModel>> getDueSoon(String householdId) async {
    final now = DateTime.now();
    final soon = now.add(const Duration(hours: 48));
    final snap = await _ref(householdId)
        .where('dueDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('dueDateTime', isLessThanOrEqualTo: Timestamp.fromDate(soon))
        .orderBy('dueDateTime')
        .get();
    return snap.docs.map((d) => DeadlineModel.fromFirestore(d)).toList();
  }

  Future<List<DeadlineModel>> getOverdue(String householdId) async {
    final now = DateTime.now();
    final snap = await _ref(householdId)
        .where('dueDateTime', isLessThan: Timestamp.fromDate(now))
        .where('status', isNotEqualTo: DeadlineStatus.completed.name)
        .get();
    return snap.docs.map((d) => DeadlineModel.fromFirestore(d)).toList();
  }

  Future<List<DeadlineModel>> getByOwner(
      String householdId, String ownerId) async {
    final snap = await _ref(householdId)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs.map((d) => DeadlineModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, DeadlineModel deadline) async {
    await _ref(householdId)
        .doc(deadline.id)
        .update(deadline.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
