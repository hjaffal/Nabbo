import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'required_item_model.freezed.dart';
part 'required_item_model.g.dart';

enum PackedStatus {
  notReady,
  ready,
  notNeeded,
  alreadyHandled,
  ownerMissing,
}

enum ItemCategory {
  clothing,
  sportsGear,
  schoolMaterial,
  food,
  drink,
  document,
  money,
  medicine,
  device,
  other,
}

@freezed
abstract class RequiredItemModel with _$RequiredItemModel {
  const factory RequiredItemModel({
    required String id,
    required String householdId,
    required String name,
    String? quantity,
    String? affectedMemberId,
    String? affectedMemberName,
    String? relatedEventId,
    String? relatedChecklistId,
    String? relatedSourceId,
    String? ownerId,
    String? ownerName,
    @TimestampConverter() DateTime? neededByDateTime,
    PackedStatus? packedStatus,
    ItemCategory? category,
    @Default(false) bool isRecurring,
    @Default(false) bool suggestedBySystem,
    @TimestampConverter() DateTime? createdAt,
  }) = _RequiredItemModel;

  factory RequiredItemModel.fromJson(Map<String, dynamic> json) =>
      _$RequiredItemModelFromJson(json);

  factory RequiredItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequiredItemModel.fromJson({'id': doc.id, ...data});
  }
}
