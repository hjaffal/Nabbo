import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class FirstCaptureScreen extends StatelessWidget {
  const FirstCaptureScreen({super.key});

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
              "You're all set!",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try sending something to Nabbo now.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            _CaptureOptionCard(
              icon: Icons.share_outlined,
              title: 'Share something',
              description: 'Share a message or screenshot from another app',
              color: AppColors.mintCard,
              onTap: () => context.go('/today'),
            ),
            const SizedBox(height: 12),
            _CaptureOptionCard(
              icon: Icons.email_outlined,
              title: 'Forward an email',
              description: 'Forward a school or activity email to your Nabbo address',
              color: AppColors.skyBlueCard,
              onTap: () => context.go('/today'),
            ),
            const SizedBox(height: 12),
            _CaptureOptionCard(
              icon: Icons.edit_note_outlined,
              title: 'Type a quick note',
              description: 'e.g. "Adam has football Friday at 18:30"',
              color: AppColors.lavenderCard,
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
  final Color color;
  final VoidCallback onTap;

  const _CaptureOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.deepTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.deepTeal, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.deepTeal,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.deepTeal.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.deepTeal,
            ),
          ],
        ),
      ),
    );
  }
}
