import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/timezones.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/timezone_search_sheet.dart';
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

  static const _timezones = AppTimezones.all;

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about\nyour household',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps Nabbo organise everything for your family.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Form in a card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: 'Household name',
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. The Jaffal Family',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    LabeledField(
                      label: 'Your name',
                      child: TextFormField(
                        controller: _parentNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Hasan',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    LabeledField(
                      label: 'Timezone',
                      child: GestureDetector(
                        onTap: () => _showTimezonePicker(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Select timezone',
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            controller:
                                TextEditingController(text: _timezone),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    LabeledField(
                      label: 'Default language',
                      child: DropdownButtonFormField<String>(
                        initialValue: _language,
                        decoration: const InputDecoration(
                          hintText: 'Select language',
                        ),
                        items: _languages.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _language = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
