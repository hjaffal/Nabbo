import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A premium "daily briefing" card shown at the top of the feed.
/// Summarizes today's events, deadlines, tasks, and items needing review.
class MorningBriefCard extends StatefulWidget {
  final String householdId;
  const MorningBriefCard({super.key, required this.householdId});

  @override
  State<MorningBriefCard> createState() => _MorningBriefCardState();
}

class _MorningBriefCardState extends State<MorningBriefCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final db = FirebaseFirestore.instance;
    final itemsRef = db
        .collection('households')
        .doc(widget.householdId)
        .collection('items');

    return StreamBuilder<QuerySnapshot>(
      stream: itemsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final endOfToday = startOfToday.add(const Duration(days: 1));
        final endOfTomorrow = startOfToday.add(const Duration(days: 2));

        final docs = snapshot.data!.docs;

        // Parse all items
        final events = <_BriefItem>[];
        final deadlines = <_BriefItem>[];
        final tasks = <_BriefItem>[];
        final noOwnerItems = <_BriefItem>[];
        int pendingCount = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          final type = data['type'] as String?;
          final title = data['title'] as String? ?? 'Untitled';
          final ownerName = data['ownerName'] as String?;

          // Count pending review items
          if (status == 'pendingReview') {
            pendingCount++;
            continue;
          }

          if (status != 'confirmed') continue;

          // Parse date
          DateTime? itemDate;
          final dateField = data['date'];
          if (dateField is Timestamp) {
            itemDate = dateField.toDate();
          }
          if (itemDate == null) continue;

          final isToday =
              itemDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              itemDate.isBefore(endOfToday);
          final isTodayOrTomorrow =
              itemDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              itemDate.isBefore(endOfTomorrow);

          // Events today
          if (type == 'event' && isToday) {
            events.add(_BriefItem(title: title));
          }

          // Deadlines today or tomorrow
          if (type == 'deadline' && isTodayOrTomorrow) {
            deadlines.add(_BriefItem(title: title));
          }

          // Tasks today
          if (type == 'task' && isToday) {
            tasks.add(_BriefItem(title: title));
          }

          // No owner items due today/tomorrow
          if (ownerName == null && isTodayOrTomorrow) {
            noOwnerItems.add(_BriefItem(title: title));
          }
        }

        final hasContent = events.isNotEmpty ||
            deadlines.isNotEmpty ||
            tasks.isNotEmpty ||
            pendingCount > 0 ||
            noOwnerItems.isNotEmpty;

        return _buildCard(
          context,
          now: now,
          events: events,
          deadlines: deadlines,
          tasks: tasks,
          pendingCount: pendingCount,
          noOwnerItems: noOwnerItems,
          hasContent: hasContent,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required DateTime now,
    required List<_BriefItem> events,
    required List<_BriefItem> deadlines,
    required List<_BriefItem> tasks,
    required int pendingCount,
    required List<_BriefItem> noOwnerItems,
    required bool hasContent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dismiss button
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white54,
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting row
              Row(
                children: [
                  Text(
                    _timeIcon(now),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _greeting(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Body
              if (!hasContent)
                const Text(
                  'Nothing scheduled today. Enjoy! ✨',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                )
              else ...[
                const Text(
                  'Today you have:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (events.isNotEmpty)
                  _bulletLine(
                    '${events.length} event${events.length > 1 ? 's' : ''} (${_names(events)})',
                  ),
                if (deadlines.isNotEmpty)
                  _bulletLine(
                    '${deadlines.length} deadline${deadlines.length > 1 ? 's' : ''} (${_names(deadlines)})',
                  ),
                if (tasks.isNotEmpty)
                  _bulletLine(
                    '${tasks.length} task${tasks.length > 1 ? 's' : ''} (${_names(tasks)})',
                  ),
                if (pendingCount > 0)
                  _bulletLine(
                    '$pendingCount item${pendingCount > 1 ? 's' : ''} to review',
                  ),
                if (noOwnerItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'No owner for: ${_names(noOwnerItems)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeIcon(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  String _names(List<_BriefItem> items) {
    if (items.length <= 3) {
      return items.map((e) => e.title).join(', ');
    }
    return '${items.take(2).map((e) => e.title).join(', ')} +${items.length - 2} more';
  }
}

class _BriefItem {
  final String title;
  const _BriefItem({required this.title});
}
