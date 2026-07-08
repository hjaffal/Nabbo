import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';
import '../../today/presentation/edit_item_screen.dart';

/// Shows the review detail for a source message.
/// If AI is still processing → shows loader.
/// If AI is done → shows extracted items (from items/ collection) with approve/edit/delete actions.
class ReviewDetailScreen extends ConsumerWidget {
  final String householdId;
  final String sourceMessageId;

  const ReviewDetailScreen({
    super.key,
    required this.householdId,
    required this.sourceMessageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = FirebaseFirestore.instance;
    final sourceRef = db
        .collection('households')
        .doc(householdId)
        .collection('sourceMessages')
        .doc(sourceMessageId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          TextButton(
            onPressed: () => _dismissSource(context, sourceRef),
            child:
                Text('Delete', style: TextStyle(color: AppColors.softCoral)),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: sourceRef.snapshots(),
        builder: (context, sourceSnap) {
          if (!sourceSnap.hasData || !sourceSnap.data!.exists) {
            return const Center(child: Text('Not found'));
          }

          final sourceData = sourceSnap.data!.data() as Map<String, dynamic>;
          final status = sourceData['processingStatus'] ?? 'pending';
          final content = sourceData['originalContent'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Original content
                SoftCard(
                  color: AppColors.surfaceSoft,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Original message',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(content,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Processing state
                if (status == 'pending' || status == 'processing') ...[
                  const _ProcessingState(),
                ] else if (status == 'failed') ...[
                  _FailedState(sourceRef: sourceRef),
                ] else if (status == 'noActionFound') ...[
                  const _NoActionState(),
                ] else ...[
                  // AI done — show items from items/ collection
                  _ExtractedItemsList(
                    householdId: householdId,
                    sourceMessageId: sourceMessageId,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _dismissSource(
      BuildContext context, DocumentReference sourceRef) async {
    await sourceRef.update({'processingStatus': 'dismissed'});
    if (context.mounted) Navigator.pop(context);
  }
}

class _ProcessingState extends StatelessWidget {
  const _ProcessingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Nabbo is reading this...',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Extracting actions, deadlines, and details.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _FailedState extends StatelessWidget {
  final DocumentReference sourceRef;
  const _FailedState({required this.sourceRef});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.softCoral),
        const SizedBox(height: 12),
        Text('Could not process this',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Try again or add details manually.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            await sourceRef.update({'processingStatus': 'pending'});
          },
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _NoActionState extends StatelessWidget {
  const _NoActionState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.info_outline_rounded, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('No clear action found',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
            'Nabbo couldn\'t find events, tasks, or deadlines in this message.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

/// Shows items linked to this source message from the items/ collection.
class _ExtractedItemsList extends ConsumerWidget {
  final String householdId;
  final String sourceMessageId;

  const _ExtractedItemsList({
    required this.householdId,
    required this.sourceMessageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(itemRepositoryProvider);

    return StreamBuilder<List<ItemModel>>(
      stream: repo.watchItemsBySource(householdId, sourceMessageId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.hourglass_empty_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('No items extracted yet',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                  'AI might still be processing. Wait a moment and check again.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          );
        }

        final pendingItems =
            items.where((i) => i.status == ItemStatus.pendingReview).toList();
        final reviewedItems =
            items.where((i) => i.status != ItemStatus.pendingReview).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingItems.isNotEmpty) ...[
              Text(
                  '${pendingItems.length} item${pendingItems.length > 1 ? 's' : ''} to review',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.lg),
              ...pendingItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ItemReviewCard(
                        item: item, householdId: householdId),
                  )),
            ],
            if (reviewedItems.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('${reviewedItems.length} already reviewed',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              ...reviewedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.softGreen),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  )),
            ],
            if (pendingItems.isEmpty && reviewedItems.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Icon(Icons.check_circle_rounded,
                  size: 40, color: AppColors.softGreen),
              const SizedBox(height: 8),
              Text('All items reviewed!',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ],
        );
      },
    );
  }
}

/// Card for a single pending item in review detail
class _ItemReviewCard extends ConsumerWidget {
  final ItemModel item;
  final String householdId;

  const _ItemReviewCard({required this.item, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdate = item.action == ItemAction.update;
    final isCancel = item.action == ItemAction.cancel;
    final isChange = isUpdate || isCancel;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: isCancel ? AppColors.coralLight : (isUpdate ? AppColors.blueLight : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + action + child
          Row(
            children: [
              _TypeChip(type: item.type),
              if (isChange) ...[
                const SizedBox(width: 6),
                _ActionChip(action: item.action),
              ],
              if (item.childName != null) ...[
                const SizedBox(width: 6),
                CategoryChip(label: item.childName!, color: AppColors.primary),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(item.title,
              style: Theme.of(context).textTheme.titleSmall),
          if (item.summary != null) ...[
            const SizedBox(height: 4),
            Text(item.summary!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.sm),

          // For updates: show what changed
          if (isUpdate && item.changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...item.changes.entries.map((e) {
              final oldVal = item.previousValues[e.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.softBlue),
                    const SizedBox(width: 4),
                    Text('${_formatKey(e.key)}: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    if (oldVal != null) ...[
                      Text('$oldVal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough, color: AppColors.textMuted)),
                      Text(' → ', style: Theme.of(context).textTheme.bodySmall),
                    ],
                    Flexible(
                      child: Text('${e.value}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }),
          ],

          // For cancellations: show what's being cancelled
          if (isCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.cancel_rounded, size: 14, color: AppColors.softCoral),
                const SizedBox(width: 4),
                Text('This will cancel the existing item',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.softCoral)),
              ],
            ),
          ],

          // Key fields (for create)
          if (!isChange) ...[
            if (item.date != null)
              _miniField(context, 'Date',
                  '${item.date!.toUtc().day}/${item.date!.toUtc().month}/${item.date!.toUtc().year} at ${item.date!.toUtc().hour.toString().padLeft(2, '0')}:${item.date!.toUtc().minute.toString().padLeft(2, '0')}'),
            if (item.location != null)
              _miniField(context, 'Location', item.location!),
            if (item.ownerName != null)
              _miniField(context, 'Owner', item.ownerName!),
          ],

          // Uncertain fields
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

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _approve(context, ref),
                  style: isCancel
                      ? FilledButton.styleFrom(backgroundColor: AppColors.softCoral)
                      : null,
                  child: Text(isCancel ? 'Confirm cancel' : (isUpdate ? 'Apply change' : 'Approve')),
                ),
              ),
              const SizedBox(width: 8),
              if (!isChange)
                OutlinedButton(
                  onPressed: () => _edit(context),
                  child: const Text('Edit'),
                ),
              if (!isChange) const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _delete(context, ref),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softCoral),
                child: Text(isChange ? 'Reject' : 'Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!.toLowerCase()}')
        .trim();
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(itemRepositoryProvider);

    if (item.action == ItemAction.update && item.targetItemId != null) {
      final updates = <String, dynamic>{};
      for (final entry in item.changes.entries) {
        updates[entry.key] = entry.value;
      }
      if (item.date != null && item.changes.containsKey('date')) {
        updates['date'] = item.date;
      }
      await repo.approveUpdate(householdId, item.id, item.targetItemId!, updates);
    } else if (item.action == ItemAction.cancel && item.targetItemId != null) {
      final isRecurring = item.recurrence != null;
      final cancelDate = item.date != null
          ? '${item.date!.year}-${item.date!.month.toString().padLeft(2, '0')}-${item.date!.day.toString().padLeft(2, '0')}'
          : null;
      await repo.approveCancel(householdId, item.id, item.targetItemId!,
          cancelDate: cancelDate, isRecurring: isRecurring);
    } else {
      // Normal create approval — require date if missing
      if (item.date == null && item.action == ItemAction.create) {
        final pickedDate = await _pickDateForApproval(context);
        if (pickedDate == null) return; // User cancelled
        // Save date then approve
        await repo.updateItem(householdId, item.id, {
          'date': Timestamp.fromDate(pickedDate),
        });
      }
      await repo.approve(householdId, item.id);
    }

    if (context.mounted) {
      final msg = item.action == ItemAction.cancel
          ? 'Item cancelled.'
          : (item.action == ItemAction.update ? 'Change applied.' : 'Approved and added to feed.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// Shows a date+time picker when approving an item without a date.
  /// Defaults to tomorrow morning (09:00).
  Future<DateTime?> _pickDateForApproval(BuildContext context) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final defaultDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

    final date = await showDatePicker(
      context: context,
      initialDate: defaultDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: 'When is this due?',
    );
    if (date == null) return null;

    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'What time?',
    );

    final hour = time?.hour ?? 9;
    final minute = time?.minute ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(itemRepositoryProvider).deleteItem(householdId, item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(item.action != ItemAction.create ? 'Change rejected.' : 'Deleted.')));
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

class _ActionChip extends StatelessWidget {
  final ItemAction action;
  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (action) {
      ItemAction.update => ('Change', AppColors.softBlue, AppColors.blueLight),
      ItemAction.cancel => ('Cancel', AppColors.softCoral, AppColors.coralLight),
      ItemAction.create => ('New', AppColors.softGreen, AppColors.greenLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ItemType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (type) {
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
      child: Text(label,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
