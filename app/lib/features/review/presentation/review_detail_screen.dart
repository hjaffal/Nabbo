import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../data/models/extracted_item_model.dart';
import '../data/repositories/review_repository.dart';
import '../data/services/approval_service.dart';
import '../../household/data/models/family_member_model.dart';
import '../../household/data/repositories/household_repository.dart';

/// Shows the review detail for a source message.
/// If AI is still processing → shows loader.
/// If AI is done → shows extracted items with approve/delete actions.
class ReviewDetailScreen extends ConsumerWidget {
  final String householdId;
  final String sourceMessageId;

  const ReviewDetailScreen({super.key, required this.householdId, required this.sourceMessageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = FirebaseFirestore.instance;
    final sourceRef = db.collection('households').doc(householdId).collection('sourceMessages').doc(sourceMessageId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          TextButton(
            onPressed: () => _dismissSource(context, sourceRef),
            child: Text('Delete', style: TextStyle(color: AppColors.softCoral)),
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
                      Text('Original message', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(content, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Processing state
                if (status == 'pending' || status == 'processing') ...[
                  _ProcessingState(),
                ] else if (status == 'failed') ...[
                  _FailedState(sourceRef: sourceRef),
                ] else if (status == 'noActionFound') ...[
                  _NoActionState(),
                ] else ...[
                  // AI done — show extracted items
                  _ExtractedItemsList(
                    householdId: householdId,
                    sourceMessageId: sourceMessageId,
                    ref: ref,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _dismissSource(BuildContext context, DocumentReference sourceRef) async {
    await sourceRef.update({'processingStatus': 'dismissed'});
    if (context.mounted) Navigator.pop(context);
  }
}

class _ProcessingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Nabbo is reading this...', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Extracting actions, deadlines, and details.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
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
        Text('Could not process this', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Try again or add details manually.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.info_outline_rounded, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('No clear action found', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Nabbo couldn\'t find events, tasks, or deadlines in this message.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

class _ExtractedItemsList extends StatelessWidget {
  final String householdId;
  final String sourceMessageId;
  final WidgetRef ref;

  const _ExtractedItemsList({required this.householdId, required this.sourceMessageId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('households').doc(householdId)
          .collection('extractedItems')
          .where('sourceMessageId', isEqualTo: sourceMessageId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('No items extracted yet', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text('AI might still be processing. Wait a moment and check again.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
          );
        }

        final pendingDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['reviewStatus'] == 'pendingReview';
        }).toList();

        final approvedDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['reviewStatus'] != 'pendingReview';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingDocs.isNotEmpty) ...[
              Text('${pendingDocs.length} item${pendingDocs.length > 1 ? 's' : ''} to review', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.lg),
              ...pendingDocs.map((doc) {
                ExtractedItemModel? item;
                try {
                  item = ExtractedItemModel.fromFirestore(doc);
                } catch (_) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ExtractedItemCard(
                    item: item,
                    householdId: householdId,
                    ref: ref,
                  ),
                );
              }),
            ],
            if (approvedDocs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('${approvedDocs.length} already reviewed', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              ...approvedDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.softGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      data['operationalSummary'] ?? 'Item',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                );
              }),
            ],
            if (pendingDocs.isEmpty && approvedDocs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Icon(Icons.check_circle_rounded, size: 40, color: AppColors.softGreen),
              const SizedBox(height: 8),
              Text('All items reviewed!', style: Theme.of(context).textTheme.titleSmall),
            ],
          ],
        );
      },
    );
  }
}

class _ExtractedItemCard extends StatelessWidget {
  final ExtractedItemModel item;
  final String householdId;
  final WidgetRef ref;

  const _ExtractedItemCard({required this.item, required this.householdId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + member
          Row(
            children: [
              CategoryChip(label: item.itemType.name, color: AppColors.primary),
              if (item.affectedMemberName != null) ...[
                const SizedBox(width: 6),
                CategoryChip(label: item.affectedMemberName!, color: AppColors.primary),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Summary
          Text(item.operationalSummary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),

          // Fields
          if (item.extractedFields.isNotEmpty) ...[
            ...item.extractedFields.take(4).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text('${f.name}: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(f.value ?? '—', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                )),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _approve(context),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton(
                onPressed: () => _dismiss(context),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final service = ref.read(approvalServiceProvider);
    await service.approveAndCommit(householdId, item);

    // Also mark source as done if all items reviewed
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approved and added to feed.')),
      );
    }
  }

  Future<void> _dismiss(BuildContext context) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.dismissItem(householdId, item.id, null);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted.')),
      );
    }
  }
}
