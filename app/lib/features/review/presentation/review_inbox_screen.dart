import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';
import 'review_detail_screen.dart';
import '../../today/presentation/edit_item_screen.dart';

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
    final repo = ref.read(itemRepositoryProvider);

    return StreamBuilder<List<ItemModel>>(
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
                child: Text(
                  '${items.length} item${items.length == 1 ? '' : 's'} to review',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            final item = items[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ReviewCardPreview(
                item: item,
                householdId: householdId,
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewCardPreview extends ConsumerWidget {
  final ItemModel item;
  final String householdId;

  const _ReviewCardPreview({
    required this.item,
    required this.householdId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      onTap: () => _onTap(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type chip + child
          Row(
            children: [
              _buildTypeChip(),
              if (item.childName != null) ...[
                const SizedBox(width: 8),
                CategoryChip(label: item.childName!, color: AppColors.primary),
              ],
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Summary
          if (item.summary != null) ...[
            const SizedBox(height: 4),
            Text(
              item.summary!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Uncertain fields warning
          if (item.uncertainFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.warmYellow),
                const SizedBox(width: 4),
                Text(
                  '${item.uncertainFields.length} field${item.uncertainFields.length == 1 ? '' : 's'} to check',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warmYellow,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Quick approve row
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _approve(context, ref),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _edit(context),
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    final (label, color, bg) = switch (item.type) {
      ItemType.event => ('Event', AppColors.primary, AppColors.lavenderLight),
      ItemType.task => ('Task', AppColors.warmYellow, AppColors.yellowLight),
      ItemType.deadline =>
        ('Deadline', AppColors.softCoral, AppColors.coralLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  IconData _typeIcon() => switch (item.type) {
        ItemType.event => Icons.event_rounded,
        ItemType.task => Icons.check_circle_outline_rounded,
        ItemType.deadline => Icons.schedule_rounded,
      };

  void _onTap(BuildContext context) {
    // If has source message, open review detail to see full context
    if (item.sourceMessageId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(
            householdId: householdId,
            sourceMessageId: item.sourceMessageId!,
          ),
        ),
      );
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(itemRepositoryProvider).approve(householdId, item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Approved and added to feed.')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primary,
      ));
    }
  }

  void _edit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemScreen(householdId: householdId, item: item),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No items waiting for your review.\nNew extractions will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
