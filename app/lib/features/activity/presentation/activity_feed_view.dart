import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';
import '../../review/presentation/review_detail_screen.dart';
import '../../today/presentation/item_detail_screen.dart';
import '../data/models/activity_event_model.dart';
import '../data/repositories/activity_repository.dart';
import 'widgets/activity_card.dart';
import 'widgets/activity_empty_state.dart';

class ActivityFeedView extends ConsumerStatefulWidget {
  final String householdId;

  const ActivityFeedView({super.key, required this.householdId});

  @override
  ConsumerState<ActivityFeedView> createState() => _ActivityFeedViewState();
}

class _ActivityFeedViewState extends ConsumerState<ActivityFeedView> {
  final ScrollController _scrollController = ScrollController();
  final List<ActivityEventModel> _additionalEvents = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final repo = ref.read(activityRepositoryProvider);
      // Get the last event's timestamp to paginate from
      final allEvents = _getAllEvents(null);
      if (allEvents.isEmpty) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
        return;
      }

      final lastEvent = allEvents.last;
      final lastCreatedAt = lastEvent.createdAt ?? DateTime.now();

      final moreEvents = await repo.loadMore(
        widget.householdId,
        lastCreatedAt,
        limit: 50,
      );

      setState(() {
        _additionalEvents.addAll(moreEvents);
        _isLoadingMore = false;
        _hasMore = moreEvents.length >= 50;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  List<ActivityEventModel> _getAllEvents(List<ActivityEventModel>? streamEvents) {
    final combined = <ActivityEventModel>[
      ...?streamEvents,
      ..._additionalEvents,
    ];
    // Deduplicate by id
    final seen = <String>{};
    combined.retainWhere((e) => seen.add(e.id));
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(activityRepositoryProvider);

    return StreamBuilder<List<ActivityEventModel>>(
      stream: repo.watchEvents(widget.householdId),
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _ErrorView(onRetry: () => setState(() {}));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final streamEvents = snapshot.data!;
        final allEvents = _getAllEvents(streamEvents);

        if (allEvents.isEmpty) {
          return const ActivityEmptyState();
        }

        // Group events by date
        final grouped = _groupByDate(allEvents);

        return RefreshIndicator(
          onRefresh: () async {
            _additionalEvents.clear();
            _hasMore = true;
            setState(() {});
          },
          child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          itemCount: grouped.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == grouped.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final section = grouped[index];

            if (section.isHeader) {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? AppSpacing.sm : AppSpacing.xl,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  section.headerText!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              );
            }

            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: ActivityCard(
                event: section.event!,
                onTap: () => _onTapEvent(context, section.event!),
              ),
            );
          },
        ),
        );
      },
    );
  }

  List<_FeedSection> _groupByDate(List<ActivityEventModel> events) {
    final sections = <_FeedSection>[];
    String? lastHeader;

    for (final event in events) {
      final header = _dateHeader(event.createdAt);
      if (header != lastHeader) {
        sections.add(_FeedSection.header(header));
        lastHeader = header;
      }
      sections.add(_FeedSection.item(event));
    }

    return sections;
  }

  String _dateHeader(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final eventDay = DateTime(date.year, date.month, date.day);

    if (eventDay == today) return 'Today';
    if (eventDay == yesterday) return 'Yesterday';

    return DateFormat('EEE, d MMM').format(date);
  }

  Future<void> _onTapEvent(BuildContext context, ActivityEventModel event) async {
    // For capture events, navigate to review detail
    if (event.activityType == ActivityType.capture && event.sourceMessageId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(
            householdId: widget.householdId,
            sourceMessageId: event.sourceMessageId!,
          ),
        ),
      );
      return;
    }

    // For other events, navigate to item detail if relatedItemId exists
    if (event.relatedItemId != null) {
      final itemRepo = ref.read(itemRepositoryProvider);
      final item = await itemRepo.getItem(widget.householdId, event.relatedItemId!);

      if (!context.mounted) return;

      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This item is no longer available'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (item.status == ItemStatus.pendingReview && item.sourceMessageId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewDetailScreen(
              householdId: widget.householdId,
              sourceMessageId: item.sourceMessageId!,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              householdId: widget.householdId,
              item: item,
            ),
          ),
        );
      }
    }
  }
}

class _FeedSection {
  final String? headerText;
  final ActivityEventModel? event;

  _FeedSection.header(this.headerText) : event = null;
  _FeedSection.item(this.event) : headerText = null;

  bool get isHeader => headerText != null;
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Couldn't load activity. Tap to retry.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
