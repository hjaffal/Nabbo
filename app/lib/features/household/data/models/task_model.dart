import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

enum Priority {
  low,
  medium,
  high,
  urgent,
}

enum TaskStatus {
  open,
  assigned,
  inProgress,
  completed,
  dismissed,
  overdue,
  blocked,
}

@freezed
abstract class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String householdId,
    required String title,
    String? description,
    String? affectedMemberId,
    String? affectedMemberName,
    String? ownerId,
    String? ownerName,
    @TimestampConverter() DateTime? dueDate,
    Priority? priority,
    String? relatedEventId,
    String? relatedSourceId,
    String? relatedFormId,
    String? relatedPaymentId,
    TaskStatus? status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel.fromJson({'id': doc.id, ...data});
  }
}
