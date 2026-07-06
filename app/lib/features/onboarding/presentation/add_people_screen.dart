import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../household/data/models/family_member_model.dart';
import '../../household/data/repositories/household_repository.dart';

class AddPeopleScreen extends ConsumerStatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  ConsumerState<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends ConsumerState<AddPeopleScreen> {
  final _nameController = TextEditingController();
  MemberRole _selectedRole = MemberRole.secondaryParent;
  final List<({String name, MemberRole role})> _people = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _people.add((name: name, role: _selectedRole));
      _nameController.clear();
    });
  }

  void _removePerson(int index) {
    setState(() => _people.removeAt(index));
  }

  Future<void> _continue() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final repo = ref.read(householdRepositoryProvider);
      final household = await repo.getHouseholdByUserId(userId);

      if (household == null) throw Exception('Household not found');

      for (final person in _people) {
        await repo.addFamilyMember(FamilyMemberModel(
          id: '',
          householdId: household.id,
          name: person.name,
          role: person.role,
          ageGroup: AgeGroup.adult,
        ));
      }

      if (!mounted) return;
      context.go('/onboarding/email');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _roleLabel(MemberRole role) {
    return switch (role) {
      MemberRole.secondaryParent => 'Second parent',
      MemberRole.caregiver => 'Caregiver',
      MemberRole.grandparent => 'Grandparent',
      MemberRole.babysitter => 'Babysitter',
      _ => 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Anyone else?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Optional. You can add more people later.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Input section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'e.g. Sara',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _addPerson(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _addPerson,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.deepTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Role selector
                  Wrap(
                    spacing: 8,
                    children: [
                      MemberRole.secondaryParent,
                      MemberRole.caregiver,
                      MemberRole.grandparent,
                      MemberRole.babysitter,
                      MemberRole.other,
                    ].map((role) {
                      final selected = _selectedRole == role;
                      return ChoiceChip(
                        label: Text(_roleLabel(role)),
                        selected: selected,
                        onSelected: (v) =>
                            setState(() => _selectedRole = role),
                        selectedColor: AppColors.deepTeal,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // People list
            Expanded(
              child: _people.isEmpty
                  ? Center(
                      child: Text(
                        'No people added yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _people.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final person = _people[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.mintCard,
                                child: Text(
                                  person.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      _roleLabel(person.role),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removePerson(index),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: _isLoading ? null : _continue,
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/onboarding/email'),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
