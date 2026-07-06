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

  Widget _buildLogo() {
    return Center(
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowValue = _glowController.value;
          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.limeAccent.withValues(alpha: 0.15 + glowValue * 0.1),
                  AppColors.skyBlueCard.withValues(alpha: 0.08 + glowValue * 0.05),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.limeAccent.withValues(alpha: 0.1 + glowValue * 0.08),
                  blurRadius: 40 + glowValue * 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.limeAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.all_inbox_rounded,
                  size: 40,
                  color: AppColors.limeAccent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingShapes() {
    return [
      _AnimatedShape(
        controller: _floatController,
        top: 60,
        left: -30,
        size: 100,
        color: AppColors.lavenderCard.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        phaseOffset: 0.0,
        floatDistance: 12,
      ),
      _AnimatedShape(
        controller: _floatController,
        top: 130,
        right: -20,
        size: 80,
        color: AppColors.skyBlueCard.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        phaseOffset: 0.3,
        floatDistance: 8,
      ),
      _AnimatedShape(
        controller: _floatController,
        bottom: 200,
        left: 30,
        size: 60,
        borderRadius: 18,
        color: AppColors.mintCard.withValues(alpha: 0.10),
        phaseOffset: 0.6,
        floatDistance: 10,
      ),
      _AnimatedShape(
        controller: _floatController,
        bottom: 300,
        right: 40,
        size: 50,
        color: AppColors.peachCard.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        phaseOffset: 0.15,
        floatDistance: 14,
      ),
      _AnimatedShape(
        controller: _floatController,
        top: 260,
        left: 50,
        size: 40,
        borderRadius: 12,
        color: AppColors.blushPink.withValues(alpha: 0.10),
        phaseOffset: 0.45,
        floatDistance: 6,
      ),
      _AnimatedShape(
        controller: _floatController,
        top: 400,
        right: 60,
        size: 35,
        borderRadius: 10,
        color: AppColors.limeAccent.withValues(alpha: 0.08),
        phaseOffset: 0.75,
        floatDistance: 9,
      ),
    ];
  }
}

/// An animated floating decorative shape with phase offset for variety.
class _AnimatedShape extends StatelessWidget {
  final AnimationController controller;
  final double? top, bottom, left, right;
  final double size;
  final Color color;
  final BoxShape? shape;
  final double? borderRadius;
  final double phaseOffset;
  final double floatDistance;

  const _AnimatedShape({
    required this.controller,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    this.shape,
    this.borderRadius,
    required this.phaseOffset,
    required this.floatDistance,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Create offset phase for each shape
        final t = (controller.value + phaseOffset) % 1.0;
        final sinValue = math.sin(t * math.pi * 2);
        final cosValue = math.cos(t * math.pi * 2 * 0.7);

        return Positioned(
          top: top != null ? top! + sinValue * floatDistance : null,
          bottom: bottom != null ? bottom! + cosValue * floatDistance : null,
          left: left != null ? left! + cosValue * (floatDistance * 0.5) : null,
          right: right != null ? right! + sinValue * (floatDistance * 0.5) : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: shape ?? BoxShape.rectangle,
              borderRadius: shape == null || shape == BoxShape.rectangle
                  ? BorderRadius.circular(borderRadius ?? size / 4)
                  : null,
            ),
          ),
        );
      },
    );
  }
}
