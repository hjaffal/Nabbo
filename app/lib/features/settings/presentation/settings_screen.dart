import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';
import 'edit_household_screen.dart';
import 'family_members_screen.dart';
import 'notification_settings_screen.dart';
import 'delete_account_screen.dart';

final _householdProvider = FutureProvider<HouseholdModel?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;
  final repo = ref.read(householdRepositoryProvider);
  return repo.getHouseholdByUserId(userId);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(_householdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Household section
          householdAsync.when(
            data: (household) {
              if (household == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Household'),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(household.name),
                    subtitle: Text('${household.timezone} • ${household.language.toUpperCase()}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditHouseholdScreen(),
                        ),
                      );
                      ref.invalidate(_householdProvider);
                    },
                  ),
                  if (household.emailAlias != null)
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(household.emailAlias!),
                      subtitle: const Text('Nabbo email alias'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: household.emailAlias!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied!')),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),

          const Divider(),
          _SectionHeader(title: 'Family'),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Family members'),
            subtitle: const Text('Add, edit, or remove members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FamilyMembersScreen(),
              ),
            ),
          ),

          const Divider(),
          _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification settings'),
            subtitle: const Text('Alerts, briefs, quiet hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),

          const Divider(),
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: Text(
                FirebaseAuth.instance.currentUser?.displayName ?? 'User'),
            subtitle:
                Text(FirebaseAuth.instance.currentUser?.email ?? ''),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
