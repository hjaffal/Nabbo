import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../review/presentation/review_detail_screen.dart';
import '../../today/presentation/item_detail_screen.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _getHouseholdId(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _NotificationsContent(householdId: snapshot.data!);
      },
    );
  }

  Future<String> _getHouseholdId(WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final household = await ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
    return household!.id;
  }
}

class _NotificationsContent extends StatelessWidget {
  final String householdId;
  const _NotificationsContent({required this.householdId});

  @override
  Widget build(BuildContext context) {
    final notificationsRef = FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(notificationsRef),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
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
                  Icon(Icons.notifications_none_rounded,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text("We'll let you know when something needs attention.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.surfaceSoft),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _NotificationTile(
                doc: doc,
                data: data,
                householdId: householdId,
              );
            },
          );
        },
      ),
    );
  }

  void _markAllRead(Query ref) async {
    final snap = await ref.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      if ((doc.data() as Map<String, dynamic>)['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();
  }
}

class _NotificationTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final String householdId;

  const _NotificationTile({
    required this.doc,
    required this.data,
    required this.householdId,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = data['read'] != true;
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final type = data['type'] as String? ?? '';

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.softCoral.withValues(alpha: 0.1),
        child: Icon(Icons.delete_outline, color: AppColors.softCoral),
      ),
      onDismissed: (_) => doc.reference.delete(),
      child: ListTile(
        onTap: () => _onTap(context),
        leading: _buildIcon(type, isUnread),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty)
              Text(body, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (createdAt != null)
              Text(timeago.format(createdAt),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildIcon(String type, bool isUnread) {
    final (icon, color) = switch (type) {
      'review_needed' => (Icons.rate_review_rounded, AppColors.warmYellow),
      'change_detected' => (Icons.change_circle_rounded, AppColors.softBlue),
      'deadline' => (Icons.schedule_rounded, AppColors.softCoral),
      'event_reminder' => (Icons.event_rounded, AppColors.primary),
      'daily_brief' => (Icons.wb_sunny_rounded, AppColors.warmYellow),
      _ => (Icons.notifications_rounded, AppColors.textMuted),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _onTap(BuildContext context) {
    // Mark as read
    if (data['read'] != true) {
      doc.reference.update({'read': true});
    }

    // Navigate based on type
    final itemId = data['itemId'] as String?;
    final sourceMessageId = data['sourceMessageId'] as String?;

    if (sourceMessageId != null && (data['type'] == 'review_needed' || data['type'] == 'change_detected')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(
            householdId: householdId,
            sourceMessageId: sourceMessageId,
          ),
        ),
      );
    } else if (itemId != null) {
      // Load item and navigate to detail
      _navigateToItem(context, itemId);
    }
  }

  Future<void> _navigateToItem(BuildContext context, String itemId) async {
    final doc = await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('items')
        .doc(itemId)
        .get();

    if (!doc.exists || !context.mounted) return;

    final item = ItemModel.fromFirestore(doc);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(householdId: householdId, item: item),
      ),
    );
  }
}
