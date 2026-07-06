import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'household_plan_model.freezed.dart';
part 'household_plan_model.g.dart';

enum PlanType {
  today,
  tomorrow,
  thisWeek,
  morningLaunch,
  eveningReset,
  weekendPlan,
}

@freezed
abstract class HouseholdPlanModel with _$HouseholdPlanModel {
  const factory HouseholdPlanModel({
    required String id,
    required String householdId,
    @TimestampConverter() DateTime? planDate,
    PlanType? type,
    @Default([]) List<String> eventIds,
    @Default([]) List<String> taskIds,
    @Default([]) List<String> deadlineIds,
    @Default([]) List<String> checklistIds,
    @Default([]) List<String> riskIds,
    @Default([]) List<String> unassignedItemIds,
    @Default([]) List<String> changeIds,
    @Default([]) List<String> completedItemIds,
    @Default([]) List<String> openItemIds,
    String? generatedSummary,
    @TimestampConverter() DateTime? createdAt,
  }) = _HouseholdPlanModel;

  factory HouseholdPlanModel.fromJson(Map<String, dynamic> json) =>
      _$HouseholdPlanModelFromJson(json);

  factory HouseholdPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HouseholdPlanModel.fromJson({'id': doc.id, ...data});
  }
}
