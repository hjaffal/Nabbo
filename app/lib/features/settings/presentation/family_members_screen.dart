import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/member_colors.dart';
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
                Icon(Icons.people_outline, size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No family members yet',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Add children and other household members.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
              onEdit: () => _showEditDialog(context, ref, member),
              onDelete: () => _confirmDelete(context, ref, member),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, FamilyMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => _EditMemberDialog(ref: ref, member: member),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FamilyMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.name} from the household?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(householdRepositoryProvider);
              await repo.deleteFamilyMember(member.householdId, member.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
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

  const _MemberCard({required this.member, required this.onEdit, required this.onDelete});

  String get _roleLabel => switch (member.role) {
        MemberRole.primaryParent => 'Primary parent',
        MemberRole.secondaryParent => 'Second parent',
        MemberRole.child => 'Child',
        MemberRole.caregiver => 'Caregiver',
        MemberRole.grandparent => 'Grandparent',
        MemberRole.babysitter => 'Babysitter',
        MemberRole.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    final memberColor = MemberColors.fromHex(member.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: member.photoUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(member.photoUrl!))
            : CircleAvatar(
                backgroundColor: memberColor.withValues(alpha: 0.15),
                child: Text(member.name[0].toUpperCase(),
                    style: TextStyle(color: memberColor, fontWeight: FontWeight.bold)),
              ),
        title: Row(
          children: [
            Text(member.name),
            const SizedBox(width: 8),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: memberColor, shape: BoxShape.circle),
            ),
          ],
        ),
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
              child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Member Dialog ---

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
        id: '', householdId: household.id, name: name, role: _role,
        ageGroup: _role == MemberRole.child ? AgeGroup.child : AgeGroup.adult,
        color: MemberColors.randomColor(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextField(controller: _nameController, autofocus: true,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Adam')),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberRole>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: MemberRole.values.map((r) => DropdownMenuItem(value: r, child: Text(_roleName(r)))).toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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

// --- Edit Member Dialog with Photo Upload ---

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
  late String _selectedColor;
  String? _photoUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _role = widget.member.role;
    _selectedColor = widget.member.color ?? MemberColors.randomColor();
    _photoUrl = widget.member.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.member.id}.jpg';
      final storagePath = 'households/${widget.member.householdId}/members/$fileName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      await storageRef.putFile(File(image.path));
      final url = await storageRef.getDownloadURL();
      setState(() { _photoUrl = url; _isUploading = false; });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final repo = widget.ref.read(householdRepositoryProvider);
      await repo.updateFamilyMember(widget.member.copyWith(name: name, role: _role, photoUrl: _photoUrl, color: _selectedColor));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          // Photo picker
          GestureDetector(
            onTap: _isUploading ? null : _pickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null
                      ? Text(widget.member.name[0].toUpperCase(), style: const TextStyle(fontSize: 28))
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 16),
          DropdownButtonFormField<MemberRole>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: MemberRole.values.map((r) => DropdownMenuItem(value: r, child: Text(_roleName(r)))).toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 16),
          // Color picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Color', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MemberColors.palette.map((hex) {
                  final color = MemberColors.fromHex(hex);
                  final isSelected = hex == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
