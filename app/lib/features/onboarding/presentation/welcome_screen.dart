import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/animations/animations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _glowController;

  // Staggered animations
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _subtextOpacity;
  late final Animation<Offset> _subtextSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    // Main entrance timeline
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Floating shapes continuous animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // Glow pulse on the logo
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Logo: 0.0 - 0.35
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Headline: 0.2 - 0.55
    _headlineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
    ));

    // Subtext: 0.35 - 0.65
    _subtextOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _subtextSlide = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
    ));

    // Button: 0.55 - 0.85
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepTeal,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated floating background shapes
            ..._buildFloatingShapes(),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Animated logo with glow
                  AnimatedBuilder(
                    animation: Listenable.merge([_entranceController, _glowController]),
                    builder: (context, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _buildLogo(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Headline
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) => Opacity(
                      opacity: _headlineOpacity.value,
                      child: Transform.translate(
                        offset: _headlineSlide.value,
                        child: child,
                      ),
                    ),
                    child: Text(
                      "Don't remember it.\nNabbo it.",
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtext
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) => Opacity(
                      opacity: _subtextOpacity.value,
                      child: Transform.translate(
                        offset: _subtextSlide.value,
                        child: child,
                      ),
                    ),
                    child: Text(
                      'Share school emails, WhatsApp messages, screenshots, '
                      'and voice notes. Nabbo turns them into actions.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textOnDarkMuted,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // CTA button
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) => Opacity(
                      opacity: _buttonOpacity.value,
                      child: Transform.translate(
                        offset: _buttonSlide.value,
                        child: child,
                      ),
                    ),
                    child: FilledButton(
                      onPressed: () => context.go('/onboarding/household'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.limeAccent,
                        foregroundColor: AppColors.deepTeal,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Start with your household'),
                    ),
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
