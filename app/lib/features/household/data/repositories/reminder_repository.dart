import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder_model.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(FirebaseFirestore.instance);
});

class ReminderRepository {
  final FirebaseFirestore _firestore;
  ReminderRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('reminders');

  Future<ReminderModel> create(
      String householdId, ReminderModel reminder) async {
    final docRef = _ref(householdId).doc();
    final data = reminder.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<ReminderModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return ReminderModel.fromFirestore(doc);
  }

  Stream<List<ReminderModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => ReminderModel.fromFirestore(d)).toList());
  }

  Future<List<ReminderModel>> getScheduled(String householdId) async {
    final now = DateTime.now();
    final snap = await _ref(householdId)
        .where('status', isEqualTo: ReminderStatus.scheduled.name)
        .where('reminderTime',
            isGreaterThan: Timestamp.fromDate(now))
        .orderBy('reminderTime')
        .get();
    return snap.docs.map((d) => ReminderModel.fromFirestore(d)).toList();
  }

  Future<List<ReminderModel>> getByObject(
      String householdId, String relatedObjectId) async {
    final snap = await _ref(householdId)
        .where('relatedObjectId', isEqualTo: relatedObjectId)
        .get();
    return snap.docs.map((d) => ReminderModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, ReminderModel reminder) async {
    await _ref(householdId)
        .doc(reminder.id)
        .update(reminder.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
