import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capture/data/models/source_message_model.dart';
import '../../capture/data/repositories/capture_repository.dart';
import '../../capture/presentation/capture_sheet.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
});

final _sourceMessagesProvider =
    StreamProvider.family<List<SourceMessageModel>, String>(
        (ref, householdId) {
  return ref.read(captureRepositoryProvider).watchSourceMessages(householdId);
});

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
      ),
      body: householdAsync.when(
        data: (household) {
          if (household == null) return const _EmptyTodayState();
          return _TodayContent(household: household);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCaptureSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nabbo it'),
      ),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  final HouseholdModel household;

  const _TodayContent({required this.household});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(_sourceMessagesProvider(household.id));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) return const _EmptyTodayState();
        return _MessagesView(messages: messages);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _MessagesView extends StatelessWidget {
  final List<SourceMessageModel> messages;

  const _MessagesView({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${messages.length} item${messages.length == 1 ? '' : 's'} captured. '
                  'Extraction coming in Phase 3.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Recent Captures',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Message list
        ...messages.map((msg) => _SourceMessageCard(message: msg)),
      ],
    );
  }
}

class _SourceMessageCard extends StatelessWidget {
  final SourceMessageModel message;

  const _SourceMessageCard({required this.message});

  IconData get _inputIcon => switch (message.inputMethod) {
        InputMethod.freeText => Icons.edit_note_rounded,
        InputMethod.voice => Icons.mic_rounded,
        InputMethod.mobileShare => Icons.share_rounded,
        InputMethod.emailForwarding => Icons.email_rounded,
        InputMethod.imageUpload => Icons.image_rounded,
        InputMethod.screenshot => Icons.screenshot_rounded,
        InputMethod.pdfUpload => Icons.picture_as_pdf_rounded,
      };

  String get _inputLabel => switch (message.inputMethod) {
        InputMethod.freeText => 'Text note',
        InputMethod.voice => 'Voice note',
        InputMethod.mobileShare => 'Shared',
        InputMethod.emailForwarding => 'Email',
        InputMethod.imageUpload => 'Image',
        InputMethod.screenshot => 'Screenshot',
        InputMethod.pdfUpload => 'PDF',
      };

  Color _statusColor(BuildContext context) =>
      switch (message.processingStatus) {
        ProcessingStatus.pending => Theme.of(context).colorScheme.outline,
        ProcessingStatus.processing =>
          Theme.of(context).colorScheme.primary,
        ProcessingStatus.completed =>
          Theme.of(context).colorScheme.primary,
        ProcessingStatus.noActionFound =>
          Theme.of(context).colorScheme.outline,
        ProcessingStatus.failed =>
          Theme.of(context).colorScheme.error,
      };

  String get _statusLabel => switch (message.processingStatus) {
        ProcessingStatus.pending => 'Pending',
        ProcessingStatus.processing => 'Processing...',
        ProcessingStatus.completed => 'Ready for review',
        ProcessingStatus.noActionFound => 'No action found',
        ProcessingStatus.failed => 'Failed',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  _inputIcon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _inputLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _statusColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              message.originalContent,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Timestamp
            if (message.receivedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTime(message.receivedAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing needs attention today.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nabbo a message when something comes in.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
