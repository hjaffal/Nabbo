import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/risk_model.dart';

final riskRepositoryProvider = Provider<RiskRepository>((ref) {
  return RiskRepository(FirebaseFirestore.instance);
});

class RiskRepository {
  final FirebaseFirestore _firestore;
  RiskRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('risks');

  Future<RiskModel> create(String householdId, RiskModel risk) async {
    final docRef = _ref(householdId).doc();
    final data = risk.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<RiskModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return RiskModel.fromFirestore(doc);
  }

  Stream<List<RiskModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => RiskModel.fromFirestore(d)).toList());
  }

  Future<List<RiskModel>> getOpen(String householdId) async {
    final snap = await _ref(householdId)
        .where('status', isEqualTo: RiskStatus.open.name)
        .get();
    return snap.docs.map((d) => RiskModel.fromFirestore(d)).toList();
  }

  Future<List<RiskModel>> getByMember(
      String householdId, String memberId) async {
    final snap = await _ref(householdId)
        .where('affectedMemberId', isEqualTo: memberId)
        .get();
    return snap.docs.map((d) => RiskModel.fromFirestore(d)).toList();
  }

  Future<List<RiskModel>> getBySeverity(
      String householdId, RiskSeverity severity) async {
    final snap = await _ref(householdId)
        .where('severity', isEqualTo: severity.name)
        .get();
    return snap.docs.map((d) => RiskModel.fromFirestore(d)).toList();
  }

  Future<List<RiskModel>> getForToday(String householdId) async {
    final snap = await _ref(householdId)
        .where('status', isEqualTo: RiskStatus.open.name)
        .where('severity', whereIn: [
          RiskSeverity.high.name,
          RiskSeverity.critical.name,
        ])
        .get();
    return snap.docs.map((d) => RiskModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, RiskModel risk) async {
    await _ref(householdId).doc(risk.id).update(risk.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
