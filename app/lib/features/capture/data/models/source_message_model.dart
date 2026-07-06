import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../household/data/models/household_model.dart';

part 'source_message_model.freezed.dart';
part 'source_message_model.g.dart';

enum InputMethod {
  freeText,
  voice,
  mobileShare,
  emailForwarding,
  imageUpload,
  screenshot,
  pdfUpload,
}

enum ProcessingStatus {
  pending,
  processing,
  completed,
  noActionFound,
  failed,
}

@freezed
abstract class SourceMessageModel with _$SourceMessageModel {
  const factory SourceMessageModel({
    required String id,
    required String householdId,
    required String submittedBy,
    required InputMethod inputMethod,
    required String originalContent,
    String? attachmentUrl,
    String? attachmentType,
    String? sourceApp,
    String? extractedText,
    String? language,
    @Default(ProcessingStatus.pending) ProcessingStatus processingStatus,
    @Default([]) List<String> linkedExtractedItemIds,
    @TimestampConverter() DateTime? receivedAt,
    @TimestampConverter() DateTime? processedAt,
  }) = _SourceMessageModel;

  factory SourceMessageModel.fromJson(Map<String, dynamic> json) =>
      _$SourceMessageModelFromJson(json);

  factory SourceMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SourceMessageModel.fromJson({'id': doc.id, ...data});
  }
}
