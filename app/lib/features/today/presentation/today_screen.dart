import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/member_colors.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';
import '../../review/presentation/review_detail_screen.dart';
import 'item_detail_screen.dart';

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
          final displayName = FirebaseAuth.instance.currentUser?.displayName ?? household.name;
          return _FeedContent(householdId: household.id, userName: displayName);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Represents a single entry in the feed (either a source message or an item)
class FeedEntry {
  final String id;
  final String title;
  final String? childName;
  final String? ownerName;
  final String? location;
  final DateTime? dateTime;
  final String feedStatus; // analyzing, pendingReview, confirmed, completed, cancelled
  final String type; // source, event, task, deadline
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? sourceMessageId;
  final ItemModel? item;
  final bool isSource;
  final bool isRecurring;

  FeedEntry({
    required this.id,
    required this.title,
    this.childName,
    this.ownerName,
    this.location,
    this.dateTime,
    required this.feedStatus,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.sourceMessageId,
    this.item,
    this.isSource = false,
    this.isRecurring = false,
  });

  bool get isPending =>
      feedStatus == 'analyzing' || feedStatus == 'pendingReview' || feedStatus == 'failed' || feedStatus == 'noAction';
  bool get isCancelled => feedStatus == 'cancelled';
  bool get isDone => feedStatus == 'completed';

  /// Returns true if dateTime has a non-midnight time component
  bool get hasTime =>
      dateTime != null && (dateTime!.hour != 0 || dateTime!.minute != 0);
}

