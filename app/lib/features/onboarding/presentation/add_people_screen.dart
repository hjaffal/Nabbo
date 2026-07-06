import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text('Other People')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Anyone else in the household?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Optional. You can add more people later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Sara',
                    ),
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<MemberRole>(
                  value: _selectedRole,
                  items: [
                    MemberRole.secondaryParent,
                    MemberRole.caregiver,
                    MemberRole.grandparent,
                    MemberRole.babysitter,
                    MemberRole.other,
                  ]
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(_roleLabel(r))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addPerson,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // People list
            Expanded(
              child: ListView.builder(
                itemCount: _people.length,
                itemBuilder: (context, index) {
                  final person = _people[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(person.name[0].toUpperCase()),
                      ),
                      title: Text(person.name),
                      subtitle: Text(_roleLabel(person.role)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removePerson(index),
                      ),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
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
