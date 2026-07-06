import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

class HouseholdSetupScreen extends ConsumerStatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  ConsumerState<HouseholdSetupScreen> createState() =>
      _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends ConsumerState<HouseholdSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  String _timezone = 'Europe/Berlin';
  String _language = 'en';
  bool _isLoading = false;

  static const _timezones = [
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Madrid',
    'America/New_York',
    'America/Chicago',
    'America/Los_Angeles',
    'Asia/Dubai',
  ];

  static const _languages = {
    'en': 'English',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final repo = ref.read(householdRepositoryProvider);

      await repo.createHousehold(HouseholdModel(
        id: '',
        name: _nameController.text.trim(),
        primaryUserId: userId,
        timezone: _timezone,
        language: _language,
      ));

      // Update user display name
      await FirebaseAuth.instance.currentUser!
          .updateDisplayName(_parentNameController.text.trim());

      if (!mounted) return;
      context.go('/onboarding/children');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about your household',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Household name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Household name',
                  hintText: 'e.g. The Jaffal Family',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Parent name
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'e.g. Hasan',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Timezone
              DropdownButtonFormField<String>(
                initialValue: _timezone,
                decoration: const InputDecoration(labelText: 'Timezone'),
                items: _timezones
                    .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                    .toList(),
                onChanged: (v) => setState(() => _timezone = v!),
              ),
              const SizedBox(height: 16),

              // Language
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(labelText: 'Default language'),
                items: _languages.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
