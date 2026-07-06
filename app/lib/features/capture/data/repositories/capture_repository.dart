import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/source_message_model.dart';

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  return CaptureRepository(FirebaseFirestore.instance);
});

class CaptureRepository {
  final FirebaseFirestore _firestore;

  CaptureRepository(this._firestore);

  CollectionReference _sourceMessagesRef(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('sourceMessages');

  /// Create a new source message from free text input
  Future<SourceMessageModel> captureText({
    required String householdId,
    required String userId,
    required String text,
  }) async {
    final docRef = _sourceMessagesRef(householdId).doc();
    final now = DateTime.now();

    final message = SourceMessageModel(
      id: docRef.id,
      householdId: householdId,
      submittedBy: userId,
      inputMethod: InputMethod.freeText,
      originalContent: text,
      processingStatus: ProcessingStatus.pending,
      receivedAt: now,
    );

    await docRef.set({
      'householdId': householdId,
      'submittedBy': userId,
      'inputMethod': InputMethod.freeText.name,
      'originalContent': text,
      'processingStatus': ProcessingStatus.pending.name,
      'linkedExtractedItemIds': [],
      'receivedAt': Timestamp.fromDate(now),
    });

    return message;
  }

  /// Create a source message from voice transcription
  Future<SourceMessageModel> captureVoice({
    required String householdId,
    required String userId,
    required String transcript,
    String? audioUrl,
  }) async {
    final docRef = _sourceMessagesRef(householdId).doc();
    final now = DateTime.now();

    final message = SourceMessageModel(
      id: docRef.id,
      householdId: householdId,
      submittedBy: userId,
      inputMethod: InputMethod.voice,
      originalContent: transcript,
      attachmentUrl: audioUrl,
      attachmentType: 'audio',
      processingStatus: ProcessingStatus.pending,
      receivedAt: now,
    );

    await docRef.set({
      'householdId': householdId,
      'submittedBy': userId,
      'inputMethod': InputMethod.voice.name,
      'originalContent': transcript,
      'attachmentUrl': audioUrl,
      'attachmentType': 'audio',
      'processingStatus': ProcessingStatus.pending.name,
      'linkedExtractedItemIds': [],
      'receivedAt': Timestamp.fromDate(now),
    });

    return message;
  }

  /// Create a source message from shared content (images, PDFs, etc.)
  Future<SourceMessageModel> captureShared({
    required String householdId,
    required String userId,
    required String content,
    required InputMethod inputMethod,
    String? attachmentUrl,
    String? attachmentType,
    String? sourceApp,
  }) async {
    final docRef = _sourceMessagesRef(householdId).doc();
    final now = DateTime.now();

    final message = SourceMessageModel(
      id: docRef.id,
      householdId: householdId,
      submittedBy: userId,
      inputMethod: inputMethod,
      originalContent: content,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      sourceApp: sourceApp,
      processingStatus: ProcessingStatus.pending,
      receivedAt: now,
    );

    await docRef.set({
      'householdId': householdId,
      'submittedBy': userId,
      'inputMethod': inputMethod.name,
      'originalContent': content,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'sourceApp': sourceApp,
      'processingStatus': ProcessingStatus.pending.name,
      'linkedExtractedItemIds': [],
      'receivedAt': Timestamp.fromDate(now),
    });

    return message;
  }

  /// Get all source messages for a household
  Stream<List<SourceMessageModel>> watchSourceMessages(String householdId) {
    return _sourceMessagesRef(householdId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SourceMessageModel.fromFirestore(doc))
            .toList());
  }

  /// Get recent source messages
  Future<List<SourceMessageModel>> getRecentMessages(
    String householdId, {
    int limit = 20,
  }) async {
    final snapshot = await _sourceMessagesRef(householdId)
        .orderBy('receivedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => SourceMessageModel.fromFirestore(doc))
        .toList();
  }

  /// Update processing status
  Future<void> updateProcessingStatus(
    String householdId,
    String messageId,
    ProcessingStatus status,
  ) async {
    await _sourceMessagesRef(householdId).doc(messageId).update({
      'processingStatus': status.name,
      'processedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a source message
  Future<void> deleteSourceMessage(String householdId, String messageId) async {
    await _sourceMessagesRef(householdId).doc(messageId).delete();
  }
}
