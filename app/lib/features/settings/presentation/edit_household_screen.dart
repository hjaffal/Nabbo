import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/timezones.dart';
import '../../../core/widgets/timezone_search_sheet.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

class EditHouseholdScreen extends ConsumerStatefulWidget {
  const EditHouseholdScreen({super.key});

  @override
  ConsumerState<EditHouseholdScreen> createState() =>
      _EditHouseholdScreenState();
}

class _EditHouseholdScreenState extends ConsumerState<EditHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _timezone = 'Europe/Berlin';
  String _language = 'en';
  bool _isLoading = true;
  bool _isSaving = false;
  HouseholdModel? _household;

  static const _timezones = AppTimezones.all;

  static const _languages = {
    'en': 'English',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
  };

  @override
  void initState() {
    super.initState();
    _loadHousehold();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadHousehold() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final repo = ref.read(householdRepositoryProvider);
    final household = await repo.getHouseholdByUserId(userId);

    if (household != null && mounted) {
      setState(() {
        _household = household;
        _nameController.text = household.name;
        _timezone = household.timezone;
        _language = household.language;
        _isLoading = false;
      });
    }
  }

  void _showTimezonePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TimezoneSearchSheet(
        timezones: _timezones,
        selected: _timezone,
        onSelected: (tz) {
          setState(() => _timezone = tz);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _household == null) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(householdRepositoryProvider);
      await repo.updateHousehold(_household!.copyWith(
        name: _nameController.text.trim(),
        timezone: _timezone,
        language: _language,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Household updated')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Household')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Household'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Household name',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => _showTimezonePicker(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Timezone',
                      hintText: 'Select timezone',
                      prefixIcon: Icon(Icons.schedule_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    controller: TextEditingController(text: _timezone),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _language,
                decoration: const InputDecoration(
                  labelText: 'Default language',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
                items: _languages.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 20),

              // Email alias (read-only)
              if (_household?.emailAlias != null)
                TextFormField(
                  initialValue: _household!.emailAlias,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Nabbo email alias',
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: 'This cannot be changed',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
