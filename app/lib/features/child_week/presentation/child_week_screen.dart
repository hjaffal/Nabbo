import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/category_icons.dart';
import '../../../core/theme/member_colors.dart';
import '../../items/data/models/item_model.dart';
import '../../today/presentation/item_detail_screen.dart';

/// Per-child week view: shows Mon–Sun of the current week for a specific child.
class ChildWeekScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String childName;
  final String? childId;
  final String? childColor;

  const ChildWeekScreen({
    super.key,
    required this.householdId,
    required this.childName,
    this.childId,
    this.childColor,
  });

  @override
  ConsumerState<ChildWeekScreen> createState() => _ChildWeekScreenState();
}

class _ChildWeekScreenState extends ConsumerState<ChildWeekScreen> {
  List<ItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// Get Monday of the current week
  DateTime get _weekStart {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysFromMonday = today.weekday - 1; // Monday = 1
    return today.subtract(Duration(days: daysFromMonday));
  }

  /// Get Sunday of the current week
  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  Future<void> _loadItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('households')
          .doc(widget.householdId)
          .collection('items')
          .where('childName', isEqualTo: widget.childName)
          .where('status', whereIn: ['confirmed', 'pendingReview'])
          .get();

      final items = <ItemModel>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(ItemModel.fromFirestore(doc));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Expand items into per-day entries for this week
  Map<DateTime, List<_DayItem>> _buildWeekData() {
    final weekData = <DateTime, List<_DayItem>>{};

    // Initialize all 7 days
    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      weekData[day] = [];
    }

    for (final item in _items) {
      if (item.recurrence != null) {
        // Expand recurring items for this week
        _expandRecurringForWeek(item, weekData);
      } else if (item.date != null) {
        // Single item — check if it falls within this week
        final itemDay = DateTime(item.date!.year, item.date!.month, item.date!.day);
        if (!itemDay.isBefore(_weekStart) && !itemDay.isAfter(_weekEnd)) {
          weekData[itemDay]?.add(_DayItem(item: item, time: item.date));
        }
      }
    }

    // Sort each day's items by time
    for (final day in weekData.keys) {
      weekData[day]!.sort((a, b) {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return -1; // all-day first
        if (b.time == null) return -1;
        return a.time!.compareTo(b.time!);
      });
    }

    return weekData;
  }

  void _expandRecurringForWeek(ItemModel item, Map<DateTime, List<_DayItem>> weekData) {
    final rule = item.recurrence!;
    final hour = item.date?.hour ?? 0;
    final minute = item.date?.minute ?? 0;

    // Parse end date
    DateTime? endDate;
    if (rule.endDate != null) {
      endDate = DateTime.tryParse(rule.endDate!);
    }

    // Build cancelled/hidden dates set
    final excludedDates = <String>{};
    for (final ex in item.exceptions) {
      if (ex.status == 'cancelled' || ex.status == 'hidden') {
        excludedDates.add(ex.date);
      }
    }

    // Parse dayOfWeek
    int? targetWeekday;
    if (rule.dayOfWeek != null) {
      const dayNames = [
        'monday', 'tuesday', 'wednesday', 'thursday',
        'friday', 'saturday', 'sunday'
      ];
      final idx = dayNames.indexOf(rule.dayOfWeek!.toLowerCase());
      if (idx >= 0) targetWeekday = idx + 1; // 1=Mon, 7=Sun
    }

    // Generate occurrences for each day of the week
    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      final dateStr = _formatDateStr(day);

      // Skip if end date passed
      if (endDate != null && day.isAfter(endDate)) continue;

      // Skip excluded dates
      if (excludedDates.contains(dateStr)) continue;

      bool showOnDay = false;

      switch (rule.frequency) {
        case 'daily':
          // Show every day (if startDate allows)
          if (rule.startDate != null) {
            final start = DateTime.tryParse(rule.startDate!);
            if (start != null && day.isBefore(start)) continue;
          }
          showOnDay = true;
          break;

        case 'weekly':
          if (targetWeekday != null && day.weekday == targetWeekday) {
            if (rule.startDate != null) {
              final start = DateTime.tryParse(rule.startDate!);
              if (start != null && day.isBefore(start)) continue;
            }
            showOnDay = true;
          }
          break;

        case 'biweekly':
          if (targetWeekday != null && day.weekday == targetWeekday) {
            // Check if this is an "on" week
            if (rule.startDate != null) {
              final start = DateTime.tryParse(rule.startDate!);
              if (start != null) {
                if (day.isBefore(start)) continue;
                final weeksDiff = day.difference(start).inDays ~/ 7;
                if (weeksDiff % 2 != 0) continue; // skip "off" weeks
              }
            }
            showOnDay = true;
          }
          break;

        case 'monthly':
          // Monthly on a specific day of month
          if (targetWeekday != null) {
            // First occurrence of that weekday in the month
            final firstOfMonth = DateTime(day.year, day.month, 1);
            var target = firstOfMonth;
            while (target.weekday != targetWeekday) {
              target = target.add(const Duration(days: 1));
            }
            if (day.day == target.day) showOnDay = true;
          } else {
            final dayOfMonth = item.date?.day ?? 1;
            if (day.day == dayOfMonth) showOnDay = true;
          }
          break;
      }

      if (showOnDay) {
        final occTime = DateTime(day.year, day.month, day.day, hour, minute);
        weekData[day]?.add(_DayItem(
          item: item,
          time: (hour == 0 && minute == 0) ? null : occTime,
          occurrenceDate: day,
        ));
      }
    }
  }

  String _formatDateStr(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = MemberColors.fromHex(widget.childColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("${widget.childName}'s week"),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: accentColor,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final weekData = _buildWeekData();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = _weekStart.add(Duration(days: index));
        final items = weekData[day] ?? [];
        final isToday = day == today;

        return Padding(
          padding: EdgeInsets.only(bottom: index < 6 ? 24 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              _DayHeader(date: day, isToday: isToday),
              const SizedBox(height: AppSpacing.sm),
              // Items or empty
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    'Nothing planned',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                ...items.map((dayItem) => _ItemRow(
                      dayItem: dayItem,
                      householdId: widget.householdId,
                    )),
            ],
          ),
        );
      },
    );
  }
}

/// Represents a single item on a specific day
class _DayItem {
  final ItemModel item;
  final DateTime? time;
  final DateTime? occurrenceDate;

  const _DayItem({
    required this.item,
    this.time,
    this.occurrenceDate,
  });

  bool get hasTime => time != null && (time!.hour != 0 || time!.minute != 0);
}

/// Day header with bold/normal styling and today indicator
class _DayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const _DayHeader({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final label = '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';

    return Row(
      children: [
        if (isToday) ...[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// A single item row: time on left, category dot + title + location on right
class _ItemRow extends StatelessWidget {
  final _DayItem dayItem;
  final String householdId;

  const _ItemRow({required this.dayItem, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final item = dayItem.item;
    final catColor = CategoryIcons.getColor(item.category, item.type);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              householdId: householdId,
              item: item,
              occurrenceDate: dayItem.occurrenceDate,
            ),
          ),
        );
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 50,
              child: Text(
                dayItem.hasTime ? _formatTime(dayItem.time!) : 'All day',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            // Category dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
            ),
            // Title + location
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.location != null && item.location!.isNotEmpty)
                    Text(
                      item.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
