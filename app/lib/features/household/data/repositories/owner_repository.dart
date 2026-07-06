import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/owner_model.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository(FirebaseFirestore.instance);
});

class OwnerRepository {
  final FirebaseFirestore _firestore;
  OwnerRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('owners');

  Future<OwnerModel> create(String householdId, OwnerModel owner) async {
    final docRef = _ref(householdId).doc();
    final data = owner.copyWith(id: docRef.id, assignedAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<OwnerModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return OwnerModel.fromFirestore(doc);
  }

  Stream<List<OwnerModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => OwnerModel.fromFirestore(d)).toList());
  }

  Future<List<OwnerModel>> getByObject(
      String householdId, String assignedObjectId) async {
    final snap = await _ref(householdId)
        .where('assignedObjectId', isEqualTo: assignedObjectId)
        .get();
    return snap.docs.map((d) => OwnerModel.fromFirestore(d)).toList();
  }

  Future<List<OwnerModel>> getUnassigned(String householdId) async {
    final snap = await _ref(householdId)
        .where('status', isEqualTo: OwnerStatus.unassigned.name)
        .get();
    return snap.docs.map((d) => OwnerModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, OwnerModel owner) async {
    await _ref(householdId)
        .doc(owner.id)
        .update(owner.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
