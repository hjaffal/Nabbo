import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'completion_model.freezed.dart';
part 'completion_model.g.dart';

@freezed
abstract class CompletionModel with _$CompletionModel {
  const factory CompletionModel({
    required String id,
    required String householdId,
    String? relatedObjectType,
    String? relatedObjectId,
    String? completedBy,
    String? completedByName,
    @TimestampConverter() DateTime? completedAt,
    String? method,
    String? notes,
    String? evidenceAttachment,
    String? confirmationStatus,
  }) = _CompletionModel;

  factory CompletionModel.fromJson(Map<String, dynamic> json) =>
      _$CompletionModelFromJson(json);

  factory CompletionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompletionModel.fromJson({'id': doc.id, ...data});
  }
}
