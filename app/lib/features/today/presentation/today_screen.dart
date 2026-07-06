import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../capture/data/models/source_message_model.dart';
import '../../capture/data/repositories/capture_repository.dart';
import '../../capture/presentation/capture_sheet.dart';
import '../../capture/presentation/voice_capture_sheet.dart';
import '../../capture/presentation/image_capture_sheet.dart';
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _userName() {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.isEmpty) return '';
    return ', ${name.split(' ').first}';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      body: SafeArea(
        child: householdAsync.when(
          data: (household) {
            if (household == null) return _buildEmpty(context);
            return _buildWithHousehold(context, ref, household);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'image',
            onPressed: () => showImageCaptureSheet(context),
            child: const Icon(Icons.image_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'voice',
            onPressed: () => showVoiceCaptureSheet(context),
            child: const Icon(Icons.mic_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'text',
            onPressed: () => showCaptureSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Nabbo it'),
          ),
        ],
      ),
    );
  }

  Widget _buildWithHousehold(
    BuildContext context,
    WidgetRef ref,
    HouseholdModel household,
  ) {
    final messagesAsync = ref.watch(_sourceMessagesProvider(household.id));

    return CustomScrollView(
      slivers: [
        // Greeting header with gradient background
        SliverToBoxAdapter(child: _buildHeader(context)),
        // Content
        SliverToBoxAdapter(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) return _buildEmptyCards(context);
              return _buildMessagesList(context, messages);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildEmptyCards(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepTeal, Color(0xFF1A5C5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}${_userName()}.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textOnDarkMuted,
                          ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textOnDark,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.limeAccent,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.deepTeal),
                SizedBox(width: 6),
                Text(
                  'Today is clear',
                  style: TextStyle(
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ColorfulHintCard(
            color: AppColors.skyBlueCard,
            icon: Icons.share_outlined,
            title: 'Share something',
            subtitle: 'Share a message or screenshot from another app',
          ),
          const SizedBox(height: 10),
          _ColorfulHintCard(
            color: AppColors.lavenderCard,
            icon: Icons.email_outlined,
            title: 'Forward an email',
            subtitle: 'Forward school or activity emails to Nabbo',
          ),
          const SizedBox(height: 10),
          _ColorfulHintCard(
            color: AppColors.mintCard,
            icon: Icons.edit_note_outlined,
            title: 'Type a quick note',
            subtitle: 'e.g. "Adam has football Friday at 18:30"',
          ),
          const SizedBox(height: 10),
          _ColorfulHintCard(
            color: AppColors.peachCard,
            icon: Icons.mic_outlined,
            title: 'Send a voice note',
            subtitle: 'Speak it, Nabbo will figure it out',
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    List<SourceMessageModel> messages,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.skyBlueCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.deepTeal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${messages.length} item${messages.length == 1 ? '' : 's'} captured. Extraction coming in Phase 3.',
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Recent Captures',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          ...messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SourceMessageCard(message: msg),
              )),
          const SizedBox(height: 80), // space for FAB
        ],
      ),
    );
  }
}

class _ColorfulHintCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ColorfulHintCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.deepTeal, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.deepTeal.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.deepTeal.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _SourceMessageCard extends StatelessWidget {
  final SourceMessageModel message;

  const _SourceMessageCard({required this.message});

  Color get _cardColor => switch (message.inputMethod) {
        InputMethod.freeText => AppColors.sunshineCard,
        InputMethod.voice => AppColors.peachCard,
        InputMethod.mobileShare => AppColors.mintCard,
        InputMethod.emailForwarding => AppColors.skyBlueCard,
        InputMethod.imageUpload => AppColors.lavenderCard,
        InputMethod.screenshot => AppColors.lavenderCard,
        InputMethod.pdfUpload => AppColors.blushPink,
      };

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

  Color _statusColor() => switch (message.processingStatus) {
        ProcessingStatus.pending => AppColors.textSecondary,
        ProcessingStatus.processing => AppColors.vibrantTeal,
        ProcessingStatus.completed => AppColors.vibrantTeal,
        ProcessingStatus.noActionFound => AppColors.textSecondary,
        ProcessingStatus.failed => AppColors.coralAlert,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.deepTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_inputIcon, size: 16, color: AppColors.deepTeal),
              ),
              const SizedBox(width: 8),
              Text(
                _inputLabel,
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content
          Text(
            message.originalContent,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Timestamp
          if (message.receivedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatTime(message.receivedAt!),
              style: TextStyle(
                color: AppColors.deepTeal.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ],
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
