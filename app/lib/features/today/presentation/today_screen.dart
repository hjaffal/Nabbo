import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../review/presentation/review_card_screen.dart';
import '../../review/data/models/extracted_item_model.dart';

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

/// Feed item model
class _FeedItem {
  final String id;
  final String collection;
  final String title;
  final String? subtitle;
  final String? childName;
  final String? ownerName;
  final String status; // confirmed, pendingReview, completed, paid, etc.
  final DateTime? dateTime;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String type; // event, task, payment, requiredItem, pending
  final DocumentReference? docRef;
  final ExtractedItemModel? extractedItem; // for pending items
  final Map<String, dynamic>? rawData;

  _FeedItem({
    required this.id,
    required this.collection,
    required this.title,
    this.subtitle,
    this.childName,
    this.ownerName,
    required this.status,
    this.dateTime,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.type,
    this.docRef,
    this.extractedItem,
    this.rawData,
  });

  bool get isPending => status == 'pendingReview';
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
                            child: _FeedCard(
                              item: item,
                              householdId: householdId,
                            ),
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
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Stream<List<_FeedItem>> _buildFeedStream(DocumentReference householdRef) {
    // Pending review items (show in feed as "awaiting review")
    final pendingStream = householdRef.collection('extractedItems')
        .where('reviewStatus', isEqualTo: 'pendingReview')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapPending(d)).toList());

    // Committed items
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

    return pendingStream.asyncExpand((pending) {
      return eventsStream.asyncExpand((events) {
        return tasksStream.asyncExpand((tasks) {
          return paymentsStream.asyncExpand((payments) {
            return itemsStream.map((items) {
              final all = [...pending, ...events, ...tasks, ...payments, ...items];
              // Pending items first, then by date
              all.sort((a, b) {
                if (a.isPending && !b.isPending) return -1;
                if (!a.isPending && b.isPending) return 1;
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
    });
  }

  _FeedItem _mapPending(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final created = (d['createdAt'] as Timestamp?)?.toDate();

    // Try to build ExtractedItemModel for detail view
    ExtractedItemModel? model;
    try {
      model = ExtractedItemModel.fromFirestore(doc);
    } catch (_) {}

    return _FeedItem(
      id: doc.id,
      collection: 'extractedItems',
      title: d['operationalSummary'] ?? 'New item',
      subtitle: 'Awaiting review',
      childName: d['affectedMemberName'],
      ownerName: null,
      status: 'pendingReview',
      dateTime: created,
      icon: Icons.pending_actions_rounded,
      iconColor: AppColors.warmYellow,
      iconBg: AppColors.yellowLight,
      type: d['itemType'] ?? 'unknown',
      extractedItem: model,
      rawData: d,
    );
  }

  _FeedItem _mapEvent(QueryDocumentSnapshot doc, DocumentReference householdRef) {
    final d = doc.data() as Map<String, dynamic>;
    final time = (d['startDateTime'] as Timestamp?)?.toDate();
    return _FeedItem(
      id: doc.id,
      collection: 'events',
      title: d['title'] ?? 'Event',
      subtitle: d['location'] != null ? '📍 ${d['location']}' : null,
      childName: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: d['status'] ?? 'confirmed',
      dateTime: time ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.event_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.lavenderLight,
      type: 'event',
      docRef: householdRef.collection('events').doc(doc.id),
      rawData: d,
    );
  }

  _FeedItem _mapTask(QueryDocumentSnapshot doc, DocumentReference householdRef) {
    final d = doc.data() as Map<String, dynamic>;
    final due = (d['dueDate'] as Timestamp?)?.toDate();
    return _FeedItem(
      id: doc.id,
      collection: 'tasks',
      title: d['title'] ?? 'Task',
      subtitle: d['ownerName'] != null ? 'Owner: ${d['ownerName']}' : '⚠️ Owner missing',
      childName: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: d['status'] ?? 'confirmed',
      dateTime: due ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.warmYellow,
      iconBg: AppColors.yellowLight,
      type: 'task',
      docRef: householdRef.collection('tasks').doc(doc.id),
      rawData: d,
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
      childName: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: d['status'] ?? 'confirmed',
      dateTime: due ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.payment_rounded,
      iconColor: AppColors.softBlue,
      iconBg: AppColors.blueLight,
      type: 'payment',
      docRef: householdRef.collection('payments').doc(doc.id),
      rawData: d,
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
      childName: d['affectedMemberName'],
      ownerName: d['ownerName'],
      status: 'notReady',
      dateTime: needed ?? (d['createdAt'] as Timestamp?)?.toDate(),
      icon: Icons.backpack_rounded,
      iconColor: AppColors.softGreen,
      iconBg: AppColors.greenLight,
      type: 'requiredItem',
      docRef: householdRef.collection('requiredItems').doc(doc.id),
      rawData: d,
    );
  }
}

// --- Date Header ---
class _DateHeader extends StatelessWidget {
  final DateTime? date;
  const _DateHeader({this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        _formatDate(date),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Pending';
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
  final String householdId;
  const _FeedCard({required this.item, required this.householdId});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => _openDetail(context),
      color: item.isPending ? AppColors.yellowLight : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title + type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: item.isPending ? AppColors.warmYellow : AppColors.textSecondary,
                              fontWeight: item.isPending ? FontWeight.w600 : null,
                            ),
                      ),
                  ],
                ),
              ),

              // Time
              if (item.dateTime != null && !item.isPending)
                Text(
                  '${item.dateTime!.hour.toString().padLeft(2, '0')}:${item.dateTime!.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),

          // Bottom row: child name + action
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (item.childName != null)
                CategoryChip(label: item.childName!, color: AppColors.primary),
              if (item.childName != null && item.ownerName != null)
                const SizedBox(width: 6),
              if (item.ownerName != null)
                CategoryChip(label: item.ownerName!, color: AppColors.softGreen),
              const Spacer(),
              if (item.isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warmYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warmYellow),
                  ),
                )
              else
                _ActionChip(item: item),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    if (item.isPending && item.extractedItem != null) {
      // Open Review Card for pending items
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewCardScreen(
            householdId: householdId,
            item: item.extractedItem!,
          ),
        ),
      );
    } else if (item.rawData != null) {
      // Open detail bottom sheet for committed items
      _showDetailSheet(context);
    }
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Type + child
              Row(
                children: [
                  CategoryChip(label: item.type, color: item.iconColor),
                  if (item.childName != null) ...[
                    const SizedBox(width: 8),
                    CategoryChip(label: item.childName!, color: AppColors.primary),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(item.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),

              if (item.subtitle != null)
                Text(item.subtitle!, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),

              const SizedBox(height: AppSpacing.xl),

              // Details from raw data
              if (item.rawData != null) ...[
                ..._buildDetailRows(ctx, item.rawData!),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Action button
              if (item.docRef != null && !item.isPending)
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(ctx),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailRows(BuildContext context, Map<String, dynamic> data) {
    final rows = <Widget>[];
    final keys = ['location', 'ownerName', 'affectedMemberName', 'amount', 'currency', 'paymentMethod', 'dueDate', 'startDateTime'];

    for (final key in keys) {
      if (data[key] != null) {
        String value;
        if (data[key] is Timestamp) {
          final dt = (data[key] as Timestamp).toDate();
          value = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          value = data[key].toString();
        }

        final label = switch (key) {
          'location' => 'Location',
          'ownerName' => 'Owner',
          'affectedMemberName' => 'Child',
          'amount' => 'Amount',
          'currency' => 'Currency',
          'paymentMethod' => 'Payment method',
          'dueDate' => 'Due date',
          'startDateTime' => 'Date & time',
          _ => key,
        };

        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ),
              Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ));
      }
    }
    return rows;
  }

  Widget _buildActionButton(BuildContext context) {
    final label = switch (item.collection) {
      'tasks' => 'Mark done',
      'payments' => 'Mark paid',
      'requiredItems' => 'Mark packed',
      _ => null,
    };

    if (label == null) return const SizedBox.shrink();

    return FilledButton(
      onPressed: () async {
        final update = switch (item.collection) {
          'tasks' => {'status': 'completed'},
          'payments' => {'status': 'paid'},
          'requiredItems' => {'packedStatus': 'ready'},
          _ => <String, dynamic>{},
        };
        await item.docRef!.update(update);
        if (context.mounted) Navigator.pop(context);
      },
      child: Text(label),
    );
  }
}

// --- Action Chip ---
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
        await item.docRef?.update(update);
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
              'Capture something to get started.\nItems will appear here as they\'re processed.',
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
