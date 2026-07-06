import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../capture/data/models/source_message_model.dart';
import '../../capture/data/repositories/capture_repository.dart';
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

  String _firstName() {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.isEmpty) return '';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) return _buildEmptyContent(context);
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
        SliverToBoxAdapter(child: _buildEmptyContent(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final firstName = _firstName();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row with notification bell
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstName.isNotEmpty)
                      Text(
                        'Hi, $firstName!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'How is your day?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textBlack,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick action chips (mood/category style)
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.edit_note_rounded,
            label: 'Capture',
            color: AppColors.chipPurple,
            bgColor: AppColors.lavenderLight,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.mic_rounded,
            label: 'Voice',
            color: AppColors.chipOrange,
            bgColor: AppColors.orangeLight,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.image_rounded,
            label: 'Photo',
            color: AppColors.chipGreen,
            bgColor: AppColors.greenLight,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.email_outlined,
            label: 'Email',
            color: AppColors.chipBlue,
            bgColor: AppColors.blueLight,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All clear today!',
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Nothing to review right now',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick capture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hint cards in a grid
          Row(
            children: [
              Expanded(
                child: _FreshHintCard(
                  icon: Icons.share_rounded,
                  iconColor: AppColors.chipBlue,
                  bgColor: AppColors.blueLight,
                  title: 'Share',
                  subtitle: 'From other apps',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FreshHintCard(
                  icon: Icons.email_rounded,
                  iconColor: AppColors.chipPurple,
                  bgColor: AppColors.lavenderLight,
                  title: 'Email',
                  subtitle: 'Forward to Nabbo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FreshHintCard(
                  icon: Icons.edit_note_rounded,
                  iconColor: AppColors.chipGreen,
                  bgColor: AppColors.greenLight,
                  title: 'Note',
                  subtitle: 'Type a quick note',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FreshHintCard(
                  icon: Icons.mic_rounded,
                  iconColor: AppColors.chipOrange,
                  bgColor: AppColors.orangeLight,
                  title: 'Voice',
                  subtitle: 'Speak it out',
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    List<SourceMessageModel> messages,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inbox_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${messages.length} item${messages.length == 1 ? '' : 's'} captured',
                    style: const TextStyle(
                      color: AppColors.textBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${messages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Section title
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Captures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SourceMessageCard(message: msg),
              )),
          const SizedBox(height: 80), // space for FAB
        ],
      ),
    );
  }
}

// -- Reusable widgets --

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textBlack,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshHintCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _FreshHintCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textBlack,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceMessageCard extends StatelessWidget {
  final SourceMessageModel message;

  const _SourceMessageCard({required this.message});

  Color get _iconColor => switch (message.inputMethod) {
        InputMethod.freeText => AppColors.chipPurple,
        InputMethod.voice => AppColors.chipOrange,
        InputMethod.mobileShare => AppColors.chipGreen,
        InputMethod.emailForwarding => AppColors.chipBlue,
        InputMethod.imageUpload => AppColors.chipPink,
        InputMethod.screenshot => AppColors.chipPink,
        InputMethod.pdfUpload => AppColors.chipCoral,
      };

  Color get _iconBg => switch (message.inputMethod) {
        InputMethod.freeText => AppColors.lavenderLight,
        InputMethod.voice => AppColors.orangeLight,
        InputMethod.mobileShare => AppColors.greenLight,
        InputMethod.emailForwarding => AppColors.blueLight,
        InputMethod.imageUpload => AppColors.pinkLight,
        InputMethod.screenshot => AppColors.pinkLight,
        InputMethod.pdfUpload => AppColors.coralLight,
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
        ProcessingStatus.pending => AppColors.textMuted,
        ProcessingStatus.processing => AppColors.primary,
        ProcessingStatus.completed => AppColors.success,
        ProcessingStatus.noActionFound => AppColors.textMuted,
        ProcessingStatus.failed => AppColors.error,
      };

  String get _statusLabel => switch (message.processingStatus) {
        ProcessingStatus.pending => 'Pending',
        ProcessingStatus.processing => 'Processing',
        ProcessingStatus.completed => 'Ready',
        ProcessingStatus.noActionFound => 'No action',
        ProcessingStatus.failed => 'Failed',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_inputIcon, size: 18, color: _iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _inputLabel,
                  style: const TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 12),
          // Content
          Text(
            message.originalContent,
            style: const TextStyle(
              color: AppColors.textBlack,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Timestamp
          if (message.receivedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              _formatTime(message.receivedAt!),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
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
