import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Notification toggles
  bool _reviewAlerts = true;
  bool _changeAlerts = true;
  bool _deadlineAlerts = true;
  bool _ownerGapAlerts = true;
  bool _prepReminders = true;
  bool _morningBrief = false;
  bool _eveningReset = false;
  bool _weeklyBrief = false;

  // Quiet hours
  bool _quietHoursEnabled = true;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _reviewAlerts = prefs.getBool('notif_review') ?? true;
      _changeAlerts = prefs.getBool('notif_changes') ?? true;
      _deadlineAlerts = prefs.getBool('notif_deadlines') ?? true;
      _ownerGapAlerts = prefs.getBool('notif_owner_gaps') ?? true;
      _prepReminders = prefs.getBool('notif_prep') ?? true;
      _morningBrief = prefs.getBool('notif_morning') ?? false;
      _eveningReset = prefs.getBool('notif_evening') ?? false;
      _weeklyBrief = prefs.getBool('notif_weekly') ?? false;
      _quietHoursEnabled = prefs.getBool('notif_quiet_enabled') ?? true;
      _quietStart = TimeOfDay(
        hour: prefs.getInt('notif_quiet_start_h') ?? 22,
        minute: prefs.getInt('notif_quiet_start_m') ?? 0,
      );
      _quietEnd = TimeOfDay(
        hour: prefs.getInt('notif_quiet_end_h') ?? 7,
        minute: prefs.getInt('notif_quiet_end_m') ?? 0,
      );
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_quiet_enabled', _quietHoursEnabled);
    await prefs.setInt('notif_quiet_start_h', _quietStart.hour);
    await prefs.setInt('notif_quiet_start_m', _quietStart.minute);
    await prefs.setInt('notif_quiet_end_h', _quietEnd.hour);
    await prefs.setInt('notif_quiet_end_m', _quietEnd.minute);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
      _saveQuietHours();
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          // Enabled by default section
          _SectionHeader(title: 'Active Alerts'),
          _NotifTile(
            title: 'Review needed',
            subtitle: 'When Nabbo finds something that needs your attention',
            value: _reviewAlerts,
            onChanged: (v) {
              setState(() => _reviewAlerts = v);
              _savePreference('notif_review', v);
            },
          ),
          _NotifTile(
            title: 'Changes detected',
            subtitle: 'Time, location, or schedule changes',
            value: _changeAlerts,
            onChanged: (v) {
              setState(() => _changeAlerts = v);
              _savePreference('notif_changes', v);
            },
          ),
          _NotifTile(
            title: 'Deadline alerts',
            subtitle: 'Forms, payments, or tasks due soon',
            value: _deadlineAlerts,
            onChanged: (v) {
              setState(() => _deadlineAlerts = v);
              _savePreference('notif_deadlines', v);
            },
          ),
          _NotifTile(
            title: 'Owner gaps',
            subtitle: 'Actions with no assigned owner',
            value: _ownerGapAlerts,
            onChanged: (v) {
              setState(() => _ownerGapAlerts = v);
              _savePreference('notif_owner_gaps', v);
            },
          ),
          _NotifTile(
            title: 'Preparation reminders',
            subtitle: 'Pack items, bring things before events',
            value: _prepReminders,
            onChanged: (v) {
              setState(() => _prepReminders = v);
              _savePreference('notif_prep', v);
            },
          ),

          const Divider(),

          // Optional section
          _SectionHeader(title: 'Daily Briefs'),
          _NotifTile(
            title: 'Morning brief',
            subtitle: "Summary of today's plan",
            value: _morningBrief,
            onChanged: (v) {
              setState(() => _morningBrief = v);
              _savePreference('notif_morning', v);
            },
          ),
          _NotifTile(
            title: 'Evening reset',
            subtitle: 'Prepare for tomorrow',
            value: _eveningReset,
            onChanged: (v) {
              setState(() => _eveningReset = v);
              _savePreference('notif_evening', v);
            },
          ),
          _NotifTile(
            title: 'Weekly brief',
            subtitle: 'Week ahead summary',
            value: _weeklyBrief,
            onChanged: (v) {
              setState(() => _weeklyBrief = v);
              _savePreference('notif_weekly', v);
            },
          ),

          const Divider(),

          // Quiet hours
          _SectionHeader(title: 'Quiet Hours'),
          SwitchListTile(
            title: const Text('Enable quiet hours'),
            subtitle: const Text('No notifications during this window'),
            value: _quietHoursEnabled,
            onChanged: (v) {
              setState(() => _quietHoursEnabled = v);
              _saveQuietHours();
            },
          ),
          if (_quietHoursEnabled) ...[
            ListTile(
              title: const Text('Start'),
              trailing: TextButton(
                onPressed: () => _pickTime(true),
                child: Text(_formatTime(_quietStart)),
              ),
            ),
            ListTile(
              title: const Text('End'),
              trailing: TextButton(
                onPressed: () => _pickTime(false),
                child: Text(_formatTime(_quietEnd)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
