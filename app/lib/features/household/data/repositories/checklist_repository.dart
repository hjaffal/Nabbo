import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist_model.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(FirebaseFirestore.instance);
});

class ChecklistRepository {
  final FirebaseFirestore _firestore;
  ChecklistRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('checklists');

  Future<ChecklistModel> create(
      String householdId, ChecklistModel checklist) async {
    final docRef = _ref(householdId).doc();
    final data = checklist.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<ChecklistModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return ChecklistModel.fromFirestore(doc);
  }

  Stream<List<ChecklistModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => ChecklistModel.fromFirestore(d)).toList());
  }

  Future<List<ChecklistModel>> getByEvent(
      String householdId, String eventId) async {
    final snap = await _ref(householdId)
        .where('relatedEventId', isEqualTo: eventId)
        .get();
    return snap.docs.map((d) => ChecklistModel.fromFirestore(d)).toList();
  }

  Future<List<ChecklistModel>> getByMember(
      String householdId, String memberId) async {
    final snap = await _ref(householdId)
        .where('affectedMemberId', isEqualTo: memberId)
        .get();
    return snap.docs.map((d) => ChecklistModel.fromFirestore(d)).toList();
  }

  Future<List<ChecklistModel>> getIncomplete(String householdId) async {
    final snap = await _ref(householdId)
        .where('completionStatus', isNotEqualTo: 'completed')
        .get();
    return snap.docs.map((d) => ChecklistModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, ChecklistModel checklist) async {
    await _ref(householdId)
        .doc(checklist.id)
        .update(checklist.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
