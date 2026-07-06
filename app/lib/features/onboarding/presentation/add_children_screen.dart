import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/data/models/family_member_model.dart';
import '../../household/data/repositories/household_repository.dart';

class AddChildrenScreen extends ConsumerStatefulWidget {
  const AddChildrenScreen({super.key});

  @override
  ConsumerState<AddChildrenScreen> createState() => _AddChildrenScreenState();
}

class _AddChildrenScreenState extends ConsumerState<AddChildrenScreen> {
  final _nameController = TextEditingController();
  final List<String> _children = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addChild() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _children.add(name);
      _nameController.clear();
    });
  }

  void _removeChild(int index) {
    setState(() => _children.removeAt(index));
  }

  Future<void> _continue() async {
    if (_children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one child')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final repo = ref.read(householdRepositoryProvider);
      final household = await repo.getHouseholdByUserId(userId);

      if (household == null) throw Exception('Household not found');

      for (final childName in _children) {
        await repo.addFamilyMember(FamilyMemberModel(
          id: '',
          householdId: household.id,
          name: childName,
          role: MemberRole.child,
          ageGroup: AgeGroup.child,
        ));
      }

      if (!mounted) return;
      context.go('/onboarding/people');
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
      appBar: AppBar(title: const Text('Add Children')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Who are the children in your household?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This helps Nabbo know who messages affect.',
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
                      labelText: 'Child name',
                      hintText: 'e.g. Adam',
                    ),
                    onSubmitted: (_) => _addChild(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addChild,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Children list
            Expanded(
              child: ListView.builder(
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(_children[index][0].toUpperCase()),
                      ),
                      title: Text(_children[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeChild(index),
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
          ],
        ),
      ),
    );
  }
}
