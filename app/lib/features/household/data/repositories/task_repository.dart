import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(FirebaseFirestore.instance);
});

class TaskRepository {
  final FirebaseFirestore _firestore;
  TaskRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('tasks');

  Future<TaskModel> create(String householdId, TaskModel task) async {
    final docRef = _ref(householdId).doc();
    final data = task.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<TaskModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  Stream<List<TaskModel>> watchAll(String householdId) {
    return _ref(householdId).orderBy('dueDate').snapshots().map(
        (s) => s.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  Future<List<TaskModel>> getByOwner(
      String householdId, String ownerId) async {
    final snap = await _ref(householdId)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }

  Future<List<TaskModel>> getByStatus(
      String householdId, TaskStatus status) async {
    final snap = await _ref(householdId)
        .where('status', isEqualTo: status.name)
        .get();
    return snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }

  Future<List<TaskModel>> getOverdue(String householdId) async {
    final now = DateTime.now();
    final snap = await _ref(householdId)
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .where('status', isNotEqualTo: TaskStatus.completed.name)
        .get();
    return snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }

  Future<List<TaskModel>> getByDueDate(
      String householdId, DateTime start, DateTime end) async {
    final snap = await _ref(householdId)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('dueDate')
        .get();
    return snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, TaskModel task) async {
    await _ref(householdId).doc(task.id).update(task.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
