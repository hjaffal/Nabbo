import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'owner_model.freezed.dart';
part 'owner_model.g.dart';

enum OwnerStatus {
  assigned,
  accepted,
  declined,
  completed,
  unassigned,
  needsReassignment,
}

@freezed
abstract class OwnerModel with _$OwnerModel {
  const factory OwnerModel({
    required String id,
    required String householdId,
    String? personId,
    String? personName,
    String? assignedObjectType,
    String? assignedObjectId,
    String? assignedBy,
    @TimestampConverter() DateTime? assignedAt,
    OwnerStatus? status,
    @Default(false) bool completionConfirmation,
    String? escalationStatus,
  }) = _OwnerModel;

  factory OwnerModel.fromJson(Map<String, dynamic> json) =>
      _$OwnerModelFromJson(json);

  factory OwnerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OwnerModel.fromJson({'id': doc.id, ...data});
  }
}
