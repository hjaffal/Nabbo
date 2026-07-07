import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../household/data/models/household_model.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

enum ItemType {
  event,
  task,
  deadline,
}

enum ItemStatus {
  pendingReview,
  confirmed,
  completed,
  cancelled,
  hidden,
}

enum ItemAction {
  create,
  update,
  cancel,
}

@freezed
abstract class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule({
    required String frequency, // weekly, daily, biweekly, monthly
    String? dayOfWeek, // monday-sunday (for weekly)
    String? startDate, // YYYY-MM-DD
    String? endDate, // YYYY-MM-DD or null (ongoing)
  }) = _RecurrenceRule;

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceRuleFromJson(json);
}

@freezed
abstract class RecurrenceException with _$RecurrenceException {
  const factory RecurrenceException({
    required String date, // YYYY-MM-DD
    String? status, // "cancelled" or null
    Map<String, dynamic>? overrides, // field overrides for this occurrence
  }) = _RecurrenceException;

  factory RecurrenceException.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceExceptionFromJson(json);
}

@freezed
abstract class ItemModel with _$ItemModel {
  const factory ItemModel({
    required String id,
    required String householdId,
    required ItemType type,
    required ItemStatus status,
    @Default(ItemAction.create) ItemAction action,
    required String title,
    String? summary,
    String? childId,
    String? childName,
    String? ownerId,
    String? ownerName,
    @TimestampConverter() DateTime? date,
    @TimestampConverter() DateTime? endDate,
    String? location,
    RecurrenceRule? recurrence,
    @Default([]) List<RecurrenceException> exceptions,
    String? sourceMessageId,
    String? targetItemId,
    String? targetItemTitle,
    @Default({}) Map<String, dynamic> changes,
    @Default({}) Map<String, dynamic> previousValues,
    @Default({}) Map<String, dynamic> extractedFields,
    @Default({}) Map<String, String> confidence,
    @Default([]) List<String> uncertainFields,
    @Default([]) List<String> suggestedActions,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _ItemModel;

  factory ItemModel.fromJson(Map<String, dynamic> json) =>
      _$ItemModelFromJson(json);

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel.fromJson({'id': doc.id, ...data});
  }
}
