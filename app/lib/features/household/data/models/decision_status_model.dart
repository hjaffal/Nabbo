import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'decision_status_model.freezed.dart';
part 'decision_status_model.g.dart';

enum DecisionState {
  pendingReview,
  approved,
  editedAndApproved,
  dismissed,
  snoozed,
  assigned,
  alreadyHandled,
  needsClarification,
}

@freezed
abstract class DecisionStatusModel with _$DecisionStatusModel {
  const factory DecisionStatusModel({
    required String id,
    required String householdId,
    String? extractedItemId,
    DecisionState? status,
    String? decidedBy,
    @TimestampConverter() DateTime? decidedAt,
    @Default([]) List<String> editedFields,
    String? dismissalReason,
    @TimestampConverter() DateTime? snoozeUntil,
    String? notes,
  }) = _DecisionStatusModel;

  factory DecisionStatusModel.fromJson(Map<String, dynamic> json) =>
      _$DecisionStatusModelFromJson(json);

  factory DecisionStatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DecisionStatusModel.fromJson({'id': doc.id, ...data});
  }
}
