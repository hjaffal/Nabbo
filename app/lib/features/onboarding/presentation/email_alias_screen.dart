import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/data/repositories/household_repository.dart';

class EmailAliasScreen extends ConsumerStatefulWidget {
  const EmailAliasScreen({super.key});

  @override
  ConsumerState<EmailAliasScreen> createState() => _EmailAliasScreenState();
}

class _EmailAliasScreenState extends ConsumerState<EmailAliasScreen> {
  String? _emailAlias;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadAlias();
  }

  Future<void> _loadAlias() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final repo = ref.read(householdRepositoryProvider);
    final household = await repo.getHouseholdByUserId(userId);

    if (household != null && mounted) {
      // Generate alias from household name
      final alias = household.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .substring(0, household.name.length.clamp(0, 20));
      final emailAlias = '$alias@nabbo.app';

      // Save to household
      await repo.updateHousehold(household.copyWith(emailAlias: emailAlias));

      setState(() => _emailAlias = emailAlias);
    }
  }

  void _copyAlias() {
    if (_emailAlias == null) return;
    Clipboard.setData(ClipboardData(text: _emailAlias!));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Nabbo Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Forward emails to Nabbo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Forward school emails and activity updates to this address. '
              'Nabbo will read them and extract actions, deadlines, and reminders.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // Email alias display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _emailAlias ?? 'Loading...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _copyAlias,
                    icon: Icon(_copied ? Icons.check : Icons.copy),
                    label: Text(_copied ? 'Copied!' : 'Copy address'),
                  ),
                ],
              ),
            ),
            const Spacer(),

            FilledButton(
              onPressed: () => context.go('/onboarding/first-capture'),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
