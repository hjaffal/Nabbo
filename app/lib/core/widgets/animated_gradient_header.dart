import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A modern header with animated gradient background and glassmorphism elements.
class AnimatedGradientHeader extends StatefulWidget {
  final String greeting;
  final String subtitle;
  final Widget? statusPill;
  final VoidCallback? onNotificationTap;

  const AnimatedGradientHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.statusPill,
    this.onNotificationTap,
  });

  @override
  State<AnimatedGradientHeader> createState() => _AnimatedGradientHeaderState();
}

class _AnimatedGradientHeaderState extends State<AnimatedGradientHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final t = _gradientController.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(AppColors.deepTeal, const Color(0xFF1A5C5C), t)!,
                Color.lerp(const Color(0xFF1A5C5C), const Color(0xFF0E4040), t)!,
              ],
              begin: Alignment(-1 + t * 0.5, -1),
              end: Alignment(1 - t * 0.3, 1),
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepTeal.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.greeting,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textOnDarkMuted,
                          ),
                    ),
                  ],
                ),
              ),
              // Glassmorphic notification button
              GestureDetector(
                onTap: widget.onNotificationTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textOnDark,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.statusPill != null) ...[
            const SizedBox(height: 16),
            widget.statusPill!,
          ],
        ],
      ),
    );
  }
}

/// A status pill with a subtle shimmer/glow animation.
class AnimatedStatusPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const AnimatedStatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor = AppColors.limeAccent,
    this.foregroundColor = AppColors.deepTeal,
  });

  @override
  State<AnimatedStatusPill> createState() => _AnimatedStatusPillState();
}

class _AnimatedStatusPillState extends State<AnimatedStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.foregroundColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
