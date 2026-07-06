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
        child: Stack(
          children: [
            // Floating colorful shapes in background
            Positioned(
              top: 60,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.lavenderCard.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 120,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.skyBlueCard.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.mintCard.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Positioned(
              bottom: 280,
              right: 40,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.peachCard.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 250,
              left: 50,
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.blushPink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Abstract basket icon with colorful ring
                  Center(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.skyBlueCard.withValues(alpha: 0.3),
                            AppColors.lavenderCard.withValues(alpha: 0.2),
                            AppColors.mintCard.withValues(alpha: 0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.limeAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.all_inbox_rounded,
                            size: 38,
                            color: AppColors.limeAccent,
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
          ],
        ),
      ),
    );
  }
}
