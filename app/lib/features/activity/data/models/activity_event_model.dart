import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../household/data/models/household_model.dart';

part 'activity_event_model.freezed.dart';
part 'activity_event_model.g.dart';

enum ActivityType {
  capture,
  approval,
  autoApproval,
  edit,
  completion,
  cancellation,
}

@freezed
abstract class ActivityEventModel with _$ActivityEventModel {
  const factory ActivityEventModel({
    required String id,
    required String householdId,
    required ActivityType activityType,
    required String actorId,
    required String actorName,
    required String title,
    String? subtitle,
    String? childId,
    String? childName,
    String? relatedItemId,
    String? sourceMessageId,
    @Default({}) Map<String, dynamic> metadata,
    @TimestampConverter() DateTime? createdAt,
  }) = _ActivityEventModel;

  factory ActivityEventModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityEventModelFromJson(json);

  factory ActivityEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityEventModel.fromJson({'id': doc.id, ...data});
  }
}
