import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'form_model.freezed.dart';
part 'form_model.g.dart';

enum FormAction {
  read,
  sign,
  print,
  complete,
  upload,
  submitOnline,
  returnPhysically,
  bringOnDay,
}

enum FormStatus {
  notStarted,
  inProgress,
  completed,
  submitted,
  overdue,
  dismissed,
}

@freezed
abstract class FormModel with _$FormModel {
  const factory FormModel({
    required String id,
    required String householdId,
    required String title,
    String? affectedMemberId,
    String? affectedMemberName,
    String? sourceMessageId,
    String? relatedEventId,
    String? relatedDeadlineId,
    String? ownerId,
    String? ownerName,
    FormAction? requiredAction,
    String? submissionMethod,
    @TimestampConverter() DateTime? dueDate,
    FormStatus? status,
    String? attachmentUrl,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _FormModel;

  factory FormModel.fromJson(Map<String, dynamic> json) =>
      _$FormModelFromJson(json);

  factory FormModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FormModel.fromJson({'id': doc.id, ...data});
  }
}
