import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/completion_model.dart';

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  return CompletionRepository(FirebaseFirestore.instance);
});

class CompletionRepository {
  final FirebaseFirestore _firestore;
  CompletionRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('completions');

  Future<CompletionModel> create(
      String householdId, CompletionModel completion) async {
    final docRef = _ref(householdId).doc();
    final data =
        completion.copyWith(id: docRef.id, completedAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<CompletionModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return CompletionModel.fromFirestore(doc);
  }

  Future<List<CompletionModel>> getByObject(
      String householdId, String relatedObjectId) async {
    final snap = await _ref(householdId)
        .where('relatedObjectId', isEqualTo: relatedObjectId)
        .get();
    return snap.docs.map((d) => CompletionModel.fromFirestore(d)).toList();
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
