import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(FirebaseFirestore.instance);
});

class EventRepository {
  final FirebaseFirestore _firestore;
  EventRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('events');

  Future<EventModel> create(String householdId, EventModel event) async {
    final docRef = _ref(householdId).doc();
    final data = event.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<EventModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  Stream<List<EventModel>> watchAll(String householdId) {
    return _ref(householdId).orderBy('startDateTime').snapshots().map(
        (s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  Stream<List<EventModel>> watchToday(String householdId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _ref(householdId)
        .where('startDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startDateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  Future<List<EventModel>> getByMember(
      String householdId, String memberId) async {
    final snap = await _ref(householdId)
        .where('affectedMemberId', isEqualTo: memberId)
        .get();
    return snap.docs.map((d) => EventModel.fromFirestore(d)).toList();
  }

  Future<List<EventModel>> getUpcoming(String householdId,
      {int days = 14}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final snap = await _ref(householdId)
        .where('startDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('startDateTime',
            isLessThanOrEqualTo: Timestamp.fromDate(future))
        .orderBy('startDateTime')
        .get();
    return snap.docs.map((d) => EventModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, EventModel event) async {
    await _ref(householdId).doc(event.id).update(event.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
