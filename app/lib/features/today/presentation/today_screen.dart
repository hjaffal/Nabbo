import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/member_colors.dart';
import '../../../core/theme/category_icons.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/widgets/nabbo_widgets.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../items/data/models/item_model.dart';
import '../../review/presentation/review_detail_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../activity/presentation/activity_feed_view.dart';
import 'widgets/morning_brief_card.dart';
import 'item_detail_screen.dart';
import '../../child_week/presentation/child_week_screen.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
});

/// Holds color and photo info for a family member
class _MemberInfo {
  final String? color;
  final String? photoUrl;
  const _MemberInfo({this.color, this.photoUrl});
}

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
          AppStrings.currentLang = household.language;
          return _FeedContent(householdId: household.id, userName: displayName, lang: household.language);
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
  final bool autoApproved;
  final DateTime? occurrenceDate; // specific date for recurring occurrences

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
    this.autoApproved = false,
    this.occurrenceDate,
  });

  bool get isPending =>
      feedStatus == 'analyzing' || feedStatus == 'pendingReview' || feedStatus == 'failed' || feedStatus == 'noAction';
  bool get isCancelled => feedStatus == 'cancelled';
  bool get isDone => feedStatus == 'completed';

  /// Returns true if dateTime has a non-midnight time component
  bool get hasTime =>
      dateTime != null && (dateTime!.hour != 0 || dateTime!.minute != 0);
}

class _FeedContent extends StatefulWidget {
  final String householdId;
  final String userName;
  final String lang;
  const _FeedContent({required this.householdId, required this.userName, required this.lang});

  @override
  State<_FeedContent> createState() => _FeedContentState();
}

class _FeedContentState extends State<_FeedContent> {
  int _selectedTab = 0; // 0 = Feed, 1 = Activity
  int _unreadCount = 0;
  DateTime? _lastViewedTimestamp;
  StreamSubscription? _activityCountSub;

  @override
  void initState() {
    super.initState();
    _loadLastViewed();
  }

  @override
  void dispose() {
    _activityCountSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('activity_last_viewed');
    if (millis != null) {
      _lastViewedTimestamp = DateTime.fromMillisecondsSinceEpoch(millis);
    }
    _startUnreadCounter();
  }

