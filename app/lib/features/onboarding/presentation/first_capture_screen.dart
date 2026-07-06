import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FirstCaptureScreen extends StatelessWidget {
  const FirstCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get Started')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "You're all set!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try sending something to Nabbo now. Choose how you want to start:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // Option cards
            _CaptureOptionCard(
              icon: Icons.share_outlined,
              title: 'Share something',
              description: 'Share a message or screenshot from another app',
              onTap: () => context.go('/today'),
            ),
            const SizedBox(height: 12),
            _CaptureOptionCard(
              icon: Icons.email_outlined,
              title: 'Forward an email',
              description: 'Forward a school or activity email to your Nabbo address',
              onTap: () => context.go('/today'),
            ),
            const SizedBox(height: 12),
            _CaptureOptionCard(
              icon: Icons.edit_note_outlined,
              title: 'Type a quick note',
              description: 'e.g. "Adam has football Friday at 18:30"',
              onTap: () => context.go('/today'),
            ),

            const Spacer(),
            TextButton(
              onPressed: () => context.go('/today'),
              child: const Text("I'll do this later"),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CaptureOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
