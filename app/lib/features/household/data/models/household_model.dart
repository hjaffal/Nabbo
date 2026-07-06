import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'household_model.freezed.dart';
part 'household_model.g.dart';

@freezed
abstract class HouseholdModel with _$HouseholdModel {
  const factory HouseholdModel({
    required String id,
    required String name,
    required String primaryUserId,
    required String timezone,
    required String language,
    String? emailAlias,
    @Default([]) List<String> memberIds,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _HouseholdModel;

  factory HouseholdModel.fromJson(Map<String, dynamic> json) =>
      _$HouseholdModelFromJson(json);

  factory HouseholdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HouseholdModel.fromJson({'id': doc.id, ...data});
  }
}

class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}
