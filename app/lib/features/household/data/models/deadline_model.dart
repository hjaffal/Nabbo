import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'deadline_model.freezed.dart';
part 'deadline_model.g.dart';

enum UrgencyLevel {
  low,
  medium,
  high,
  critical,
}

enum DeadlineStatus {
  upcoming,
  dueToday,
  overdue,
  completed,
  dismissed,
}

@freezed
abstract class DeadlineModel with _$DeadlineModel {
  const factory DeadlineModel({
    required String id,
    required String householdId,
    required String title,
    @TimestampConverter() DateTime? dueDateTime,
    String? affectedMemberId,
    String? affectedMemberName,
    String? ownerId,
    String? ownerName,
    String? relatedTaskId,
    String? relatedFormId,
    String? relatedPaymentId,
    String? relatedEventId,
    String? relatedSourceId,
    UrgencyLevel? urgencyLevel,
    DeadlineStatus? status,
    @TimestampConverter() DateTime? createdAt,
  }) = _DeadlineModel;

  factory DeadlineModel.fromJson(Map<String, dynamic> json) =>
      _$DeadlineModelFromJson(json);

  factory DeadlineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeadlineModel.fromJson({'id': doc.id, ...data});
  }
}
