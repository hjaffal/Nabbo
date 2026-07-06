import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../data/models/extracted_item_model.dart';
import '../data/repositories/review_repository.dart';
import 'review_card_screen.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
});

class ReviewInboxScreen extends ConsumerWidget {
  const ReviewInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: householdAsync.when(
        data: (household) {
          if (household == null) return const _EmptyState();
          return _ReviewList(householdId: household.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ReviewList extends ConsumerWidget {
  final String householdId;
  const _ReviewList({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reviewRepositoryProvider);

    return StreamBuilder<List<ExtractedItemModel>>(
      stream: repo.watchPendingItems(householdId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) return const _EmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      '${items.length} item${items.length == 1 ? '' : 's'} to review',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }

            final item = items[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ReviewCardPreview(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewCardScreen(
                      householdId: householdId,
                      item: item,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewCardPreview extends StatelessWidget {
  final ExtractedItemModel item;
  final VoidCallback onTap;

  const _ReviewCardPreview({required this.item, required this.onTap});

  Color get _typeColor => switch (item.itemType) {
        ExtractedItemType.event => AppColors.primary,
        ExtractedItemType.task => AppColors.warmYellow,
        ExtractedItemType.deadline => AppColors.softCoral,
        ExtractedItemType.payment => AppColors.softBlue,
        ExtractedItemType.form => AppColors.primary,
        ExtractedItemType.checklist => AppColors.softGreen,
        ExtractedItemType.change => AppColors.warmYellow,
        ExtractedItemType.risk => AppColors.softCoral,
        _ => AppColors.textSecondary,
      };

  Color get _typeBgColor => switch (item.itemType) {
        ExtractedItemType.event => AppColors.lavenderLight,
        ExtractedItemType.task => AppColors.yellowLight,
        ExtractedItemType.deadline => AppColors.coralLight,
        ExtractedItemType.payment => AppColors.blueLight,
        ExtractedItemType.form => AppColors.lavenderLight,
        ExtractedItemType.checklist => AppColors.greenLight,
        ExtractedItemType.change => AppColors.yellowLight,
        ExtractedItemType.risk => AppColors.coralLight,
        _ => AppColors.surfaceSoft,
      };

  IconData get _typeIcon => switch (item.itemType) {
        ExtractedItemType.event => Icons.event_rounded,
        ExtractedItemType.task => Icons.check_circle_outline_rounded,
        ExtractedItemType.deadline => Icons.schedule_rounded,
        ExtractedItemType.payment => Icons.payment_rounded,
        ExtractedItemType.form => Icons.description_rounded,
        ExtractedItemType.checklist => Icons.checklist_rounded,
        ExtractedItemType.change => Icons.change_circle_rounded,
        ExtractedItemType.risk => Icons.warning_rounded,
        _ => Icons.inbox_rounded,
      };

  String get _typeLabel => switch (item.itemType) {
        ExtractedItemType.event => 'Event',
        ExtractedItemType.task => 'Task',
        ExtractedItemType.deadline => 'Deadline',
        ExtractedItemType.payment => 'Payment',
        ExtractedItemType.form => 'Form',
        ExtractedItemType.checklist => 'Checklist',
        ExtractedItemType.change => 'Change',
        ExtractedItemType.risk => 'Risk',
        _ => 'Item',
      };

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type chip + member
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _typeBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon, size: 14, color: _typeColor),
                    const SizedBox(width: 4),
                    Text(
                      _typeLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _typeColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.affectedMemberName != null)
                CategoryChip(
                  label: item.affectedMemberName!,
                  color: AppColors.primary,
                ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Summary
          Text(
            item.operationalSummary,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Uncertain fields warning
          if (item.uncertainFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warmYellow),
                const SizedBox(width: 4),
                Text(
                  '${item.uncertainFields.length} field${item.uncertainFields.length == 1 ? '' : 's'} to check',
                  style: TextStyle(fontSize: 12, color: AppColors.warmYellow, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          // Suggested next step
          if (item.suggestedNextStep != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.suggestedNextStep!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 40, color: AppColors.softGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing to review right now.\nCapture something to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
