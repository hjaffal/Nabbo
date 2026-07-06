import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
      final alias = household.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .substring(0, household.name.length.clamp(0, 20));
      final emailAlias = '$alias@nabbo.app';

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
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Nabbo email',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Forward school emails and activity updates to this address. '
              'Nabbo will extract actions, deadlines, and reminders.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),

            // Email display card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.skyBlueCard,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      size: 28,
                      color: AppColors.deepTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _emailAlias ?? 'Loading...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepTeal,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _copyAlias,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy,
                      size: 18,
                    ),
                    label: Text(_copied ? 'Copied!' : 'Copy address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepTeal,
                      side: const BorderSide(color: AppColors.deepTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            FilledButton(
              onPressed: () => context.go('/onboarding/sharing'),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
