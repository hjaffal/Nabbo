import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(FirebaseFirestore.instance);
});

class LocationRepository {
  final FirebaseFirestore _firestore;
  LocationRepository(this._firestore);

  CollectionReference _ref(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('locations');

  Future<LocationModel> create(
      String householdId, LocationModel location) async {
    final docRef = _ref(householdId).doc();
    final data = location.copyWith(id: docRef.id, createdAt: DateTime.now());
    await docRef.set(data.toJson()..remove('id'));
    return data;
  }

  Future<LocationModel?> get(String householdId, String id) async {
    final doc = await _ref(householdId).doc(id).get();
    if (!doc.exists) return null;
    return LocationModel.fromFirestore(doc);
  }

  Stream<List<LocationModel>> watchAll(String householdId) {
    return _ref(householdId).snapshots().map(
        (s) => s.docs.map((d) => LocationModel.fromFirestore(d)).toList());
  }

  Future<List<LocationModel>> getByType(
      String householdId, LocationType type) async {
    final snap = await _ref(householdId)
        .where('type', isEqualTo: type.name)
        .get();
    return snap.docs.map((d) => LocationModel.fromFirestore(d)).toList();
  }

  Future<List<LocationModel>> search(
      String householdId, String query) async {
    final snap = await _ref(householdId)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();
    return snap.docs.map((d) => LocationModel.fromFirestore(d)).toList();
  }

  Future<void> update(String householdId, LocationModel location) async {
    await _ref(householdId)
        .doc(location.id)
        .update(location.toJson()..remove('id'));
  }

  Future<void> delete(String householdId, String id) async {
    await _ref(householdId).doc(id).delete();
  }
}
