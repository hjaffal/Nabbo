import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseFirestore.instance);
});

class PaymentRepository {
  final FirebaseFirestore _firestore;
  PaymentRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('payments');

  Future<PaymentModel> create(
      String householdId, PaymentModel payment) async {
    final docRef = _ref(householdId).doc();
    final data = payment.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<PaymentModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return PaymentModel.fromFirestore(doc);
  }

  Stream<List<PaymentModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
  }

  Future<List<PaymentModel>> getDueSoon(String householdId) async {
    final now = DateTime.now();
    final soon = now.add(const Duration(hours: 48));
    final snap = await _ref(householdId)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(soon))
        .orderBy('dueDate')
        .get();
    return snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
  }

  Future<List<PaymentModel>> getByStatus(
      String householdId, PaymentStatus status) async {
    final snap = await _ref(householdId)
        .where('status', isEqualTo: status.name)
        .get();
    return snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
  }

  Future<List<PaymentModel>> getByOwner(
      String householdId, String ownerId) async {
    final snap = await _ref(householdId)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, PaymentModel payment) async {
    await _ref(householdId)
        .doc(payment.id)
        .update(payment.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