  void _startUnreadCounter() {
    final db = FirebaseFirestore.instance;
    final eventsRef = db
        .collection('households')
        .doc(widget.householdId)
        .collection('activityEvents')
        .orderBy('createdAt', descending: true)
        .limit(100);

    _activityCountSub = eventsRef.snapshots().listen((snapshot) {
      if (!mounted) return;
      final lastViewed = _lastViewedTimestamp ?? DateTime(2000);
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts != null && ts.toDate().isAfter(lastViewed)) {
          count++;
        }
      }
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });
  }

  Future<void> _markActivityViewed() async {
    final now = DateTime.now();
    setState(() {
      _lastViewedTimestamp = now;
      _unreadCount = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activity_last_viewed', now.millisecondsSinceEpoch);
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    if (index == 1) {
      _markActivityViewed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final householdRef = db.collection('households').doc(widget.householdId);

    return Column(
      children: [
        // Header
        SafeArea(
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
                          Text('${_greeting()}, ${widget.userName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(AppStrings.get('your_family_feed', widget.lang),
                              style: Theme.of(context).textTheme.headlineMedium),
                        ],
                      ),
                    ),
                    _NotificationBell(householdId: widget.householdId),
                    const SizedBox(width: 12),
                    _WeatherWidget(householdId: widget.householdId),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Tab toggle
                _FeedActivityToggle(
                  selectedIndex: _selectedTab,
                  unreadCount: _unreadCount,
                  onChanged: _onTabChanged,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),

        // Body — IndexedStack preserves scroll positions
        Expanded(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              // Feed tab
              _FeedList(
                householdId: widget.householdId,
                householdRef: householdRef,
                lang: widget.lang,
              ),
              // Activity tab
              ActivityFeedView(householdId: widget.householdId),
            ],
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.get('good_morning', widget.lang);
    if (hour < 17) return AppStrings.get('good_afternoon', widget.lang);
    return AppStrings.get('good_evening', widget.lang);
  }
}

/// Toggle pills for Feed / Activity
class _FeedActivityToggle extends StatelessWidget {
  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onChanged;

  const _FeedActivityToggle({
    required this.selectedIndex,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TogglePill(
          label: 'Feed',
          isSelected: selectedIndex == 0,
          onTap: () => onChanged(0),
        ),
        const SizedBox(width: AppSpacing.sm),
        _TogglePill(
          label: 'Activity',
          isSelected: selectedIndex == 1,
          onTap: () => onChanged(1),
          badgeCount: selectedIndex == 0 ? unreadCount : 0,
        ),
      ],
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _TogglePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Extracted feed list (original feed content)
class _FeedList extends StatefulWidget {
  final String householdId;
  final DocumentReference householdRef;
  final String lang;
  const _FeedList({required this.householdId, required this.householdRef, required this.lang});

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  // Key to force stream rebuild on refresh
  Key _streamKey = UniqueKey();

  Future<void> _onRefresh() async {
    setState(() => _streamKey = UniqueKey());
    // Small delay to let the stream reconnect
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String get householdId => widget.householdId;
  DocumentReference get householdRef => widget.householdRef;
  String get lang => widget.lang;

  @override
  Widget build(BuildContext context) {
    // Load member info map (name → { color, photoUrl })
    return StreamBuilder<Map<String, _MemberInfo>>(
      stream: householdRef.collection('members').snapshots().map((snap) {
        final map = <String, _MemberInfo>{};
        for (final doc in snap.docs) {
          final data = doc.data();
          final name = data['name'] as String?;
          final color = data['color'] as String?;
          final photoUrl = data['photoUrl'] as String?;
          if (name != null) {
            map[name.toLowerCase()] = _MemberInfo(color: color, photoUrl: photoUrl);
          }
        }
        return map;
      }),
      builder: (context, membersSnap) {
        final memberInfo = membersSnap.data ?? {};

        return StreamBuilder<List<FeedEntry>>(
          key: _streamKey,
          stream: _buildFeedStream(householdRef),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                  child: MorningBriefCard(householdId: householdId),
                ),
              ),
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

                      return AnimatedListItem(
                        index: index,
                        child: Column(
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
                              child: _buildSwipeable(context, entry, householdId, memberInfo),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwipeable(BuildContext context, FeedEntry entry, String householdId, Map<String, _MemberInfo> memberInfo) {
    // Allow swipe on confirmed, completed, and cancelled items (not pending, not source)
    final canSwipe = !entry.isSource &&
        !entry.isPending &&
        (entry.feedStatus == 'confirmed' || entry.feedStatus == 'completed' || entry.feedStatus == 'cancelled') &&
        entry.item != null;

    if (!canSwipe) {
      return _FeedCard(entry: entry, householdId: householdId, memberInfo: memberInfo);
    }

    final itemId = entry.item!.id;

    return Dismissible(
      key: Key(entry.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → show options (hide / cancel)
          final result = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.visibility_off_rounded, color: AppColors.textMuted),
                    title: const Text('Hide'),
                    subtitle: const Text('Remove from feed'),
                    onTap: () => Navigator.pop(ctx, 'hide'),
                  ),
                  ListTile(
                    leading: Icon(Icons.cancel_rounded, color: AppColors.softCoral),
                    title: const Text('Cancel'),
                    subtitle: Text(entry.isRecurring ? 'Cancel this occurrence' : 'Cancel this item'),
                    onTap: () => Navigator.pop(ctx, 'cancel'),
                  ),
                  if (entry.isRecurring)
                    ListTile(
                      leading: Icon(Icons.block_rounded, color: AppColors.softCoral),
                      title: const Text('Cancel entire series'),
                      onTap: () => Navigator.pop(ctx, 'cancelAll'),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );

          if (result == 'hide') {
            if (entry.isRecurring && entry.occurrenceDate != null) {
              // Hide single occurrence via exception
              final dateStr = '${entry.occurrenceDate!.year}-${entry.occurrenceDate!.month.toString().padLeft(2, '0')}-${entry.occurrenceDate!.day.toString().padLeft(2, '0')}';
              FirebaseFirestore.instance.collection('households').doc(householdId).collection('items').doc(itemId).update({
                'exceptions': FieldValue.arrayUnion([{'date': dateStr, 'status': 'hidden'}]),
                'updatedAt': Timestamp.now(),
              });
            } else {
              _setStatus(householdId, itemId, 'hidden', entry.feedStatus);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${entry.title} hidden'),
              ));
            }
          } else if (result == 'cancel') {
            if (entry.isRecurring && entry.occurrenceDate != null) {
              final dateStr = '${entry.occurrenceDate!.year}-${entry.occurrenceDate!.month.toString().padLeft(2, '0')}-${entry.occurrenceDate!.day.toString().padLeft(2, '0')}';
              FirebaseFirestore.instance.collection('households').doc(householdId).collection('items').doc(itemId).update({
                'exceptions': FieldValue.arrayUnion([{'date': dateStr, 'status': 'cancelled'}]),
                'updatedAt': Timestamp.now(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${entry.title} cancelled for this date')));
              }
            } else {
              _setStatus(householdId, itemId, 'cancelled', entry.feedStatus);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${entry.title} cancelled'),
                  action: SnackBarAction(label: 'Undo', onPressed: () => _setStatus(householdId, itemId, entry.feedStatus, null)),
                ));
              }
            }
          } else if (result == 'cancelAll') {
            _setStatus(householdId, itemId, 'cancelled', entry.feedStatus);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${entry.title} series cancelled')));
            }
          }
          return false; // Don't dismiss — we handle state changes manually
        } else {
          // Swipe left → mark complete + hide
          if (entry.isRecurring && entry.occurrenceDate != null) {
            final dateStr = '${entry.occurrenceDate!.year}-${entry.occurrenceDate!.month.toString().padLeft(2, '0')}-${entry.occurrenceDate!.day.toString().padLeft(2, '0')}';
            FirebaseFirestore.instance.collection('households').doc(householdId).collection('items').doc(itemId).update({
              'exceptions': FieldValue.arrayUnion([{'date': dateStr, 'status': 'hidden'}]),
              'updatedAt': Timestamp.now(),
            });
          } else {
            _setStatus(householdId, itemId, 'hidden', entry.feedStatus);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${entry.title} done')),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.softGreen,
              action: SnackBarAction(label: 'Undo', textColor: Colors.white, onPressed: () {
                if (entry.isRecurring && entry.occurrenceDate != null) {
                  final dateStr = '${entry.occurrenceDate!.year}-${entry.occurrenceDate!.month.toString().padLeft(2, '0')}-${entry.occurrenceDate!.day.toString().padLeft(2, '0')}';
                  FirebaseFirestore.instance.collection('households').doc(householdId).collection('items').doc(itemId).update({
                    'exceptions': FieldValue.arrayRemove([{'date': dateStr, 'status': 'hidden'}]),
                    'updatedAt': Timestamp.now(),
                  });
                } else {
                  _setStatus(householdId, itemId, entry.feedStatus, null);
                }
              }),
            ));
          }
          return false; // Don't remove from tree — stream handles UI updates
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 22),
            const SizedBox(width: 6),
            Text('Options', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.softGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Done', style: TextStyle(color: AppColors.softGreen, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 22),
          ],
        ),
      ),
      child: _FeedCard(entry: entry, householdId: householdId, memberInfo: memberInfo),
    );
  }

  void _setStatus(String householdId, String itemId, String status, String? _) {
    final db = FirebaseFirestore.instance;
    db.collection('households')
        .doc(householdId)
        .collection('items')
        .doc(itemId)
        .update({'status': status, 'updatedAt': Timestamp.now()});

    // Record activity event for completion (hidden = done)
    if (status == 'hidden' || status == 'cancelled') {
      db.collection('households').doc(householdId).collection('items').doc(itemId).get().then((doc) {
        if (!doc.exists) return;
        final data = doc.data()!;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

        // Get actor name from members
        db.collection('households').doc(householdId).collection('members')
            .where('role', isEqualTo: 'primaryParent').limit(1).get().then((members) {
          final actorName = members.docs.isNotEmpty
              ? (members.docs.first.data()['name'] as String? ?? 'Parent')
              : (FirebaseAuth.instance.currentUser?.displayName ?? 'Parent');

          db.collection('households').doc(householdId).collection('activityEvents').add({
            'householdId': householdId,
            'activityType': status == 'hidden' ? 'completion' : 'cancellation',
            'actorId': userId,
            'actorName': actorName,
            'title': data['title'] ?? 'Untitled',
            'subtitle': null,
            'childId': data['childId'],
            'childName': data['childName'],
            'relatedItemId': itemId,
            'sourceMessageId': null,
            'metadata': {},
            'createdAt': Timestamp.now(),
          });
        });
      }).catchError((_) {});
    }
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
          // Only hide 'hidden' items from feed
          if (item.status == ItemStatus.hidden) continue;
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
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      all.sort((a, b) {
        // Pending/analyzing always first
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;

        // Then: today+future before past
        final aIsPast = a.dateTime != null && a.dateTime!.isBefore(todayStart);
        final bIsPast = b.dateTime != null && b.dateTime!.isBefore(todayStart);
        if (!aIsPast && bIsPast) return -1;
        if (aIsPast && !bIsPast) return 1;

        // Within same group: sort by date
        if (a.dateTime == null && b.dateTime == null) return 0;
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;

        // Future items: ascending (today first, then tomorrow, etc.)
        // Past items: descending (yesterday first, then day before, etc.)
        if (aIsPast && bIsPast) {
          return b.dateTime!.compareTo(a.dateTime!); // most recent past first
        }
        return a.dateTime!.compareTo(b.dateTime!); // earliest future first
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
    final icon = CategoryIcons.getIcon(item.category, item.type);
    final color = CategoryIcons.getColor(item.category, item.type);
    final bgColor = CategoryIcons.getBackgroundColor(item.category, item.type);

    return FeedEntry(
      id: item.id,
      title: item.title,
      childName: item.childName,
      ownerName: item.ownerName,
      location: item.location,
      dateTime: item.date,
      feedStatus: item.status.name,
      type: item.type.name,
      icon: icon,
      iconColor: item.status == ItemStatus.cancelled
          ? AppColors.textMuted
          : color,
      iconBg: item.status == ItemStatus.cancelled
          ? AppColors.surfaceSoft
          : bgColor,
      sourceMessageId: item.sourceMessageId,
      item: item,
      isRecurring: item.recurrence != null,
      autoApproved: item.autoApproved,
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

    // Parse day of week if provided
    int? targetWeekday;
    if (rule.dayOfWeek != null) {
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
      if (idx >= 0) targetWeekday = idx + 1; // 1=Mon, 7=Sun
    }

    // Check end date
    DateTime? endDate;
    if (rule.endDate != null) {
      endDate = DateTime.tryParse(rule.endDate!);
    }

    // Build set of cancelled and hidden dates from exceptions
    final cancelledDates = <String>{};
    final hiddenDates = <String>{};
    for (final ex in item.exceptions) {
      if (ex.status == 'cancelled') {
        cancelledDates.add(ex.date);
      } else if (ex.status == 'hidden') {
        hiddenDates.add(ex.date);
      }
    }

    // Generate occurrences based on frequency
    final maxOccurrences = endDate != null ? 52 : 4;
    List<DateTime> occurrenceDates = [];

    if (rule.frequency == 'daily') {
      for (int i = 0; i < maxOccurrences; i++) {
        final occDate = today.add(Duration(days: i));
        if (endDate != null && occDate.isAfter(endDate)) break;
        occurrenceDates.add(occDate);
      }
    } else if (rule.frequency == 'weekly' && targetWeekday != null) {
      for (int week = 0; week < maxOccurrences; week++) {
        var daysUntil = targetWeekday - today.weekday;
        if (daysUntil < 0) daysUntil += 7;
        final occDate = today.add(Duration(days: daysUntil + (week * 7)));
        if (endDate != null && occDate.isAfter(endDate)) break;
        occurrenceDates.add(occDate);
      }
    } else if (rule.frequency == 'biweekly' && targetWeekday != null) {
      for (int week = 0; week < maxOccurrences; week++) {
        var daysUntil = targetWeekday - today.weekday;
        if (daysUntil < 0) daysUntil += 7;
        final occDate = today.add(Duration(days: daysUntil + (week * 14)));
        if (endDate != null && occDate.isAfter(endDate)) break;
        occurrenceDates.add(occDate);
      }
    } else if (rule.frequency == 'monthly') {
      // Monthly: find the target weekday in each month (e.g., first Monday)
      for (int month = 0; month < maxOccurrences; month++) {
        final targetMonth = DateTime(today.year, today.month + month, 1);
        DateTime? occDate;

        if (targetWeekday != null) {
          // Find first occurrence of targetWeekday in this month
          var day = targetMonth;
          while (day.weekday != targetWeekday) {
            day = day.add(const Duration(days: 1));
          }
          occDate = day;
        } else {
          // Monthly on a specific day (use the item's date day-of-month)
          final dayOfMonth = item.date?.day ?? 1;
          final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
          occDate = DateTime(targetMonth.year, targetMonth.month, dayOfMonth.clamp(1, daysInMonth));
        }

        if (occDate.isBefore(today)) continue;
        if (endDate != null && occDate.isAfter(endDate)) break;
        occurrenceDates.add(occDate);
      }
    } else {
      // Unknown frequency — just show the item as-is
      return [_mapItem(item)];
    }

    // Build feed entries from occurrence dates
    for (final ex in item.exceptions) {
      if (ex.status == 'cancelled') {
        cancelledDates.add(ex.date);
      }
    }

    // Build feed entries from occurrence dates
    for (int i = 0; i < occurrenceDates.length; i++) {
      final occDate = occurrenceDates[i];
      final occDateTime =
          DateTime(occDate.year, occDate.month, occDate.day, hour, minute);

      final dateStr =
          '${occDate.year}-${occDate.month.toString().padLeft(2, '0')}-${occDate.day.toString().padLeft(2, '0')}';

      // Skip hidden occurrences
      if (hiddenDates.contains(dateStr)) continue;

      final isCancelledOccurrence = cancelledDates.contains(dateStr);

      final catIcon = CategoryIcons.getIcon(item.category, item.type);
      final catColor = CategoryIcons.getColor(item.category, item.type);
      final catBg = CategoryIcons.getBackgroundColor(item.category, item.type);
      entries.add(FeedEntry(
        id: '${item.id}_o$i',
        title: item.title,
        location: item.location,
        childName: item.childName,
        ownerName: item.ownerName,
        dateTime: occDateTime,
        feedStatus: isCancelledOccurrence ? 'cancelled' : 'confirmed',
        type: item.type.name,
        icon: catIcon,
        iconColor: isCancelledOccurrence ? AppColors.textMuted : catColor,
        iconBg: isCancelledOccurrence ? AppColors.surfaceSoft : catBg,
        item: item,
        isRecurring: true,
        occurrenceDate: occDate,
      ));
    }

    return entries;
  }

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
  final Map<String, _MemberInfo> memberInfo;
  const _FeedCard({required this.entry, required this.householdId, required this.memberInfo});

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
                            colorHex: memberInfo[entry.childName!.toLowerCase()]?.color,
                            photoUrl: memberInfo[entry.childName!.toLowerCase()]?.photoUrl,
                            householdId: householdId,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(entry: entry),
                if (entry.autoApproved)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('✨ Auto',
                        style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ),
              ],
            ),
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
              occurrenceDate: entry.occurrenceDate,
            ),
          ),
        );
      }
    }
  }
}

