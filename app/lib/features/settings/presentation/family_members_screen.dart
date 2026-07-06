import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/data/models/family_member_model.dart';
import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  return ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
});

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: householdAsync.when(
        data: (household) {
          if (household == null) {
            return const Center(child: Text('No household found'));
          }
          return _MembersList(householdId: household.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(ref: ref),
    );
  }
}

class _MembersList extends ConsumerWidget {
  final String householdId;

  const _MembersList({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersStream = ref
        .read(householdRepositoryProvider)
        .watchFamilyMembers(householdId);

    return StreamBuilder<List<FamilyMemberModel>>(
      stream: membersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No family members yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add children and other household members.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return _MemberCard(
              member: member,
              onEdit: () => _showEditMemberDialog(context, ref, member),
              onDelete: () => _confirmDelete(context, ref, member),
            );
          },
        );
      },
    );
  }

  void _showEditMemberDialog(
      BuildContext context, WidgetRef ref, FamilyMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => _EditMemberDialog(ref: ref, member: member),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, FamilyMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.name} from the household?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(householdRepositoryProvider);
              await repo.deleteFamilyMember(member.householdId, member.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMemberModel member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  String get _roleLabel => switch (member.role) {
        MemberRole.primaryParent => 'Primary parent',
        MemberRole.secondaryParent => 'Second parent',
        MemberRole.child => 'Child',
        MemberRole.caregiver => 'Caregiver',
        MemberRole.grandparent => 'Grandparent',
        MemberRole.babysitter => 'Babysitter',
        MemberRole.other => 'Other',
      };

  Color _roleColor(BuildContext context) => switch (member.role) {
        MemberRole.primaryParent => Theme.of(context).colorScheme.primary,
        MemberRole.secondaryParent => Theme.of(context).colorScheme.tertiary,
        MemberRole.child => Theme.of(context).colorScheme.secondary,
        _ => Theme.of(context).colorScheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(context).withValues(alpha: 0.15),
          child: Text(
            member.name[0].toUpperCase(),
            style: TextStyle(
              color: _roleColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member.name),
        subtitle: Text(_roleLabel),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Remove',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _AddMemberDialog({required this.ref});

  @override
  ConsumerState<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<_AddMemberDialog> {
  final _nameController = TextEditingController();
  MemberRole _role = MemberRole.child;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final repo = widget.ref.read(householdRepositoryProvider);
      final household = await repo.getHouseholdByUserId(userId);

      if (household == null) throw Exception('Household not found');

      await repo.addFamilyMember(FamilyMemberModel(
        id: '',
        householdId: household.id,
        name: name,
        role: _role,
        ageGroup: _role == MemberRole.child ? AgeGroup.child : AgeGroup.adult,
      ));

      if (mounted) Navigator.pop(context);
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
    return AlertDialog(
      title: const Text('Add Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Adam',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberRole>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: MemberRole.values
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(_roleName(r)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  String _roleName(MemberRole role) => switch (role) {
        MemberRole.primaryParent => 'Primary parent',
        MemberRole.secondaryParent => 'Second parent',
        MemberRole.child => 'Child',
        MemberRole.caregiver => 'Caregiver',
        MemberRole.grandparent => 'Grandparent',
        MemberRole.babysitter => 'Babysitter',
        MemberRole.other => 'Other',
      };
}

class _EditMemberDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final FamilyMemberModel member;

  const _EditMemberDialog({required this.ref, required this.member});

  @override
  ConsumerState<_EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends ConsumerState<_EditMemberDialog> {
  late final TextEditingController _nameController;
  late MemberRole _role;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _role = widget.member.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final repo = widget.ref.read(householdRepositoryProvider);
      await repo.updateFamilyMember(widget.member.copyWith(
        name: name,
        role: _role,
      ));

      if (mounted) Navigator.pop(context);
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
    return AlertDialog(
      title: const Text('Edit Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberRole>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: MemberRole.values
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(_roleName(r)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _roleName(MemberRole role) => switch (role) {
        MemberRole.primaryParent => 'Primary parent',
        MemberRole.secondaryParent => 'Second parent',
        MemberRole.child => 'Child',
        MemberRole.caregiver => 'Caregiver',
        MemberRole.grandparent => 'Grandparent',
        MemberRole.babysitter => 'Babysitter',
        MemberRole.other => 'Other',
      };
}
