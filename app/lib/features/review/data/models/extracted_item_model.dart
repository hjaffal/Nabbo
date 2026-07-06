import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../household/data/models/household_model.dart';

part 'extracted_item_model.freezed.dart';
part 'extracted_item_model.g.dart';

enum ExtractedItemType {
  event,
  task,
  deadline,
  requiredItem,
  checklist,
  form,
  payment,
  locationUpdate,
  change,
  risk,
  routineSuggestion,
}

enum ReviewStatus {
  pendingReview,
  approved,
  editedAndApproved,
  dismissed,
  snoozed,
  assigned,
  alreadyHandled,
  needsClarification,
}

enum ConfidenceLevel {
  high,
  medium,
  low,
  unknown,
}

@freezed
abstract class ExtractedField with _$ExtractedField {
  const factory ExtractedField({
    required String name,
    String? value,
    @Default(ConfidenceLevel.unknown) ConfidenceLevel confidence,
    @Default(false) bool isSuggested,
    @Default(false) bool isInferred,
  }) = _ExtractedField;

  factory ExtractedField.fromJson(Map<String, dynamic> json) =>
      _$ExtractedFieldFromJson(json);
}

@freezed
abstract class ExtractedItemModel with _$ExtractedItemModel {
  const factory ExtractedItemModel({
    required String id,
    required String householdId,
    required String sourceMessageId,
    String? affectedMemberId,
    String? affectedMemberName,
    required ExtractedItemType itemType,
    required String operationalSummary,
    @Default([]) List<ExtractedField> extractedFields,
    @Default([]) List<String> uncertainFields,
    @Default([]) List<String> suggestedActions,
    String? suggestedNextStep,
    @Default(ReviewStatus.pendingReview) ReviewStatus reviewStatus,
    String? dismissalReason,
    @TimestampConverter() DateTime? snoozeUntil,
    String? assignedOwnerId,
    String? assignedOwnerName,

    // Change detection
    String? relatedObjectId,
    String? relatedObjectType,
    String? previousValue,
    String? newValue,
    String? changeType,

    // Risk
    String? riskType,
    String? riskSeverity,

    // Timestamps
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? reviewedAt,
  }) = _ExtractedItemModel;

  factory ExtractedItemModel.fromJson(Map<String, dynamic> json) =>
      _$ExtractedItemModelFromJson(json);

  factory ExtractedItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExtractedItemModel.fromJson({'id': doc.id, ...data});
  }
}
