import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'household_model.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

enum PaymentStatus {
  pending,
  paid,
  overdue,
  dismissed,
  unknown,
}

@freezed
abstract class PaymentModel with _$PaymentModel {
  const factory PaymentModel({
    required String id,
    required String householdId,
    required String title,
    double? amount,
    String? currency,
    String? affectedMemberId,
    String? affectedMemberName,
    String? relatedEventId,
    String? relatedSourceId,
    String? relatedDeadlineId,
    String? ownerId,
    String? ownerName,
    String? paymentMethod,
    String? paymentLink,
    @TimestampConverter() DateTime? dueDate,
    PaymentStatus? status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _PaymentModel;

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel.fromJson({'id': doc.id, ...data});
  }
}