class _FeedContent extends StatelessWidget {
  final String householdId;
  final String userName;
  const _FeedContent({required this.householdId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final householdRef = db.collection('households').doc(householdId);

    // Load member colors map (name → color hex)
    return StreamBuilder<Map<String, String>>(
      stream: householdRef.collection('members').snapshots().map((snap) {
        final map = <String, String>{};
        for (final doc in snap.docs) {
          final data = doc.data();
          final name = data['name'] as String?;
          final color = data['color'] as String?;
          if (name != null && color != null) {
            map[name.toLowerCase()] = color;
          }
        }
        return map;
      }),
      builder: (context, membersSnap) {
        final memberColors = membersSnap.data ?? {};

        return StreamBuilder<List<FeedEntry>>(
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
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_greeting()}, $userName',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text('Your family feed',
                                    style: Theme.of(context).textTheme.headlineMedium),
                              ],
                            ),
                          ),
                          _WeatherWidget(householdId: householdId),
                        ],
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
                      final entry = items[index];
                      // Group by day
                      final showDateHeader = index == 0 ||
                          !_isSameDay(
                              items[index - 1].dateTime, entry.dateTime) ||
                          items[index - 1].isPending != entry.isPending;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            if (index > 0)
                              const SizedBox(height: AppSpacing.xl),
                            _DateHeader(
                                date: entry.dateTime,
                                isPending: entry.isPending),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _buildSwipeable(context, entry, householdId, memberColors),
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
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildSwipeable(BuildContext context, FeedEntry entry, String householdId, Map<String, String> memberColors) {
    // Allow swipe on confirmed and cancelled items (not pending, not source)
    final canSwipe = !entry.isSource &&
        !entry.isPending &&
        entry.item != null;

    if (!canSwipe) {
      return _FeedCard(entry: entry, householdId: householdId, memberColors: memberColors);
    }

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hide', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.visibility_off_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
      onDismissed: (_) {
        final itemId = entry.item!.id;
        final previousStatus = entry.feedStatus;
        FirebaseFirestore.instance
            .collection('households')
            .doc(householdId)
            .collection('items')
            .doc(itemId)
            .update({'status': 'hidden', 'updatedAt': Timestamp.now()});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.title} hidden'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('households')
                    .doc(householdId)
                    .collection('items')
                    .doc(itemId)
                    .update({'status': previousStatus, 'updatedAt': Timestamp.now()});
              },
            ),
          ),
        );
      },
      child: _FeedCard(entry: entry, householdId: householdId, memberColors: memberColors),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Stream<List<FeedEntry>> _buildFeedStream(DocumentReference householdRef) {
    // Stream 1: Source messages that are still being processed (analyzing state only)
    // Once AI completes, the items themselves appear with pendingReview status
    final sourcesStream = householdRef
        .collection('sourceMessages')
        .orderBy('receivedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs
            .where((d) {
              final data = d.data();
              final status = data['processingStatus'] as String?;
              // Show pending/processing (analyzing) + failed/noAction (so user sees the result)
              // completed sources are represented by their items in the items stream
              return status == 'pending' || status == 'processing' || status == 'failed' || status == 'noAction';
            })
            .map((d) => _mapSource(d))
            .toList());

    // Stream 2: All items from items/ collection
    // We fetch all and filter client-side to avoid composite index requirements
    final itemsStream = householdRef
        .collection('items')
        .snapshots()
        .map((snapshot) {
      final entries = <FeedEntry>[];
      for (final doc in snapshot.docs) {
        try {
          final item = ItemModel.fromFirestore(doc);
          // Hide completed and hidden items from feed (cancelled items stay visible)
          if (item.status == ItemStatus.completed || item.status == ItemStatus.hidden) continue;
          // Expand recurring items
          if (item.recurrence != null && item.status == ItemStatus.confirmed) {
            entries.addAll(_expandRecurring(item));
          } else {
            entries.add(_mapItem(item));
          }
        } catch (_) {}
      }
      return entries;
    });

    // Combine both streams using combineLatest pattern
    return _combineLatest(sourcesStream, itemsStream);
  }

  /// Combines two streams, emitting latest combined value whenever either emits
  Stream<List<FeedEntry>> _combineLatest(
    Stream<List<FeedEntry>> sourcesStream,
    Stream<List<FeedEntry>> itemsStream,
  ) {
    final controller = StreamController<List<FeedEntry>>();
    List<FeedEntry> latestSources = [];
    List<FeedEntry> latestItems = [];
    bool hasSources = false;
    bool hasItems = false;

    void emit() {
      if (!hasSources && !hasItems) return;
      final all = [...latestSources, ...latestItems];
      all.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        if (a.dateTime == null && b.dateTime == null) return 0;
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;
        return a.dateTime!.compareTo(b.dateTime!);
      });
      controller.add(all);
    }

    final sub1 = sourcesStream.listen(
      (data) {
        latestSources = data;
        hasSources = true;
        emit();
      },
      onError: (e) => controller.addError(e),
    );
    final sub2 = itemsStream.listen(
      (data) {
        latestItems = data;
        hasItems = true;
        emit();
      },
      onError: (e) => controller.addError(e),
    );

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  FeedEntry _mapSource(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final received = (d['receivedAt'] as Timestamp?)?.toDate();
    final content = d['originalContent'] as String? ?? 'New capture';
    final status = d['processingStatus'] as String? ?? 'pending';

    final isAnalyzing = status == 'pending' || status == 'processing';
    final isFailed = status == 'failed';
    final isNoAction = status == 'noAction';

    String subtitle;
    Color iconColor;
    Color iconBg;
    if (isFailed) {
      subtitle = 'Failed — tap to retry';
      iconColor = AppColors.softCoral;
      iconBg = AppColors.coralLight;
    } else if (isNoAction) {
      subtitle = 'No action found';
      iconColor = AppColors.textMuted;
      iconBg = AppColors.surfaceSoft;
    } else {
      subtitle = 'Analyzing...';
      iconColor = AppColors.softBlue;
      iconBg = AppColors.blueLight;
    }

    return FeedEntry(
      id: doc.id,
      title: _truncate(content, 80),
      location: subtitle,
      dateTime: received,
      feedStatus: isAnalyzing ? 'analyzing' : (isFailed ? 'failed' : 'noAction'),
      type: 'source',
      icon: _inputIcon(d['inputMethod']),
      iconColor: iconColor,
      iconBg: iconBg,
      sourceMessageId: doc.id,
      isSource: true,
    );
  }

  FeedEntry _mapItem(ItemModel item) {
    final typeInfo = _typeVisuals(item.type);

    return FeedEntry(
      id: item.id,
      title: item.title,
      childName: item.childName,
      ownerName: item.ownerName,
      location: item.location,
      dateTime: item.date,
      feedStatus: item.status.name,
      type: item.type.name,
      icon: typeInfo.$1,
      iconColor: item.status == ItemStatus.cancelled
          ? AppColors.textMuted
          : typeInfo.$2,
      iconBg: item.status == ItemStatus.cancelled
          ? AppColors.surfaceSoft
          : typeInfo.$3,
      sourceMessageId: item.sourceMessageId,
      item: item,
      isRecurring: item.recurrence != null,
    );
  }

  /// Expand a recurring item into multiple feed entries (next 4 weeks)
  List<FeedEntry> _expandRecurring(ItemModel item) {
    final rule = item.recurrence!;
    final entries = <FeedEntry>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hour = item.date?.hour ?? 0;
    final minute = item.date?.minute ?? 0;

    // Parse frequency and day
    int? targetWeekday;
    if (rule.frequency == 'weekly' && rule.dayOfWeek != null) {
      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      final idx = dayNames.indexOf(rule.dayOfWeek!.toLowerCase());
      if (idx >= 0) targetWeekday = idx + 1;
    }

    if (targetWeekday == null) {
      // Fallback: just show the item as-is
      return [_mapItem(item)];
    }

    // Check end date
    DateTime? endDate;
    if (rule.endDate != null) {
      endDate = DateTime.tryParse(rule.endDate!);
    }

    // Build set of cancelled dates from exceptions
    final cancelledDates = <String>{};
    for (final ex in item.exceptions) {
      if (ex.status == 'cancelled') {
        cancelledDates.add(ex.date);
      }
    }

    for (int week = 0; week < 4; week++) {
      var daysUntil = targetWeekday - today.weekday;
      if (daysUntil < 0) daysUntil += 7;
      final occDate = today.add(Duration(days: daysUntil + (week * 7)));
      final occDateTime =
          DateTime(occDate.year, occDate.month, occDate.day, hour, minute);

      // Check if past end date
      if (endDate != null && occDate.isAfter(endDate)) break;

      // Check if cancelled
      final dateStr =
          '${occDate.year}-${occDate.month.toString().padLeft(2, '0')}-${occDate.day.toString().padLeft(2, '0')}';
      if (cancelledDates.contains(dateStr)) continue;

      final typeInfo = _typeVisuals(item.type);
      entries.add(FeedEntry(
        id: '${item.id}_w$week',
        title: item.title,
        location: item.location,
        childName: item.childName,
        ownerName: item.ownerName,
        dateTime: occDateTime,
        feedStatus: 'confirmed',
        type: item.type.name,
        icon: Icons.repeat_rounded,
        iconColor: typeInfo.$2,
        iconBg: typeInfo.$3,
        item: item,
        isRecurring: true,
      ));
    }

    return entries;
  }

  (IconData, Color, Color) _typeVisuals(ItemType type) => switch (type) {
        ItemType.event => (
            Icons.event_rounded,
            AppColors.primary,
            AppColors.lavenderLight
          ),
        ItemType.task => (
            Icons.check_circle_outline_rounded,
            AppColors.warmYellow,
            AppColors.yellowLight
          ),
        ItemType.deadline => (
            Icons.schedule_rounded,
            AppColors.softCoral,
            AppColors.coralLight
          ),
      };

  IconData _inputIcon(String? method) => switch (method) {
        'freeText' => Icons.edit_note_rounded,
        'voice' => Icons.mic_rounded,
        'emailForwarding' => Icons.email_rounded,
        'imageUpload' => Icons.image_rounded,
        'mobileShare' => Icons.share_rounded,
        _ => Icons.inbox_rounded,
      };

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;
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
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

