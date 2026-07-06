import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/change_model.dart';

final changeRepositoryProvider = Provider<ChangeRepository>((ref) {
  return ChangeRepository(FirebaseFirestore.instance);
});

class ChangeRepository {
  final FirebaseFirestore _firestore;
  ChangeRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('changes');

  Future<ChangeModel> create(String householdId, ChangeModel change) async {
    final docRef = _ref(householdId).doc();
    final data = change.copyWith(id: docRef.id, detectedAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<ChangeModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return ChangeModel.fromFirestore(doc);
  }

  Stream<List<ChangeModel>> watchAll(String householdId) {
    return _ref(householdId)
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map(
            (s) => s.docs.map((d) => ChangeModel.fromFirestore(d)).toList());
  }

  Future<List<ChangeModel>> getPendingReview(String householdId) async {
    final snap = await _ref(householdId)
        .where('reviewStatus',
            isEqualTo: ChangeReviewStatus.pendingReview.name)
        .get();
    return snap.docs.map((d) => ChangeModel.fromFirestore(d)).toList();
  }

  Future<List<ChangeModel>> getByObject(
      String householdId, String relatedObjectId) async {
    final snap = await _ref(householdId)
        .where('relatedObjectId', isEqualTo: relatedObjectId)
        .get();
    return snap.docs.map((d) => ChangeModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, ChangeModel change) async {
    await _ref(householdId)
        .doc(change.id)
        .update(change.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
