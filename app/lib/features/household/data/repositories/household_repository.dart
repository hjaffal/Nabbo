import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/household_model.dart';
import '../models/family_member_model.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(FirebaseFirestore.instance);
});

class HouseholdRepository {
  final FirebaseFirestore _firestore;

  HouseholdRepository(this._firestore);

  CollectionReference get _householdsRef => _firestore.collection('households');

  CollectionReference _membersRef(String householdId) =>
      _householdsRef.doc(householdId).collection('members');

  // Household CRUD
  Future<HouseholdModel> createHousehold(HouseholdModel household) async {
    final docRef = _householdsRef.doc();
    final data = household.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(_toFirestoreData(data));
    return data;
  }

  Future<HouseholdModel?> getHousehold(String id) async {
    final doc = await _householdsRef.doc(id).get();
    if (!doc.exists) return null;
    return HouseholdModel.fromFirestore(doc);
  }

  Future<HouseholdModel?> getHouseholdByUserId(String userId) async {
    final query = await _householdsRef
        .where('primaryUserId', isEqualTo: userId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return HouseholdModel.fromFirestore(query.docs.first);
  }

  Future<void> updateHousehold(HouseholdModel household) async {
    final data = household.copyWith(updatedAt: DateTime.now());
    await _householdsRef.doc(household.id).update(_toFirestoreData(data));
  }

  // Family Member CRUD
  Future<FamilyMemberModel> addFamilyMember(FamilyMemberModel member) async {
    final docRef = _membersRef(member.householdId).doc();
    final data = member.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
    );
    await docRef.set(_memberToFirestoreData(data));
    return data;
  }

  Stream<List<FamilyMemberModel>> watchFamilyMembers(String householdId) {
    return _membersRef(householdId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FamilyMemberModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<FamilyMemberModel>> getFamilyMembers(String householdId) async {
    final snapshot = await _membersRef(householdId).get();
    return snapshot.docs
        .map((doc) => FamilyMemberModel.fromFirestore(doc))
        .toList();
  }

  Future<void> updateFamilyMember(FamilyMemberModel member) async {
    await _membersRef(member.householdId)
        .doc(member.id)
        .update(_memberToFirestoreData(member));
  }

  Future<void> deleteFamilyMember(String householdId, String memberId) async {
    await _membersRef(householdId).doc(memberId).delete();
  }

  // Helpers
  Map<String, dynamic> _toFirestoreData(HouseholdModel household) {
    final json = household.toJson();
    json.remove('id');
    return json;
  }

  Map<String, dynamic> _memberToFirestoreData(FamilyMemberModel member) {
    final json = member.toJson();
    json.remove('id');
    return json;
  }
}
