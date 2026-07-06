import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepTeal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Abstract basket shape
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.mistBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.mistBlue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.all_inbox_rounded,
                        size: 36,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Headline
              Text(
                "Don't remember it.\nNabbo it.",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Subtext
              Text(
                'Share school emails, WhatsApp messages, screenshots, '
                'and voice notes. Nabbo turns them into actions.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textOnDarkMuted,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // CTA
              FilledButton(
                onPressed: () => context.go('/onboarding/household'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.limeAccent,
                  foregroundColor: AppColors.deepTeal,
                ),
                child: const Text('Start with your household'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
