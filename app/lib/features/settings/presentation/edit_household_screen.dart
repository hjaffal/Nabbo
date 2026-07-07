import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/constants/timezones.dart';
import '../../../core/widgets/labeled_field.dart';
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
  final _zipCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  String _timezone = 'Europe/Berlin';
  String _language = 'en';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDetecting = false;
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
    _zipCodeController.dispose();
    _cityController.dispose();
    _countryController.dispose();
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
        _zipCodeController.text = household.zipCode ?? '';
        _cityController.text = household.city ?? '';
        _countryController.text = household.country ?? '';
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
        zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
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

  Future<void> _detectLocation() async {
    setState(() => _isDetecting = true);
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Enable in Settings.');
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _zipCodeController.text = place.postalCode ?? '';
          _cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
          _countryController.text = place.country ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
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
              LabeledField(
                label: 'Household name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter household name',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      controller: TextEditingController(text: _timezone),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              LabeledField(
                label: 'Default language',
                child: DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(
                    hintText: 'Select language',
                  ),
                  items: _languages.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ),
              const SizedBox(height: 20),

              // Email alias (read-only)
              if (_household?.emailAlias != null)
                LabeledField(
                  label: 'Nabbo email alias',
                  readOnly: true,
                  child: TextFormField(
                    initialValue: _household!.emailAlias,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Email alias',
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Location section
              Row(
                children: [
                  Text('Location',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isDetecting ? null : _detectLocation,
                    icon: _isDetecting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(_isDetecting ? 'Detecting...' : 'Detect'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              LabeledField(
                label: 'Zip / Postal code',
                child: TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 1012',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              LabeledField(
                label: 'City',
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Amsterdam',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              LabeledField(
                label: 'Country',
                child: TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Netherlands',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
