import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'routine_model.freezed.dart';
part 'routine_model.g.dart';

enum RoutineType {
  schoolDay,
  sportsActivity,
  musicLesson,
  swimming,
  weekendActivity,
  morningLaunch,
  eveningReset,
  pickupRoutine,
  travelRoutine,
}

@freezed
abstract class RoutineModel with _$RoutineModel {
  const factory RoutineModel({
    required String id,
    required String householdId,
    required String name,
    String? affectedMemberId,
    String? affectedMemberName,
    RoutineType? type,
    String? frequency,
    String? commonLocation,
    @Default([]) List<String> commonItems,
    String? defaultOwnerId,
    String? defaultOwnerName,
    String? defaultChecklistId,
    @Default([]) List<String> linkedEventIds,
    String? confidence,
    @TimestampConverter() DateTime? lastUsedDate,
    @TimestampConverter() DateTime? createdAt,
  }) = _RoutineModel;

  factory RoutineModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineModelFromJson(json);

  factory RoutineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoutineModel.fromJson({'id': doc.id, ...data});
  }
}
