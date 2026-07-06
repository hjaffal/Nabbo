import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/required_item_model.dart';

final requiredItemRepositoryProvider = Provider<RequiredItemRepository>((ref) {
  return RequiredItemRepository(FirebaseFirestore.instance);
});

class RequiredItemRepository {
  final FirebaseFirestore _firestore;
  RequiredItemRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('requiredItems');

  Future<RequiredItemModel> create(
      String householdId, RequiredItemModel item) async {
    final docRef = _ref(householdId).doc();
    final data = item.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<RequiredItemModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return RequiredItemModel.fromFirestore(doc);
  }

  Stream<List<RequiredItemModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => RequiredItemModel.fromFirestore(d)).toList());
  }

  Future<List<RequiredItemModel>> getByEvent(
      String householdId, String eventId) async {
    final snap = await _ref(householdId)
        .where('relatedEventId', isEqualTo: eventId)
        .get();
    return snap.docs.map((d) => RequiredItemModel.fromFirestore(d)).toList();
  }

  Future<List<RequiredItemModel>> getByChecklist(
      String householdId, String checklistId) async {
    final snap = await _ref(householdId)
        .where('relatedChecklistId', isEqualTo: checklistId)
        .get();
    return snap.docs.map((d) => RequiredItemModel.fromFirestore(d)).toList();
  }

  Future<List<RequiredItemModel>> getUnpacked(String householdId) async {
    final snap = await _ref(householdId)
        .where('packedStatus', isEqualTo: PackedStatus.notReady.name)
        .get();
    return snap.docs.map((d) => RequiredItemModel.fromFirestore(d)).toList();
  }

  Future<List<RequiredItemModel>> getNeededToday(String householdId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snap = await _ref(householdId)
        .where('neededByDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('neededByDateTime',
            isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    return snap.docs.map((d) => RequiredItemModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, RequiredItemModel item) async {
    await _ref(householdId).doc(item.id).update(item.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
