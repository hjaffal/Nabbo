import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/animations/animations.dart';
import '../../../core/animations/fade_slide_transition.dart';
import '../../../core/animations/scale_fade_in.dart';
import '../../../core/animations/pulse_animation.dart';

class ReviewInboxScreen extends ConsumerStatefulWidget {
  const ReviewInboxScreen({super.key});

  @override
  ConsumerState<ReviewInboxScreen> createState() => _ReviewInboxScreenState();
}

class _ReviewInboxScreenState extends ConsumerState<ReviewInboxScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Animated gradient header
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _headerController,
                builder: (context, child) {
                  final opacity = CurvedAnimation(
                    parent: _headerController,
                    curve: const Interval(0, 0.6, curve: Curves.easeOut),
                  ).value;
                  final slide = Tween<Offset>(
                    begin: const Offset(0, -20),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _headerController,
                    curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
                  )).value;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: slide,
                      child: child,
                    ),
                  );
                },
                child: _buildHeader(context),
              ),
            ),
            // Content
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _AnimatedEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lavenderCard,
            AppColors.blushPink.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavenderCard.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Review',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              // Badge count (animated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.deepTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '0 items',
                  style: TextStyle(
                    color: AppColors.deepTeal.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Items extracted from your messages appear here for review.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepTeal.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

/// Beautiful animated empty state with staggered elements.
class _AnimatedEmptyState extends StatefulWidget {
  const _AnimatedEmptyState();

  @override
  State<_AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<_AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated floating circles
            ScaleFadeIn(
              delay: const Duration(milliseconds: 300),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 5 + t * 6,
                          top: 15 - t * 4,
                          child: _Orb(
                            size: 55,
                            color: AppColors.skyBlueCard,
                          ),
                        ),
                        Positioned(
                          right: 5 - t * 3,
                          top: 5 + t * 8,
                          child: _Orb(
                            size: 45,
                            color: AppColors.mintCard,
                          ),
                        ),
                        Positioned(
                          left: 25 + t * 4,
                          bottom: 5 + t * 5,
                          child: _Orb(
                            size: 50,
                            color: AppColors.peachCard,
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.deepTeal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.inbox_outlined,
                              size: 24,
                              color: AppColors.deepTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            FadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: Text(
                'Nothing to review yet.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: const Duration(milliseconds: 650),
              child: Text(
                'Share a message, forward an email, or type a quick note.\nNabbo will extract what matters.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
