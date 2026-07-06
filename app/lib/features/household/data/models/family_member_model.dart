import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'family_member_model.freezed.dart';
part 'family_member_model.g.dart';

enum MemberRole {
  primaryParent,
  secondaryParent,
  child,
  caregiver,
  grandparent,
  babysitter,
  other,
}

enum AgeGroup {
  toddler,
  child,
  teenager,
  adult,
}

@freezed
abstract class FamilyMemberModel with _$FamilyMemberModel {
  const factory FamilyMemberModel({
    required String id,
    required String householdId,
    required String name,
    required MemberRole role,
    AgeGroup? ageGroup,
    String? color,
    @Default([]) List<String> defaultResponsibilities,
    @TimestampConverter() DateTime? createdAt,
  }) = _FamilyMemberModel;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberModelFromJson(json);

  factory FamilyMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMemberModel.fromJson({'id': doc.id, ...data});
  }
}
