import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

enum EventStatus {
  pending,
  confirmed,
  changed,
  cancelled,
  completed,
  missed,
}

@freezed
abstract class EventModel with _$EventModel {
  const factory EventModel({
    required String id,
    required String householdId,
    required String title,
    String? affectedMemberId,
    String? affectedMemberName,
    @TimestampConverter() DateTime? startDateTime,
    @TimestampConverter() DateTime? endDateTime,
    String? location,
    String? ownerId,
    String? ownerName,
    String? relatedSourceId,
    @Default([]) List<String> relatedTaskIds,
    String? relatedChecklistId,
    @Default([]) List<String> relatedRequiredItemIds,
    String? recurrence,
    EventStatus? status,
    String? confidenceLevel,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromJson({'id': doc.id, ...data});
  }
}
