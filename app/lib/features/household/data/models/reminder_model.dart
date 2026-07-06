import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'reminder_model.freezed.dart';
part 'reminder_model.g.dart';

enum ReminderType {
  task,
  deadline,
  departure,
  checklist,
  payment,
  form,
  change,
  ownerReminder,
}

enum ReminderStatus {
  scheduled,
  sent,
  dismissed,
  completed,
  failed,
}

@freezed
abstract class ReminderModel with _$ReminderModel {
  const factory ReminderModel({
    required String id,
    required String householdId,
    String? relatedObjectType,
    String? relatedObjectId,
    String? recipientId,
    String? recipientName,
    @TimestampConverter() DateTime? reminderTime,
    ReminderType? type,
    String? message,
    ReminderStatus? status,
    String? channel,
    @TimestampConverter() DateTime? createdAt,
  }) = _ReminderModel;

  factory ReminderModel.fromJson(Map<String, dynamic> json) =>
      _$ReminderModelFromJson(json);

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel.fromJson({'id': doc.id, ...data});
  }
}
