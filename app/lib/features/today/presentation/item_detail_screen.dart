import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/category_icons.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';
import '../../review/presentation/review_detail_screen.dart';
import 'edit_item_screen.dart';

/// Full screen detail view for an item (event, task, deadline)
class ItemDetailScreen extends ConsumerWidget {
  final String householdId;
  final ItemModel item;
  final DateTime? occurrenceDate; // non-null if viewing a specific recurring occurrence

  const ItemDetailScreen({
    super.key,
    required this.householdId,
    required this.item,
    this.occurrenceDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_typeLabel(item.type)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon + title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: CategoryIcons.getBackgroundColor(item.category, item.type),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(CategoryIcons.getIcon(item.category, item.type),
                      color: CategoryIcons.getColor(item.category, item.type), size: 26),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (item.summary != null) ...[
                        const SizedBox(height: 4),
                        Text(item.summary!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Status badge
            _buildStatusBadge(context),
            const SizedBox(height: AppSpacing.xl),

            // Info card
            SoftCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldRow(context, 'Type', _typeLabel(item.type)),
                  _fieldRow(context, 'Child', item.childName),
                  _fieldRow(context, 'Owner', item.ownerName),
                  _fieldRow(context, 'Date', _formatDateTime(item.date)),
                  if (item.endDate != null)
                    _fieldRow(
                        context, 'End date', _formatDateTime(item.endDate)),
                  if (item.location != null)
                    _locationRow(context, item.location!),
                  if (item.recurrence != null) ...[
                    _fieldRow(context, 'Recurrence',
                        _formatRecurrence(item.recurrence!)),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty)
                    _fieldRow(context, 'Notes', item.notes),
                  // Extracted fields
                  ...item.extractedFields.entries.map((e) {
                    if (e.value == null || e.value.toString().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _fieldRow(context, _formatKey(e.key),
                        e.value.toString());
                  }),
                ],
              ),
            ),

            // Confidence indicators
            if (item.uncertainFields.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              SoftCard(
                color: AppColors.yellowLight,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.warmYellow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.uncertainFields.length} field${item.uncertainFields.length == 1 ? '' : 's'} may need checking: ${item.uncertainFields.join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warmYellow,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl),

            // Action buttons
            if (item.status == ItemStatus.confirmed) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _markComplete(context, ref),
                  child: const Text('Mark complete'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleCancel(context, ref),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.softCoral),
                  child: Text(item.recurrence != null && occurrenceDate != null
                      ? 'Cancel this occurrence'
                      : 'Cancel'),
                ),
              ),
              if (item.recurrence != null && occurrenceDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _cancelAll(context, ref),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.softCoral),
                    child: const Text('Cancel entire series'),
                  ),
                ),
              ],
            ] else if (item.status == ItemStatus.pendingReview) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _approve(context, ref),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _delete(context, ref),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.softCoral),
                  child: const Text('Delete'),
                ),
              ),
            ],

            // View original source
            if (item.sourceMessageId != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton.icon(
                  onPressed: () => _viewSource(context),
                  icon: const Icon(Icons.article_outlined, size: 18),
                  label: const Text('View original message'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewSource(BuildContext context) {
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

  Widget _buildStatusBadge(BuildContext context) {
    final (label, color) = switch (item.status) {
      ItemStatus.pendingReview => ('Needs review', AppColors.warmYellow),
      ItemStatus.confirmed => ('Active', AppColors.softGreen),
      ItemStatus.completed => ('Done', AppColors.softGreen),
      ItemStatus.cancelled => ('Cancelled', AppColors.softCoral),
      ItemStatus.hidden => ('Hidden', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
      child: Text(label,
          style:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _fieldRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value ?? '— not set',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value == null ? AppColors.textMuted : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(BuildContext context, String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('Location',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openInMaps(location),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openInMaps(String location) {
    final encoded = Uri.encodeComponent(location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String? _formatDateTime(DateTime? dt) {
    if (dt == null) return null;
    final utc = dt.toUtc();
    return '${utc.day}/${utc.month}/${utc.year} at ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}';
  }

  String _formatRecurrence(RecurrenceRule rule) {
    final parts = <String>[rule.frequency];
    if (rule.dayOfWeek != null) parts.add('on ${rule.dayOfWeek}');
    return parts.join(' ');
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!.toLowerCase()}')
        .trim();
  }

  String _typeLabel(ItemType type) => switch (type) {
        ItemType.event => 'Event',
        ItemType.task => 'Task',
        ItemType.deadline => 'Deadline',
      };

  IconData _typeIcon(ItemType type) => switch (type) {
        ItemType.event => Icons.event_rounded,
        ItemType.task => Icons.check_circle_outline_rounded,
        ItemType.deadline => Icons.schedule_rounded,
      };

  Color _typeColor(ItemType type) => switch (type) {
        ItemType.event => AppColors.primary,
        ItemType.task => AppColors.warmYellow,
        ItemType.deadline => AppColors.softCoral,
      };

  Color _typeBgColor(ItemType type) => switch (type) {
        ItemType.event => AppColors.lavenderLight,
        ItemType.task => AppColors.yellowLight,
        ItemType.deadline => AppColors.coralLight,
      };

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(itemRepositoryProvider).approve(householdId, item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved and added to feed.')));
      Navigator.pop(context);
    }
  }

  Future<void> _markComplete(BuildContext context, WidgetRef ref) async {
    await ref.read(itemRepositoryProvider).complete(householdId, item.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    if (item.recurrence != null && occurrenceDate != null) {
      // Cancel single occurrence via exceptions array
      final dateStr =
          '${occurrenceDate!.year}-${occurrenceDate!.month.toString().padLeft(2, '0')}-${occurrenceDate!.day.toString().padLeft(2, '0')}';
      await ref.read(itemRepositoryProvider).cancelOccurrence(householdId, item.id, dateStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Occurrence cancelled')));
        Navigator.pop(context);
      }
    } else {
      // Cancel entire item
      await ref.read(itemRepositoryProvider).cancel(householdId, item.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _cancelAll(BuildContext context, WidgetRef ref) async {
    await ref.read(itemRepositoryProvider).cancel(householdId, item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entire series cancelled')));
      Navigator.pop(context);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(itemRepositoryProvider).deleteItem(householdId, item.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemScreen(
          householdId: householdId,
          item: item,
        ),
      ),
    );
  }
}
