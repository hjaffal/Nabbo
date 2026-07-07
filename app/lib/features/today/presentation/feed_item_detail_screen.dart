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
      appBar: AppBar(
        title: Text(type[0].toUpperCase() + type.substring(1)),
        actions: [
          if (docRef != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _openEdit(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
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

            // Status
            _buildStatusBadge(context),
            const SizedBox(height: AppSpacing.xl),

            // All data fields
            if (rawData != null)
              SoftCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildAllFields(context),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }

  List<Widget> _buildAllFields(BuildContext context) {
    if (rawData == null) return [];
    final skip = {'householdId', 'sourceExtractedItemId', 'sourceMessageId', 'affectedMemberId', 'ownerId'};

    // Show important fields first, then others
    final priority = ['title', 'affectedMemberName', 'ownerName', 'startDateTime', 'endDateTime', 'dueDate', 'location', 'amount', 'currency', 'recurrence', 'status'];
    final shown = <String>{};

    final widgets = <Widget>[];

    // Priority fields first
    for (final key in priority) {
      if (rawData!.containsKey(key) && !skip.contains(key)) {
        shown.add(key);
        widgets.add(_fieldRow(context, key, rawData![key]));
      }
    }

    // Then remaining fields
    for (final entry in rawData!.entries) {
      if (!skip.contains(entry.key) && !shown.contains(entry.key) && entry.value != null && entry.value.toString() != 'null' && entry.value.toString().isNotEmpty) {
        widgets.add(_fieldRow(context, entry.key, entry.value));
      }
    }

    return widgets;
  }

  Widget _fieldRow(BuildContext context, String key, dynamic value) {
    String val;
    if (value == null || value.toString() == 'null') {
      val = '— not set';
    } else if (value is Timestamp) {
      final dt = value.toDate();
      val = '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (value is List) {
      val = (value).join(', ');
    } else {
      val = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(_formatKey(key), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              val,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: val == '— not set' ? AppColors.textMuted : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!.toLowerCase()}').trim();
  }

  String _actionLabel() => switch (type) {
        'task' => 'Mark done',
        'payment' => 'Mark paid',
        _ => 'Mark complete',
      };

  Future<void> _markDone(BuildContext context) async {
    final update = switch (type) {
      'task' => {'status': 'completed'},
      'payment' => {'status': 'paid'},
      _ => <String, dynamic>{},
    };
    if (update.isNotEmpty && docRef != null) await docRef!.update(update);
    if (context.mounted) Navigator.pop(context);
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditFeedItemScreen(
          docRef: docRef!,
          rawData: rawData ?? {},
          type: type,
        ),
      ),
    );
  }
}

/// Edit screen — shows all fields as editable text fields
class _EditFeedItemScreen extends StatefulWidget {
  final DocumentReference docRef;
  final Map<String, dynamic> rawData;
  final String type;

  const _EditFeedItemScreen({required this.docRef, required this.rawData, required this.type});

  @override
  State<_EditFeedItemScreen> createState() => _EditFeedItemScreenState();
}

class _EditFeedItemScreenState extends State<_EditFeedItemScreen> {
  late Map<String, TextEditingController> _controllers;
  bool _isSaving = false;

  // Fields we allow editing (includes date/time and assignee)
  static const _editableFields = [
    'title', 'location', 'affectedMemberName', 'ownerName',
    'startDateTime', 'endDateTime', 'dueDate',
    'amount', 'currency', 'paymentMethod', 'paymentLink',
    'name', 'recurrence', 'description', 'submissionMethod',
    'status',
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final key in _editableFields) {
      final value = widget.rawData[key];
      String textVal = '';
      if (value is Timestamp) {
        final dt = value.toDate();
        textVal = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (value != null && value.toString() != 'null') {
        textVal = value.toString();
      }
      _controllers[key] = TextEditingController(text: textVal);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      final newVal = entry.value.text.trim();
      final oldVal = widget.rawData[entry.key]?.toString() ?? '';
      if (newVal != oldVal && newVal.isNotEmpty) {
        updates[entry.key] = newVal;
      }
    }

    if (updates.isNotEmpty) {
      await widget.docRef.update(updates);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.pop(context);
    }
  }

  String _formatKey(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!.toLowerCase()}').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _formatKey(entry.key),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
