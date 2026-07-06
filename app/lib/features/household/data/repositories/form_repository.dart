import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/form_model.dart';

final formRepositoryProvider = Provider<FormRepository>((ref) {
  return FormRepository(FirebaseFirestore.instance);
});

class FormRepository {
  final FirebaseFirestore _firestore;
  FormRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('forms');

  Future<FormModel> create(String householdId, FormModel form) async {
    final docRef = _ref(householdId).doc();
    final data = form.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<FormModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return FormModel.fromFirestore(doc);
  }

  Stream<List<FormModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => FormModel.fromFirestore(d)).toList());
  }

  Future<List<FormModel>> getDueSoon(String householdId) async {
    final now = DateTime.now();
    final soon = now.add(const Duration(hours: 48));
    final snap = await _ref(householdId)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(soon))
        .orderBy('dueDate')
        .get();
    return snap.docs.map((d) => FormModel.fromFirestore(d)).toList();
  }

  Future<List<FormModel>> getByStatus(
      String householdId, FormStatus status) async {
    final snap = await _ref(householdId)
        .where('status', isEqualTo: status.name)
        .get();
    return snap.docs.map((d) => FormModel.fromFirestore(d)).toList();
  }

  Future<List<FormModel>> getByOwner(
      String householdId, String ownerId) async {
    final snap = await _ref(householdId)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs.map((d) => FormModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, FormModel form) async {
    await _ref(householdId).doc(form.id).update(form.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
