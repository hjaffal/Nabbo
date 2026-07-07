import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nabbo_widgets.dart';

/// Full screen detail view for a committed feed item (event, task, payment)
class FeedItemDetailScreen extends StatelessWidget {
  final String title;
  final String type;
  final String? childName;
  final String? ownerName;
  final String? subtitle;
  final String feedStatus;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final DocumentReference? docRef;
  final Map<String, dynamic>? rawData;

  const FeedItemDetailScreen({
    super.key,
    required this.title,
    required this.type,
    this.childName,
    this.ownerName,
    this.subtitle,
    required this.feedStatus,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.docRef,
    this.rawData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type[0].toUpperCase() + type.substring(1))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      if (subtitle != null)
                        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Status badge
            Row(
              children: [
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Child & Owner
            if (childName != null || ownerName != null)
              SoftCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    if (childName != null)
                      _detailRow(context, 'Child', childName!),
                    if (ownerName != null)
                      _detailRow(context, 'Owner', ownerName!),
                  ],
                ),
              ),

            if (childName != null || ownerName != null)
              const SizedBox(height: AppSpacing.lg),

            // All fields from raw data
            if (rawData != null)
              SoftCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Details', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    ..._buildAllFields(context),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.xxxl),

            // Action button
            if (docRef != null && feedStatus == 'confirmed')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _markDone(context),
                  child: Text(_actionLabel()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (label, color) = switch (feedStatus) {
      'confirmed' => ('Active', AppColors.softGreen),
      'cancelled' => ('Cancelled', AppColors.softCoral),
      'completed' => ('Done', AppColors.softGreen),
      'paid' => ('Paid', AppColors.softGreen),
      _ => ('Active', AppColors.softGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  List<Widget> _buildAllFields(BuildContext context) {
    if (rawData == null) return [];
    final skip = {'householdId', 'sourceExtractedItemId', 'sourceMessageId', 'affectedMemberId', 'ownerId', 'affectedMemberName', 'ownerName', 'status', 'createdAt'};

    return rawData!.entries
        .where((e) => e.value != null && !skip.contains(e.key) && e.value.toString().isNotEmpty)
        .map((e) {
      String val;
      if (e.value is Timestamp) {
        final dt = (e.value as Timestamp).toDate();
        val = '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        val = e.value.toString();
      }
      return _detailRow(context, _formatKey(e.key), val);
    }).toList();
  }

  String _formatKey(String key) {
    // camelCase to Title Case
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
  }

  String _actionLabel() => switch (type) {
        'task' => 'Mark done',
        'payment' => 'Mark paid',
        _ => 'Done',
      };

  Future<void> _markDone(BuildContext context) async {
    final update = switch (type) {
      'task' => {'status': 'completed'},
      'payment' => {'status': 'paid'},
      _ => <String, dynamic>{},
    };
    if (update.isNotEmpty && docRef != null) {
      await docRef!.update(update);
    }
    if (context.mounted) Navigator.pop(context);
  }
}
