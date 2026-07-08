import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/activity_event_model.dart';

class ActivityCard extends StatelessWidget {
  final ActivityEventModel event;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actor avatar
            _ActorAvatar(name: event.actorName),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action text
                  _ActionText(event: event),
                  const SizedBox(height: 2),

                  // Item title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Bottom row: child chip + timestamp
                  Row(
                    children: [
                      if (event.childName != null && event.childName!.isNotEmpty) ...[
                        _ChildPill(name: event.childName!),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        _formatRelativeTime(event.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '${mins < 1 ? 1 : mins} min ago';
    }

    // Same day or older — show formatted time
    return DateFormat('h:mm a').format(dateTime);
  }
}

class _ActorAvatar extends StatelessWidget {
  final String name;
  const _ActorAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  final ActivityEventModel event;
  const _ActionText({required this.event});

  @override
  Widget build(BuildContext context) {
    final isAutoApproval = event.activityType == ActivityType.autoApproval;

    return Row(
      children: [
        if (isAutoApproval) ...[
          const Icon(
            Icons.auto_awesome,
            size: 13,
            color: AppColors.warmYellow,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            _buildActionText(),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _buildActionText() {
    final meta = event.metadata;
    final actorName = event.actorName;

    switch (event.activityType) {
      case ActivityType.approval:
        return '$actorName approved';
      case ActivityType.capture:
        final itemCount = meta['itemCount'] ?? 1;
        final inputMethod = meta['inputMethod'] ?? 'text';
        final itemLabel = itemCount == 1 ? 'item' : 'items';
        return '$actorName captured $itemCount $itemLabel from $inputMethod';
      case ActivityType.completion:
        return '$actorName completed';
      case ActivityType.cancellation:
        return '$actorName cancelled';
      case ActivityType.edit:
        final changedFields = meta['changedFields'];
        if (changedFields is List && changedFields.isNotEmpty) {
          final fields = changedFields.cast<String>();
          if (fields.length <= 2) {
            return '$actorName updated ${fields.join(', ')}';
          }
          return '$actorName updated ${fields.take(2).join(', ')} + ${fields.length - 2} more';
        }
        return '$actorName updated';
      case ActivityType.autoApproval:
        return 'Auto-approved';
    }
  }
}

class _ChildPill extends StatelessWidget {
  final String name;
  const _ChildPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
