import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../capture/data/models/source_message_model.dart';
import '../../review/presentation/review_detail_screen.dart';

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

/// Unified feed item
class _FeedItem {
  final String id;
  final String title;
  final String? childName;
  final String? ownerName;
  final String? subtitle;
  final DateTime? dateTime;
  final String feedStatus; // pendingReview, confirmed, cancelled, completed, paid
  final String type; // source, event, task, payment, requiredItem
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? sourceMessageId;
  final DocumentReference? docRef;
  final Map<String, dynamic>? rawData;

  _FeedItem({
    required this.id,
    required this.title,
    this.childName,
    this.ownerName,
    this.subtitle,
    this.dateTime,
    required this.feedStatus,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.sourceMessageId,
    this.docRef,
    this.rawData,
  });

  bool get isPending => feedStatus == 'pendingReview' || feedStatus == 'processing';
  bool get isCancelled => feedStatus == 'cancelled';
  bool get isDone => feedStatus == 'completed' || feedStatus == 'paid';
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
                      Text(_greeting(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Your family feed', style: Theme.of(context).textTheme.headlineMedium),
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
                      // Group by day
                      final showDateHeader = index == 0 ||
                          !_isSameDay(items[index - 1].dateTime, item.dateTime);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            if (index > 0) const SizedBox(height: AppSpacing.xl),
                            _DateHeader(date: item.dateTime, isPending: item.isPending),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _FeedCard(item: item, householdId: householdId),
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
    // 1. Source messages that are pending/processing/completed (not yet approved)
    final sourcesStream = householdRef.collection('sourceMessages')
        .where('processingStatus', whereIn: ['pending', 'processing', 'completed'])
        .snapshots()
        .map((s) => s.docs.map((d) => _mapSource(d)).toList());

    // 2. Committed events
    final eventsStream = householdRef.collection('events')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapCommitted(d, 'event', Icons.event_rounded, AppColors.primary, AppColors.lavenderLight)).toList());

    // 3. Committed tasks
    final tasksStream = householdRef.collection('tasks')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapCommitted(d, 'task', Icons.check_circle_outline_rounded, AppColors.warmYellow, AppColors.yellowLight)).toList());

    // 4. Committed payments
    final paymentsStream = householdRef.collection('payments')
        .snapshots()
        .map((s) => s.docs.map((d) => _mapCommitted(d, 'payment', Icons.payment_rounded, AppColors.softBlue, AppColors.blueLight)).toList());

    return sourcesStream.asyncExpand((sources) {
      return eventsStream.asyncExpand((events) {
        return tasksStream.asyncExpand((tasks) {
          return paymentsStream.map((payments) {
            final all = [...sources, ...events, ...tasks, ...payments];
            // Pending first, then by date descending
            all.sort((a, b) {
              if (a.isPending && !b.isPending) return -1;
              if (!a.isPending && b.isPending) return 1;
              if (a.dateTime == null && b.dateTime == null) return 0;
              if (a.dateTime == null) return 1;
              if (b.dateTime == null) return -1;
              return b.dateTime!.compareTo(a.dateTime!); // newest first
            });
            return all;
          });
        });
      });
    });
  }

  _FeedItem _mapSource(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final received = (d['receivedAt'] as Timestamp?)?.toDate();
    final status = d['processingStatus'] ?? 'pending';

    return _FeedItem(
      id: doc.id,
      title: _truncate(d['originalContent'] ?? 'New capture', 80),
      childName: null,
      ownerName: null,
      subtitle: status == 'completed' ? 'Ready for review' : 'Processing...',
      dateTime: received,
      feedStatus: 'pendingReview',
      type: 'source',
      icon: _inputIcon(d['inputMethod']),
      iconColor: AppColors.warmYellow,
      iconBg: AppColors.yellowLight,
      sourceMessageId: doc.id,
      rawData: d,
    );
  }

  _FeedItem _mapCommitted(QueryDocumentSnapshot doc, String type, IconData icon, Color color, Color bg) {
    final d = doc.data() as Map<String, dynamic>;
    final status = d['status'] ?? 'confirmed';
    final created = (d['createdAt'] as Timestamp?)?.toDate();
    final startDt = (d['startDateTime'] as Timestamp?)?.toDate();
    final dueDt = (d['dueDate'] as Timestamp?)?.toDate();

    String? subtitle;
    if (d['location'] != null) subtitle = '📍 ${d['location']}';
    if (type == 'payment' && d['amount'] != null) {
      subtitle = '${d['currency'] ?? 'EUR'} ${d['amount']}';
    }

    return _FeedItem(
      id: doc.id,
      title: d['title'] ?? type,
      childName: d['affectedMemberName'],
      ownerName: d['ownerName'],
      subtitle: subtitle,
      dateTime: startDt ?? dueDt ?? created,
      feedStatus: status,
      type: type,
      icon: icon,
      iconColor: status == 'cancelled' ? AppColors.textMuted : color,
      iconBg: status == 'cancelled' ? AppColors.surfaceSoft : bg,
      docRef: doc.reference,
      rawData: d,
    );
  }

  IconData _inputIcon(String? method) => switch (method) {
        'freeText' => Icons.edit_note_rounded,
        'voice' => Icons.mic_rounded,
        'emailForwarding' => Icons.email_rounded,
        'imageUpload' => Icons.image_rounded,
        'mobileShare' => Icons.share_rounded,
        _ => Icons.inbox_rounded,
      };

  String _truncate(String s, int max) => s.length > max ? '${s.substring(0, max)}...' : s;
}