// --- Feed Card ---
class _FeedCard extends StatelessWidget {
  final FeedEntry entry;
  final String householdId;
  final Map<String, String> memberColors;
  const _FeedCard({required this.entry, required this.householdId, required this.memberColors});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: entry.isCancelled ? 0.5 : (entry.isDone ? 0.6 : 1.0),
      child: SoftCard(
        onTap: () => _onTap(context),
        color: entry.isPending ? AppColors.yellowLight : null,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: entry.iconBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(entry.icon, color: entry.iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          decoration: entry.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Location + time row
                  if (entry.location != null || entry.hasTime || entry.isSource) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry.isSource) ...[
                          Text(
                            'Analyzing...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.softBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ] else ...[
                          if (entry.location != null) ...[
                            Icon(Icons.place_rounded,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                entry.location!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (entry.location != null && entry.hasTime)
                            Text('  •  ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textMuted)),
                          if (entry.hasTime)
                            Text(
                              _formatTime(entry.dateTime!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          if (entry.isRecurring) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.repeat_rounded,
                                size: 13, color: AppColors.textMuted),
                          ],
                        ],
                      ],
                    ),
                  ],

                  // Child + Owner chips
                  if (entry.childName != null || entry.ownerName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (entry.childName != null) ...[
                          _ChildChip(
                            name: entry.childName!,
                            colorHex: memberColors[entry.childName!.toLowerCase()],
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (entry.ownerName != null)
                          CategoryChip(
                              label: entry.ownerName!,
                              color: AppColors.softGreen),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status badge
            const SizedBox(width: 8),
            _StatusBadge(entry: entry),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _onTap(BuildContext context) {
    if (entry.isSource) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(
            householdId: householdId,
            sourceMessageId: entry.id,
          ),
        ),
      );
    } else if (entry.feedStatus == 'pendingReview') {
      if (entry.sourceMessageId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewDetailScreen(
              householdId: householdId,
              sourceMessageId: entry.sourceMessageId!,
            ),
          ),
        );
      } else if (entry.item != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              householdId: householdId,
              item: entry.item!,
            ),
          ),
        );
      }
    } else {
      if (entry.item != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              householdId: householdId,
              item: entry.item!,
            ),
          ),
        );
      }
    }
  }
}

