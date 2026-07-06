import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/family_member_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../data/models/extracted_item_model.dart';
import '../data/repositories/review_repository.dart';

class ReviewCardScreen extends ConsumerWidget {
  final String householdId;
  final ExtractedItemModel item;

  const ReviewCardScreen({super.key, required this.householdId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          TextButton(
            onPressed: () => _dismiss(context, ref),
            child: const Text('Dismiss'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone 1: Item type + source
            _buildTypeHeader(context),
            const SizedBox(height: AppSpacing.xl),

            // Zone 2: Operational summary
            _buildSummary(context),
            const SizedBox(height: AppSpacing.xl),

            // Zone 3: Extracted fields
            _buildFields(context),
            const SizedBox(height: AppSpacing.xl),

            // Zone 4: Uncertainty
            if (item.uncertainFields.isNotEmpty) ...[
              _buildUncertainty(context),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Zone 5: Suggested actions
            if (item.suggestedActions.isNotEmpty) ...[
              _buildSuggestions(context),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Zone 6: Actions
            _buildActions(context, ref),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeHeader(BuildContext context) {
    final typeLabel = switch (item.itemType) {
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

    final typeColor = switch (item.itemType) {
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

    return Row(
      children: [
        CategoryChip(label: typeLabel, color: typeColor),
        const SizedBox(width: 8),
        if (item.affectedMemberName != null)
          CategoryChip(label: item.affectedMemberName!, color: AppColors.primary),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.operationalSummary,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (item.suggestedNextStep != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.suggestedNextStep!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFields(BuildContext context) {
    if (item.extractedFields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Details'),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: item.extractedFields.map((field) {
              final confidenceColor = switch (field.confidence) {
                ConfidenceLevel.high => AppColors.softGreen,
                ConfidenceLevel.medium => AppColors.warmYellow,
                ConfidenceLevel.low => AppColors.softCoral,
                ConfidenceLevel.unknown => AppColors.textMuted,
              };

              final confidenceLabel = switch (field.confidence) {
                ConfidenceLevel.high => 'Clear',
                ConfidenceLevel.medium => 'Check this',
                ConfidenceLevel.low => 'Uncertain',
                ConfidenceLevel.unknown => 'Missing',
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        field.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        field.value ?? '—',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        confidenceLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: confidenceColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUncertainty(BuildContext context) {
    return SoftCard(
      color: AppColors.yellowLight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warmYellow, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs checking',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item.uncertainFields.join(', '),
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Suggested'),
        ...item.suggestedActions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(action, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: Approve
        FilledButton.icon(
          onPressed: () => _approve(context, ref),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve'),
        ),
        const SizedBox(height: AppSpacing.md),

        // Secondary row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _snooze(context, ref),
                icon: const Icon(Icons.snooze_rounded, size: 18),
                label: const Text('Snooze'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _assignOwner(context, ref),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Assign'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Mark handled
        TextButton(
          onPressed: () => _markHandled(context, ref),
          child: const Text('Already handled'),
        ),
      ],
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.approveItem(householdId, item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approved. Added to your plan.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.dismissItem(householdId, item.id, null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dismissed.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final repo = ref.read(reviewRepositoryProvider);
    await repo.snoozeItem(householdId, item.id, tomorrow);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snoozed until tomorrow.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _markHandled(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.markHandled(householdId, item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as handled.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _assignOwner(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(householdRepositoryProvider);
    final members = await repo.getFamilyMembers(householdId);

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<FamilyMemberModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign owner', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            ...members.map((m) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(m.name[0], style: TextStyle(color: AppColors.primary)),
                  ),
                  title: Text(m.name),
                  subtitle: Text(m.role.name),
                  onTap: () => Navigator.pop(ctx, m),
                )),
          ],
        ),
      ),
    );

    if (selected != null && context.mounted) {
      final reviewRepo = ref.read(reviewRepositoryProvider);
      await reviewRepo.assignOwner(
        householdId,
        item.id,
        ownerId: selected.id,
        ownerName: selected.name,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned to ${selected.name}.')),
        );
        Navigator.pop(context);
      }
    }
  }
}
