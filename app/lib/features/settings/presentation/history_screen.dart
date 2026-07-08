import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/category_icons.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';
import '../../today/presentation/item_detail_screen.dart';

/// Shows hidden and completed items with ability to restore them.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _getHouseholdId(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('History')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _HistoryContent(householdId: snapshot.data!);
      },
    );
  }

  Future<String> _getHouseholdId(WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final household = await ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
    return household!.id;
  }
}

class _HistoryContent extends ConsumerWidget {
  final String householdId;
  const _HistoryContent({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsRef = FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('items')
        .where('status', whereIn: ['hidden', 'completed'])
        .orderBy('updatedAt', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No history yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Completed and hidden items will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              try {
                final item = ItemModel.fromFirestore(doc);
                return _HistoryTile(item: item, householdId: householdId, ref: ref);
              } catch (_) {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ItemModel item;
  final String householdId;
  final WidgetRef ref;

  const _HistoryTile({required this.item, required this.householdId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final icon = CategoryIcons.getIcon(item.category, item.type);
    final color = CategoryIcons.getColor(item.category, item.type);
    final isHidden = item.status == ItemStatus.hidden;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHidden ? AppColors.textMuted.withValues(alpha: 0.1) : AppColors.softGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isHidden ? 'Hidden' : 'Completed',
                style: TextStyle(fontSize: 10, color: isHidden ? AppColors.textMuted : AppColors.softGreen),
              ),
            ),
            if (item.childName != null) ...[
              const SizedBox(width: 6),
              Text(item.childName!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final repo = ref.read(itemRepositoryProvider);
            if (value == 'restore') {
              await repo.updateItem(householdId, item.id, {'status': 'confirmed'});
            } else if (value == 'delete') {
              await repo.deleteItem(householdId, item.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'restore', child: Text('Restore to Feed')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete permanently', style: TextStyle(color: AppColors.softCoral)),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(householdId: householdId, item: item),
            ),
          );
        },
      ),
    );
  }
}
