import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/data/models/household_model.dart';
import '../../household/data/repositories/household_repository.dart';

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
                    subtitle: const Text('Household name'),
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
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(household.language.toUpperCase()),
                    subtitle: const Text('Language'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(household.timezone),
                    subtitle: const Text('Timezone'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),

          const Divider(),
          _SectionHeader(title: 'Family Members'),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Manage family members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to family members management
            },
          ),

          const Divider(),
          _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
            },
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
