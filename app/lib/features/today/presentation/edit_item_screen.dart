import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/member_colors.dart';
import '../../../core/config/api_keys.dart';
import '../../../core/widgets/place_autocomplete_field.dart';
import '../../household/data/models/family_member_model.dart';
import '../../household/data/repositories/household_repository.dart';
import '../../items/data/models/item_model.dart';
import '../../items/data/repositories/item_repository.dart';

/// Edit screen for an ItemModel. Works at ANY lifecycle stage.
/// Uses dropdowns for child and owner selection from family members.
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
  late TextEditingController _summaryController;

  String? _selectedChildId;
  String? _selectedChildName;
  String? _selectedOwnerId;
  String? _selectedOwnerName;
  String _location = '';
  DateTime? _date;
  DateTime? _endDate;
  TimeOfDay? _time;
  ItemType _type = ItemType.event;
  bool _isSaving = false;

  // Recurrence
  bool _repeats = false;
  String _frequency = 'weekly';
  String? _dayOfWeek;
  DateTime? _recurrenceEnd;

  List<FamilyMemberModel> _members = [];

  // Google Places API key
  static const _placesApiKey = ApiKeys.placesApiKey;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item.title);
    _summaryController = TextEditingController(text: item.summary ?? '');
    _selectedChildId = item.childId;
    _selectedChildName = item.childName;
    _selectedOwnerId = item.ownerId;
    _selectedOwnerName = item.ownerName;
    _location = item.location ?? '';
    _date = item.date;
    _endDate = item.endDate;
    _time = item.date != null
        ? TimeOfDay(hour: item.date!.hour, minute: item.date!.minute)
        : null;
    _type = item.type;

    // Recurrence
    if (item.recurrence != null) {
      _repeats = true;
      _frequency = item.recurrence!.frequency;
      _dayOfWeek = item.recurrence!.dayOfWeek;
      if (item.recurrence!.endDate != null) {
        _recurrenceEnd = DateTime.tryParse(item.recurrence!.endDate!);
      }
    }

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final repo = ref.read(householdRepositoryProvider);
    final members = await repo.getFamilyMembers(widget.householdId);
    if (mounted) setState(() => _members = members);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  List<FamilyMemberModel> get _children =>
      _members.where((m) => m.role == MemberRole.child).toList();

  List<FamilyMemberModel> get _adults => _members
      .where((m) =>
          m.role == MemberRole.primaryParent ||
          m.role == MemberRole.secondaryParent ||
          m.role == MemberRole.caregiver ||
          m.role == MemberRole.grandparent)
      .toList();

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{};

    // Title
    if (_titleController.text.trim() != widget.item.title) {
      updates['title'] = _titleController.text.trim();
    }

    // Location
    if (_location != (widget.item.location ?? '')) {
      updates['location'] = _location.isEmpty ? null : _location;
    }

    // Child
    if (_selectedChildId != widget.item.childId) {
      updates['childId'] = _selectedChildId;
      updates['childName'] = _selectedChildName;
    }

    // Owner
    if (_selectedOwnerId != widget.item.ownerId) {
      updates['ownerId'] = _selectedOwnerId;
      updates['ownerName'] = _selectedOwnerName;
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
    } else if (widget.item.date != null) {
      updates['date'] = null;
    }

    // End date
    if (_endDate != widget.item.endDate) {
      updates['endDate'] =
          _endDate != null ? Timestamp.fromDate(_endDate!) : null;
    }

    // Recurrence
    if (_repeats) {
      final startDate = _date ?? DateTime.now();
      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr = _recurrenceEnd != null
          ? '${_recurrenceEnd!.year}-${_recurrenceEnd!.month.toString().padLeft(2, '0')}-${_recurrenceEnd!.day.toString().padLeft(2, '0')}'
          : null;
      updates['recurrence'] = {
        'frequency': _frequency,
        'dayOfWeek': _dayOfWeek,
        'startDate': startStr,
        'endDate': endStr,
      };
    } else if (widget.item.recurrence != null) {
      // Was recurring, now not
      updates['recurrence'] = null;
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
            // Type
            _SectionLabel(label: 'Type'),
            const SizedBox(height: 8),
            SegmentedButton<ItemType>(
              segments: const [
                ButtonSegment(value: ItemType.event, label: Text('Event')),
                ButtonSegment(value: ItemType.task, label: Text('Task')),
                ButtonSegment(
                    value: ItemType.deadline, label: Text('Deadline')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            _SectionLabel(label: 'Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'What needs to happen?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Summary
            _SectionLabel(label: 'Summary'),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(
                hintText: 'Optional details',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Child (dropdown)
            _SectionLabel(label: 'Child (who is this about?)'),
            const SizedBox(height: 8),
            _MemberSelector(
              members: _children,
              selectedId: _selectedChildId,
              placeholder: 'Select child',
              onChanged: (member) {
                setState(() {
                  _selectedChildId = member?.id;
                  _selectedChildName = member?.name;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Owner (dropdown — adults only)
            _SectionLabel(label: 'Owner (who is responsible?)'),
            const SizedBox(height: 8),
            _MemberSelector(
              members: _adults,
              selectedId: _selectedOwnerId,
              placeholder: 'Assign a parent',
              onChanged: (member) {
                setState(() {
                  _selectedOwnerId = member?.id;
                  _selectedOwnerName = member?.name;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Location
            _SectionLabel(label: 'Location'),
            const SizedBox(height: 8),
            PlaceAutocompleteField(
              initialValue: _location,
              apiKey: _placesApiKey,
              onChanged: (value) => _location = value,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Date & Time
            _SectionLabel(label: 'Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.calendar_today,
                    label: _date != null
                        ? '${_date!.day}/${_date!.month}/${_date!.year}'
                        : 'Date',
                    hasValue: _date != null,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.access_time,
                    label: _time != null
                        ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
                        : 'Time',
                    hasValue: _time != null,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PickerButton(
              icon: Icons.event,
              label: _endDate != null
                  ? 'Ends: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'End date (optional)',
              hasValue: _endDate != null,
              onTap: _pickEndDate,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recurrence
            _SectionLabel(label: 'Recurrence'),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Repeats'),
              value: _repeats,
              onChanged: (v) => setState(() => _repeats = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_repeats) ...[
              const SizedBox(height: 8),
              // Frequency
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Every 2 weeks')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: AppSpacing.md),

              // Day of week (for weekly/biweekly/monthly)
              if (_frequency != 'daily')
                DropdownButtonFormField<String>(
                  value: _dayOfWeek,
                  decoration: const InputDecoration(
                    labelText: 'Day of week',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monday', child: Text('Monday')),
                    DropdownMenuItem(value: 'tuesday', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'wednesday', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'thursday', child: Text('Thursday')),
                    DropdownMenuItem(value: 'friday', child: Text('Friday')),
                    DropdownMenuItem(value: 'saturday', child: Text('Saturday')),
                    DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
                  ],
                  onChanged: (v) => setState(() => _dayOfWeek = v),
                ),
              const SizedBox(height: AppSpacing.md),

              // Recurrence end date
              _PickerButton(
                icon: Icons.event_busy,
                label: _recurrenceEnd != null
                    ? 'Until: ${_recurrenceEnd!.day}/${_recurrenceEnd!.month}/${_recurrenceEnd!.year}'
                    : 'Repeats forever (tap to set end)',
                hasValue: _recurrenceEnd != null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _recurrenceEnd ?? DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _recurrenceEnd = picked);
                },
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// --- Section Label ---
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// --- Member Selector (dropdown with color dots) ---
class _MemberSelector extends StatelessWidget {
  final List<FamilyMemberModel> members;
  final String? selectedId;
  final String placeholder;
  final ValueChanged<FamilyMemberModel?> onChanged;

  const _MemberSelector({
    required this.members,
    required this.selectedId,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hint: Text(placeholder,
              style: TextStyle(color: AppColors.textMuted)),
          items: [
            // "None" option
            DropdownMenuItem<String?>(
              value: null,
              child: Text('— None',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            // Family members
            ...members.map((m) {
              final color = MemberColors.fromHex(m.color);
              return DropdownMenuItem<String?>(
                value: m.id,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          m.name[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(m.name),
                  ],
                ),
              );
            }),
          ],
          onChanged: (id) {
            if (id == null) {
              onChanged(null);
            } else {
              final member = members.firstWhere((m) => m.id == id);
              onChanged(member);
            }
          },
        ),
      ),
    );
  }
}

// --- Picker Button ---
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          color: hasValue ? null : AppColors.textMuted,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
