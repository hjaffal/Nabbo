import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'checklist_model.freezed.dart';
part 'checklist_model.g.dart';

enum ChecklistType {
  morningLaunch,
  eveningReset,
  schoolTrip,
  sportsActivity,
  medical,
  travel,
  weekend,
  eventPrep,
}

@freezed
abstract class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String name,
    @Default(false) bool isCompleted,
    String? ownerId,
    String? ownerName,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

@freezed
abstract class ChecklistModel with _$ChecklistModel {
  const factory ChecklistModel({
    required String id,
    required String householdId,
    required String title,
    ChecklistType? type,
    String? affectedMemberId,
    String? affectedMemberName,
    String? relatedEventId,
    String? relatedRoutineId,
    @Default([]) List<ChecklistItem> items,
    String? ownerId,
    String? ownerName,
    @TimestampConverter() DateTime? date,
    String? completionStatus,
    @Default(false) bool createdManually,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _ChecklistModel;

  factory ChecklistModel.fromJson(Map<String, dynamic> json) =>
      _$ChecklistModelFromJson(json);

  factory ChecklistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChecklistModel.fromJson({'id': doc.id, ...data});
  }
}
