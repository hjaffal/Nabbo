import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
});

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      body: householdAsync.when(
        data: (household) {
          if (household == null) return const _EmptyState();
          return _FeedContent(householdId: household.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// A single feed item from any collection
class _FeedItem {
  final String id;
  final String collection;
  final String title;
  final String? subtitle;
  final String? affectedMember;
  final String? ownerName;
  final String status;
  final DateTime? dateTime;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final DocumentReference docRef;

  _FeedItem({
    required this.id,
    required this.collection,
    required this.title,
    this.subtitle,
    this.affectedMember,
    this.ownerName,
    required this.status,
    this.dateTime,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.docRef,
  });
}

class _FeedContent extends StatelessWidget {
  final String householdId;
  const _FeedContent({required this.householdId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final householdRef = db.collection('households').doc(householdId);

    return StreamBuilder<List<_FeedItem>>(
      stream: _buildFeedStream(householdRef),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your family feed',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),

            // Feed items grouped by day
            if (items.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final showDateHeader = index == 0 ||
                          !_isSameDay(items[index - 1].dateTime, item.dateTime);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            if (index > 0) const SizedBox(height: AppSpacing.xl),
                            _DateHeader(date: item.dateTime),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _FeedCard(item: item),
                          ),
                        ],
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Stream<List<_FeedItem>> _buildFeedStream(DocumentReference householdRef) {
    // Merge streams from all collections
    final eventsStream = householdRef.collection('events')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapEvent(d, householdRef)).toList());

    final tasksStream = householdRef.collection('tasks')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapTask(d, householdRef)).toList());

    final paymentsStream = householdRef.collection('payments')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapPayment(d, householdRef)).toList());

    final itemsStream = householdRef.collection('requiredItems')
        .where('packedStatus', isEqualTo: 'notReady')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapRequiredItem(d, householdRef)).toList());

    // Combine all streams
    return eventsStream.asyncExpand((events) {
      return tasksStream.asyncExpand((tasks) {
        return paymentsStream.asyncExpand((payments) {
          return itemsStream.map((items) {
            final all = [...events, ...tasks, ...payments, ...items];
            // Sort by date (items without dates go to top as "undated")
            all.sort((a, b) {
              if (a.dateTime == null && b.dateTime == null) return 0;
              if (a.dateTime == null) return -1;
              if (b.dateTime == null) return 1;
              return a.dateTime!.compareTo(b.dateTime!);
            });
            return all;
          });
        });
      });
    });
  }

  _FeedItem _mapEvent(QueryDocumentSnapshot doc, DocumentReference householdRef) {
    final d = doc.data() as Map<String, dynamic>;
    final time = (d['startDateTime'] as Timestamp?)?.toDate();
    return _FeedItem(
      id: doc.id,
      collection: 'events',
      title: d['title'] ?? 'Event',
      subtitle: d['location'] != null ? '📍 ${d['location']}' : null,
      affectedMember: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: d['status'] ?? 'confirmed',
      dateTime: time,
      icon: Icons.event_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.lavenderLight,
      docRef: householdRef.collection('events').doc(doc.id),
    );
  }

  _FeedItem _mapTask(QueryDocumentSnapshot doc, DocumentReference householdRef) {
    final d = doc.data() as Map<String, dynamic>;
    final due = (d['dueDate'] as Timestamp?)?.toDate();
    return _FeedItem(
      id: doc.id,
      collection: 'tasks',
      title: d['title'] ?? 'Task',
      subtitle: d['ownerName'] != null ? 'Owner: ${d['ownerName']}' : 'Owner missing',
      affectedMember: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: d['status'] ?? 'confirmed',
      dateTime: due ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.warmYellow,
      iconBg: AppColors.yellowLight,
      docRef: householdRef.collection('tasks').doc(doc.id),
    );
  }

  _FeedItem _mapPayment(QueryDocumentSnapshot doc, DocumentReference householdRef) {
    final d = doc.data() as Map<String, dynamic>;
    final due = (d['dueDate'] as Timestamp?)?.toDate();
    final amount = d['amount'];
    final currency = d['currency'] ?? 'EUR';
    return _FeedItem(
      id: doc.id,
      collection: 'payments',
      title: d['title'] ?? 'Payment',
      subtitle: amount != null ? '$currency $amount' : null,
      affectedMember: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: d['status'] ?? 'confirmed',
      dateTime: due ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.payment_rounded,
      iconColor: AppColors.softBlue,
      iconBg: AppColors.blueLight,
      docRef: householdRef.collection('payments').doc(doc.id),
    );
  }

  _FeedItem _mapRequiredItem(QueryDocumentSnapshot doc, DocumentReference householdRef) {
    final d = doc.data() as Map<String, dynamic>;
    final needed = (d['neededByDateTime'] as Timestamp?)?.toDate();
    return _FeedItem(
      id: doc.id,
      collection: 'requiredItems',
      title: d['name'] ?? 'Item to bring',
      subtitle: 'Pack this',
      affectedMember: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: 'notReady',
      dateTime: needed ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.backpack_rounded,
      iconColor: AppColors.softGreen,
      iconBg: AppColors.greenLight,
      docRef: householdRef.collection('requiredItems').doc(doc.id),
    );
  }
}

// --- Date Header ---
class _DateHeader extends StatelessWidget {
  final DateTime? date;
  const _DateHeader({this.date});

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDate(date),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Undated';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final itemDay = DateTime(d.year, d.month, d.day);

    if (itemDay == today) return 'Today';
    if (itemDay == tomorrow) return 'Tomorrow';

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

// --- Feed Card ---
class _FeedCard extends StatelessWidget {
  final _FeedItem item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                if (item.subtitle != null)
                  Text(item.subtitle!, style: Theme.of(context).textTheme.bodySmall),
                if (item.affectedMember != null) ...[
                  const SizedBox(height: 4),
                  CategoryChip(label: item.affectedMember!, color: AppColors.primary),
                ],
              ],
            ),
          ),

          // Time + action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.dateTime != null)
                Text(
                  '${item.dateTime!.hour.toString().padLeft(2, '0')}:${item.dateTime!.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              const SizedBox(height: 4),
              _ActionChip(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Action Chip on Feed Card ---
class _ActionChip extends StatelessWidget {
  final _FeedItem item;
  const _ActionChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final label = switch (item.collection) {
      'tasks' => 'Done',
      'payments' => 'Paid',
      'requiredItems' => 'Packed',
      _ => null,
    };

    if (label == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final update = switch (item.collection) {
          'tasks' => {'status': 'completed'},
          'payments' => {'status': 'paid'},
          'requiredItems' => {'packedStatus': 'ready'},
          _ => <String, dynamic>{},
        };
        await item.docRef.update(update);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.softGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.softGreen),
        ),
      ),
    );
  }
}

// --- Empty State ---
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
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 40, color: AppColors.softGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing in your feed yet.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture something and approve it\nto see it here.',
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