/// Child chip with initial avatar using member's assigned color
class _ChildChip extends StatelessWidget {
  final String name;
  final String? colorHex;
  const _ChildChip({required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = MemberColors.fromHex(colorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color,
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 4),
          Text(name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

// --- Status Badge ---
class _StatusBadge extends StatelessWidget {
  final FeedEntry entry;
  const _StatusBadge({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (entry.feedStatus) {
      'analyzing' => ('Analyzing', AppColors.softBlue),
      'pendingReview' => ('Review', AppColors.warmYellow),
      'confirmed' => ('Active', AppColors.softGreen),
      'cancelled' => ('Cancelled', AppColors.softCoral),
      'completed' => ('Done', AppColors.softGreen),
      'failed' => ('Failed', AppColors.softCoral),
      'noAction' => ('No action', AppColors.textMuted),
      _ => ('', AppColors.textMuted),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
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
                    color: AppColors.greenLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    size: 40, color: AppColors.softGreen)),
            const SizedBox(height: 20),
            Text('Nothing in your feed yet.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Capture something to get started.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// --- Weather Widget ---
class _WeatherWidget extends StatefulWidget {
  final String householdId;
  const _WeatherWidget({required this.householdId});

  @override
  State<_WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<_WeatherWidget> {
  WeatherData? _weather;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      // Get city from household document
      final doc = await FirebaseFirestore.instance
          .collection('households')
          .doc(widget.householdId)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final city = data['city'] as String?;

      WeatherData? weather;

      if (city != null && city.isNotEmpty) {
        weather = await WeatherService.fetchByCity(city);
      } else {
        // Fallback: use device GPS location
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            if (mounted) setState(() => _loaded = true);
            return;
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            ).timeout(const Duration(seconds: 10));
            weather = await WeatherService.fetchByCoords(
                position.latitude, position.longitude);
          }
        } catch (_) {}
      }

      if (mounted) setState(() { _weather = weather; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _weather == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_weather!.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            '${_weather!.temperature.round()}°',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
