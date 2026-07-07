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
import 'feed_item_detail_screen.dart';

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
    // 1. Source messages not yet fully approved/dismissed
    final sourcesStream = householdRef.collection('sourceMessages')
        .orderBy('receivedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs
            .where((d) {
              final status = (d.data())['processingStatus'] as String?;
              // Only show pending, processing, completed (not approved/dismissed/failed/noActionFound)
              return status == 'pending' || status == 'processing' || status == 'completed';
            })
            .map((d) => _mapSource(d))
            .toList());

    // 2. Committed events (expand recurring)
    final eventsStream = householdRef.collection('events')
        .snapshots()
        .map((s) {
          final items = <_FeedItem>[];
          for (final doc in s.docs) {
            final d = doc.data();
            final recurrence = d['recurrence'] as String?;
            if (recurrence != null && recurrence.isNotEmpty) {
              items.addAll(_expandRecurring(doc));
            } else {
              items.add(_mapCommitted(doc, 'event', Icons.event_rounded, AppColors.primary, AppColors.lavenderLight));
            }
          }
          return items;
        });

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
            // Sort: pending items first, then chronologically (today → future)
            all.sort((a, b) {
              // Pending/analyzing always on top
              if (a.isPending && !b.isPending) return -1;
              if (!a.isPending && b.isPending) return 1;
              // Then by date ascending (today first, then tomorrow, etc.)
              if (a.dateTime == null && b.dateTime == null) return 0;
              if (a.dateTime == null) return 1;
              if (b.dateTime == null) return -1;
              return a.dateTime!.compareTo(b.dateTime!);
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
    final isAnalyzing = status == 'pending' || status == 'processing';

    return _FeedItem(
      id: doc.id,
      title: _truncate(d['originalContent'] ?? 'New capture', 80),
      childName: null,
      ownerName: null,
      subtitle: isAnalyzing ? 'Analyzing...' : 'Needs review',
      dateTime: received,
      feedStatus: isAnalyzing ? 'processing' : 'pendingReview',
      type: 'source',
      icon: _inputIcon(d['inputMethod']),
      iconColor: isAnalyzing ? AppColors.softBlue : AppColors.warmYellow,
      iconBg: isAnalyzing ? AppColors.blueLight : AppColors.yellowLight,
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

  /// Expand a recurring event into multiple feed items (one per week for 4 weeks)
  List<_FeedItem> _expandRecurring(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final recurrence = d['recurrence'] as String? ?? '';
    final baseTime = (d['startDateTime'] as Timestamp?)?.toDate();
    final status = d['status'] ?? 'confirmed';

    // Parse which weekday from recurrence string
    final lowerRec = recurrence.toLowerCase();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    int? targetWeekday;
    for (int i = 0; i < dayNames.length; i++) {
      if (lowerRec.contains(dayNames[i])) {
        targetWeekday = i + 1; // 1=Mon, 7=Sun
        break;
      }
    }

    if (targetWeekday == null) {
      return [_mapCommitted(doc, 'event', Icons.event_rounded, AppColors.primary, AppColors.lavenderLight)];
    }

    final items = <_FeedItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hour = baseTime?.hour ?? 0;
    final minute = baseTime?.minute ?? 0;

    for (int week = 0; week < 4; week++) {
      var daysUntil = targetWeekday - today.weekday;
      if (daysUntil < 0) daysUntil += 7;
      final occDate = today.add(Duration(days: daysUntil + (week * 7)));
      final occDateTime = DateTime(occDate.year, occDate.month, occDate.day, hour, minute);

      items.add(_FeedItem(
        id: '${doc.id}_w$week',
        title: d['title'] ?? 'Event',
        subtitle: d['location'] != null ? '📍 ${d['location']}' : null,
        childName: d['affectedMemberName'],
        ownerName: d['ownerName'],
        dateTime: occDateTime,
        feedStatus: status,
        type: 'event',
        icon: Icons.repeat_rounded,
        iconColor: AppColors.primary,
        iconBg: AppColors.lavenderLight,
        docRef: doc.reference,
        rawData: d,
      ));
    }

    return items;
  }

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
    } else {
      // Open full screen detail for committed items
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeedItemDetailScreen(
            title: item.title,
            type: item.type,
            childName: item.childName,
            ownerName: item.ownerName,
            subtitle: item.subtitle,
            feedStatus: item.feedStatus,
            icon: item.icon,
            iconColor: item.iconColor,
            iconBg: item.iconBg,
            docRef: item.docRef,
            rawData: item.rawData,
          ),
        ),
      );
    }
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
