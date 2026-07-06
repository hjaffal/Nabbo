import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../data/models/source_message_model.dart';
import '../data/repositories/capture_repository.dart';

/// Handles shared content from other apps (WhatsApp, screenshots, PDFs, etc.)
class ShareHandler {
  final WidgetRef ref;
  final BuildContext context;

  StreamSubscription? _intentSub;

  ShareHandler({required this.ref, required this.context});

  /// Start listening for shared content
  void initialize() {
    // Handle shared content when app is opened from share
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> files) {
      if (files.isNotEmpty) {
        _handleSharedFiles(files);
      }
    });

    // Handle shared content while app is running
    _intentSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
      if (files.isNotEmpty) {
        _handleSharedFiles(files);
      }
    });
  }

  void dispose() {
    _intentSub?.cancel();
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final householdRepo = ref.read(householdRepositoryProvider);
    final captureRepo = ref.read(captureRepositoryProvider);
    final household = await householdRepo.getHouseholdByUserId(userId);

    if (household == null) return;

    for (final file in files) {
      await _processSharedFile(file, household, userId, captureRepo);
    }

    // Show confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            files.length == 1
                ? 'Captured! Nabbo will process this.'
                : '${files.length} items captured.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Reset the intent
    ReceiveSharingIntent.instance.reset();
  }

  Future<void> _processSharedFile(
    SharedMediaFile file,
    HouseholdModel household,
    String userId,
    CaptureRepository captureRepo,
  ) async {
    final inputMethod = _getInputMethod(file);
    final content = _getContent(file);

    await captureRepo.captureShared(
      householdId: household.id,
      userId: userId,
      content: content,
      inputMethod: inputMethod,
      attachmentUrl: file.path,
      attachmentType: file.mimeType,
      sourceApp: null,
    );
  }

  InputMethod _getInputMethod(SharedMediaFile file) {
    if (file.type == SharedMediaType.image) {
      return InputMethod.imageUpload;
    } else if (file.type == SharedMediaType.file) {
      final path = file.path.toLowerCase();
      if (path.endsWith('.pdf')) return InputMethod.pdfUpload;
      return InputMethod.mobileShare;
    } else if (file.type == SharedMediaType.text) {
      return InputMethod.mobileShare;
    } else if (file.type == SharedMediaType.url) {
      return InputMethod.mobileShare;
    }
    return InputMethod.mobileShare;
  }

  String _getContent(SharedMediaFile file) {
    // For text shares, the message/text is in the path or thumbnail
    if (file.type == SharedMediaType.text ||
        file.type == SharedMediaType.url) {
      return file.path;
    }
    // For files/images, use the filename as content placeholder
    // Actual text extraction will happen in the Cloud Function (Phase 3)
    final filename = file.path.split('/').last;
    return '[${file.type.name}] $filename';
  }
}
