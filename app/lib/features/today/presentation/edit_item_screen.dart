import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';

/// Edit screen for an ItemModel. Works at ANY lifecycle stage.
class EditItemScreen extends ConsumerStatefulWidget {
  final String householdId;
  final ItemModel item;

  const EditItemScreen({
    super.key,
    required this.householdId,
    required this.item,
  });

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _childNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _summaryController;

  DateTime? _date;
  DateTime? _endDate;
  TimeOfDay? _time;
  ItemType _type = ItemType.event;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item.title);
    _locationController = TextEditingController(text: item.location ?? '');
    _childNameController = TextEditingController(text: item.childName ?? '');
    _ownerNameController = TextEditingController(text: item.ownerName ?? '');
    _summaryController = TextEditingController(text: item.summary ?? '');
    _date = item.date;
    _endDate = item.endDate;
    _time = item.date != null
        ? TimeOfDay(hour: item.date!.hour, minute: item.date!.minute)
        : null;
    _type = item.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _childNameController.dispose();
    _ownerNameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{};

    // Title
    if (_titleController.text.trim() != widget.item.title) {
      updates['title'] = _titleController.text.trim();
    }

    // Location
    final loc = _locationController.text.trim();
    if (loc != (widget.item.location ?? '')) {
      updates['location'] = loc.isEmpty ? null : loc;
    }

    // Child name
    final child = _childNameController.text.trim();
    if (child != (widget.item.childName ?? '')) {
      updates['childName'] = child.isEmpty ? null : child;
    }

    // Owner name
    final owner = _ownerNameController.text.trim();
    if (owner != (widget.item.ownerName ?? '')) {
      updates['ownerName'] = owner.isEmpty ? null : owner;
    }

    // Summary
    final summary = _summaryController.text.trim();
    if (summary != (widget.item.summary ?? '')) {
      updates['summary'] = summary.isEmpty ? null : summary;
    }

    // Type
    if (_type != widget.item.type) {
      updates['type'] = _type.name;
    }

    // Date + time
    if (_date != null) {
      final hour = _time?.hour ?? 0;
      final minute = _time?.minute ?? 0;
      final combined =
          DateTime(_date!.year, _date!.month, _date!.day, hour, minute);
      if (combined != widget.item.date) {
        updates['date'] = Timestamp.fromDate(combined);
      }
    }

    // End date
    if (_endDate != widget.item.endDate) {
      updates['endDate'] =
          _endDate != null ? Timestamp.fromDate(_endDate!) : null;
    }

    if (updates.isNotEmpty) {
      await ref
          .read(itemRepositoryProvider)
          .updateItem(widget.householdId, widget.item.id, updates);
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
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
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            Text('Type',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SegmentedButton<ItemType>(
              segments: const [
                ButtonSegment(value: ItemType.event, label: Text('Event')),
                ButtonSegment(value: ItemType.task, label: Text('Task')),
                ButtonSegment(value: ItemType.deadline, label: Text('Deadline')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(labelText: 'Summary'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Child
            TextField(
              controller: _childNameController,
              decoration:
                  const InputDecoration(labelText: 'Child (affected member)'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Owner
            TextField(
              controller: _ownerNameController,
              decoration:
                  const InputDecoration(labelText: 'Owner (responsible parent)'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Date picker
            Text('Date & Time',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_date != null
                        ? '${_date!.day}/${_date!.month}/${_date!.year}'
                        : 'Pick date'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(_time != null
                        ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
                        : 'Pick time'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _pickEndDate,
              icon: const Icon(Icons.event, size: 16),
              label: Text(_endDate != null
                  ? 'End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'Set end date (optional)'),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
