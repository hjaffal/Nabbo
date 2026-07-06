import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine_model.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(FirebaseFirestore.instance);
});

class RoutineRepository {
  final FirebaseFirestore _firestore;
  RoutineRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('routines');

  Future<RoutineModel> create(
      String householdId, RoutineModel routine) async {
    final docRef = _ref(householdId).doc();
    final data = routine.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<RoutineModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return RoutineModel.fromFirestore(doc);
  }

  Stream<List<RoutineModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => RoutineModel.fromFirestore(d)).toList());
  }

  Future<List<RoutineModel>> getByMember(
      String householdId, String memberId) async {
    final snap = await _ref(householdId)
        .where('affectedMemberId', isEqualTo: memberId)
        .get();
    return snap.docs.map((d) => RoutineModel.fromFirestore(d)).toList();
  }

  Future<List<RoutineModel>> getActive(String householdId) async {
    final snap = await _ref(householdId)
        .where('frequency', isNotEqualTo: null)
        .get();
    return snap.docs.map((d) => RoutineModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, RoutineModel routine) async {
    await _ref(householdId)
        .doc(routine.id)
        .update(routine.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
