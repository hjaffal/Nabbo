import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/data/repositories/household_repository.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_confirmController.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Please type DELETE to confirm.');
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userId = user.uid;
      final repo = ref.read(householdRepositoryProvider);
      final household = await repo.getHouseholdByUserId(userId);

      // Delete household data if exists
      if (household != null) {
        final db = FirebaseFirestore.instance;
        final householdRef = db.collection('households').doc(household.id);

        // Delete subcollections
        final subcollections = [
          'members',
          'sourceMessages',
          'extractedItems',
          'events',
          'tasks',
          'deadlines',
          'requiredItems',
          'checklists',
          'forms',
          'payments',
          'changes',
          'risks',
          'reminders',
          'routines',
        ];

        for (final sub in subcollections) {
          final docs = await householdRef.collection(sub).get();
          for (final doc in docs.docs) {
            await doc.reference.delete();
          }
        }

        // Delete household document
        await householdRef.delete();
      }

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() => _error =
            'For security, please sign out and sign back in before deleting your account.');
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This action cannot be undone',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting your account will permanently remove all your household data, '
                    'source messages, extracted items, and settings.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Type DELETE to confirm:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                hintText: 'DELETE',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isDeleting ? null : _deleteAccount,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete My Account'),
            ),
          ],
        ),
      ),
    );
  }
}
