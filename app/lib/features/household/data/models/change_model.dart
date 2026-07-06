import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'change_model.freezed.dart';
part 'change_model.g.dart';

enum ChangeType {
  time,
  date,
  location,
  requiredItemAdded,
  requiredItemRemoved,
  deadline,
  eventCancelled,
  owner,
  payment,
  formRequirementAdded,
}

enum ImpactLevel {
  low,
  medium,
  high,
}

enum ChangeReviewStatus {
  pendingReview,
  confirmed,
  rejected,
  dismissed,
}

@freezed
abstract class ChangeModel with _$ChangeModel {
  const factory ChangeModel({
    required String id,
    required String householdId,
    String? relatedObjectType,
    String? relatedObjectId,
    String? sourceMessageId,
    String? previousValue,
    String? newValue,
    ChangeType? changeType,
    @TimestampConverter() DateTime? detectedAt,
    String? confidenceLevel,
    ImpactLevel? impactLevel,
    ChangeReviewStatus? reviewStatus,
  }) = _ChangeModel;

  factory ChangeModel.fromJson(Map<String, dynamic> json) =>
      _$ChangeModelFromJson(json);

  factory ChangeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChangeModel.fromJson({'id': doc.id, ...data});
  }
}
