import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Who are the children?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This helps Nabbo know who messages affect.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Input row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Child name',
                        hintText: 'e.g. Adam',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addChild(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addChild,
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
            ),
            const SizedBox(height: 16),

            // Children chips
            Expanded(
              child: _children.isEmpty
                  ? Center(
                      child: Text(
                        'No children added yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_children.length, (index) {
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: AppColors.lavenderCard,
                            child: Text(
                              _children[index][0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          label: Text(_children[index]),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeChild(index),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        );
                      }),
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
          ],
        ),
      ),
    );
  }
}
