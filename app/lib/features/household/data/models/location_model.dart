import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

enum LocationType {
  home,
  school,
  sportsClub,
  activityVenue,
  doctor,
  caregiverLocation,
  pickupPoint,
  dropoffPoint,
  other,
}

@freezed
abstract class LocationModel with _$LocationModel {
  const factory LocationModel({
    required String id,
    required String householdId,
    required String name,
    String? address,
    LocationType? type,
    @Default([]) List<String> linkedMemberIds,
    @Default([]) List<String> linkedRoutineIds,
    @Default([]) List<String> linkedEventIds,
    String? travelNotes,
    String? defaultTravelTime,
    String? confidence,
    @TimestampConverter() DateTime? createdAt,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel.fromJson({'id': doc.id, ...data});
  }
}
