import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SharingExplanationScreen extends StatelessWidget {
  const SharingExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Share')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share anything to Nabbo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you see a message, screenshot, PDF, or note you don't want to remember — share it to Nabbo.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            _ShareStep(
              icon: Icons.message_outlined,
              title: 'WhatsApp messages',
              description: 'Long-press a message → Share → Nabbo',
            ),
            const SizedBox(height: 16),
            _ShareStep(
              icon: Icons.screenshot_outlined,
              title: 'Screenshots',
              description: 'Take a screenshot → Share → Nabbo',
            ),
            const SizedBox(height: 16),
            _ShareStep(
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDFs & documents',
              description: 'Open a file → Share → Nabbo',
            ),
            const SizedBox(height: 16),
            _ShareStep(
              icon: Icons.email_outlined,
              title: 'Emails',
              description: 'Forward to your Nabbo email address',
            ),
            const SizedBox(height: 16),
            _ShareStep(
              icon: Icons.mic_outlined,
              title: 'Voice notes',
              description: 'Open Nabbo and speak a quick reminder',
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

class _ShareStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ShareStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 22,
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
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