/// Child chip with photo or colored initial avatar
class _ChildChip extends StatelessWidget {
  final String name;
  final String? colorHex;
  final String? photoUrl;
  final String? householdId;
  const _ChildChip({required this.name, this.colorHex, this.photoUrl, this.householdId});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = MemberColors.fromHex(colorHex);

    return GestureDetector(
      onTap: householdId != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildWeekScreen(
                    householdId: householdId!,
                    childName: name,
                    childColor: colorHex,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null && photoUrl!.isNotEmpty)
              CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(photoUrl!),
              )
            else
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
      'analyzing' => (AppStrings.get('analyzing'), AppColors.softBlue),
      'pendingReview' => (AppStrings.get('review'), AppColors.warmYellow),
      'confirmed' => (AppStrings.get('active'), AppColors.softGreen),
      'cancelled' => (AppStrings.get('cancelled'), AppColors.softCoral),
      'completed' => (AppStrings.get('done'), AppColors.softGreen),
      'failed' => (AppStrings.get('failed'), AppColors.softCoral),
      'noAction' => (AppStrings.get('no_action'), AppColors.textMuted),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration: floating emoji cluster
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 10, left: 30,
                    child: _FloatingEmoji(emoji: '📬', size: 32, delay: 0),
                  ),
                  Positioned(
                    top: 0, right: 40,
                    child: _FloatingEmoji(emoji: '✨', size: 24, delay: 200),
                  ),
                  Positioned(
                    bottom: 10, left: 50,
                    child: _FloatingEmoji(emoji: '🏠', size: 40, delay: 100),
                  ),
                  Positioned(
                    bottom: 20, right: 30,
                    child: _FloatingEmoji(emoji: '☀️', size: 28, delay: 300),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your family feed is clear',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Forward an email, share a message,\nor speak a quick reminder to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small floating emoji with a gentle bob animation
class _FloatingEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  final int delay;
  const _FloatingEmoji({required this.emoji, required this.size, required this.delay});

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _bounce = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -_bounce.value),
        child: child,
      ),
      child: Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
    );
  }
}

// --- Notification Bell ---
class _NotificationBell extends StatelessWidget {
  final String householdId;
  const _NotificationBell({required this.householdId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
          child: Stack(
            children: [
              Icon(
                count > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                color: count > 0 ? AppColors.primary : AppColors.textMuted,
                size: 26,
              ),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.softCoral,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
  String? _cityName;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      WeatherData? weather;

      // Use device GPS for weather (always most accurate)
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
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
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _weather = weather;
          _cityName = weather?.cityName;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _weather == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
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
        if (_cityName != null)
          Text(
            _cityName!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
          ),
      ],
    );
  }
}