// --- Date Header ---
class _DateHeader extends StatelessWidget {
  final DateTime? date;
  final bool isPending;
  const _DateHeader({this.date, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPending ? AppColors.yellowLight : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        isPending ? 'Needs Review' : _formatDate(date),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isPending ? AppColors.warmYellow : null,
            ),
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
  final String householdId;
  const _FeedCard({required this.item, required this.householdId});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isCancelled ? 0.5 : (item.isDone ? 0.6 : 1.0),
      child: SoftCard(
        onTap: () => _onTap(context),
        color: item.isPending ? AppColors.yellowLight : null,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          decoration: item.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Subtitle
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: item.isPending ? AppColors.warmYellow : AppColors.textSecondary,
                            fontWeight: item.isPending ? FontWeight.w600 : null,
                          ),
                    ),
                  ],

                  // Child + Owner chips
                  if (item.childName != null || item.ownerName != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (item.childName != null)
                          CategoryChip(label: item.childName!, color: AppColors.primary),
                        if (item.ownerName != null)
                          CategoryChip(label: item.ownerName!, color: AppColors.softGreen),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Right side: status badge
            _StatusBadge(item: item),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (item.type == 'source') {
      // Open review detail for source messages
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(
            householdId: householdId,
            sourceMessageId: item.id,
          ),
        ),
      );
    } else if (item.rawData != null) {
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
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppSpacing.xl),
              Row(children: [
                CategoryChip(label: item.type, color: item.iconColor),
                if (item.childName != null) ...[const SizedBox(width: 8), CategoryChip(label: item.childName!, color: AppColors.primary)],
              ]),
              const SizedBox(height: AppSpacing.lg),
              Text(item.title, style: Theme.of(ctx).textTheme.titleLarge),
              if (item.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(item.subtitle!, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (item.rawData != null)
                ...item.rawData!.entries
                    .where((e) => e.value != null && !['householdId', 'sourceExtractedItemId', 'sourceMessageId'].contains(e.key))
                    .map((e) {
                  String val;
                  if (e.value is Timestamp) {
                    final dt = (e.value as Timestamp).toDate();
                    val = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  } else {
                    val = e.value.toString();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 120, child: Text(e.key, style: Theme.of(ctx).textTheme.bodySmall)),
                      Expanded(child: Text(val, style: Theme.of(ctx).textTheme.bodyMedium)),
                    ]),
                  );
                }),
              const SizedBox(height: AppSpacing.xl),
              if (item.docRef != null && item.feedStatus == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final update = switch (item.type) {
                        'task' => {'status': 'completed'},
                        'payment' => {'status': 'paid'},
                        _ => <String, dynamic>{},
                      };
                      if (update.isNotEmpty) await item.docRef!.update(update);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(switch (item.type) {
                      'task' => 'Mark done',
                      'payment' => 'Mark paid',
                      _ => 'Done',
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Status Badge ---
class _StatusBadge extends StatelessWidget {
  final _FeedItem item;
  const _StatusBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (item.feedStatus) {
      'pendingReview' => ('Review', AppColors.warmYellow),
      'processing' => ('Processing', AppColors.softBlue),
      'confirmed' => ('Active', AppColors.softGreen),
      'cancelled' => ('Cancelled', AppColors.softCoral),
      'completed' => ('Done', AppColors.softGreen),
      'paid' => ('Paid', AppColors.softGreen),
      _ => ('', AppColors.textMuted),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
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
            Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 40, color: AppColors.softGreen)),
            const SizedBox(height: 20),
            Text('Nothing in your feed yet.', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Capture something to get started.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
