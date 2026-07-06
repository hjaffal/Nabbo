import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'risk_model.freezed.dart';
part 'risk_model.g.dart';

enum RiskType {
  noOwner,
  deadlineNear,
  deadlineOverdue,
  conflictingEvents,
  locationChanged,
  itemNotPacked,
  paymentUnpaid,
  formIncomplete,
  travelTimeRisk,
  missingInfo,
  contradictoryInfo,
}

enum RiskSeverity {
  low,
  medium,
  high,
  critical,
}

enum RiskStatus {
  open,
  acknowledged,
  resolved,
  dismissed,
}

@freezed
abstract class RiskModel with _$RiskModel {
  const factory RiskModel({
    required String id,
    required String householdId,
    required String title,
    String? description,
    String? affectedMemberId,
    String? affectedMemberName,
    @Default([]) List<String> relatedObjectIds,
    RiskType? type,
    RiskSeverity? severity,
    String? suggestedAction,
    String? ownerId,
    RiskStatus? status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? resolvedAt,
  }) = _RiskModel;

  factory RiskModel.fromJson(Map<String, dynamic> json) =>
      _$RiskModelFromJson(json);

  factory RiskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RiskModel.fromJson({'id': doc.id, ...data});
  }
}
