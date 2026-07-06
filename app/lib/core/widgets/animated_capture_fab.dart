import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// A modern expandable FAB with radial menu animation.
/// Tap to expand into capture options with smooth spring animations.
class AnimatedCaptureFab extends StatefulWidget {
  final VoidCallback onTextCapture;
  final VoidCallback onVoiceCapture;
  final VoidCallback onImageCapture;

  const AnimatedCaptureFab({
    super.key,
    required this.onTextCapture,
    required this.onVoiceCapture,
    required this.onImageCapture,
  });

  @override
  State<AnimatedCaptureFab> createState() => _AnimatedCaptureFabState();
}

class _AnimatedCaptureFabState extends State<AnimatedCaptureFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _selectOption(VoidCallback action) {
    _toggle();
    Future.delayed(const Duration(milliseconds: 150), action);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 260,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Backdrop blur when open
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggle,
                child: const SizedBox.expand(),
              ),
            ),

          // Mini FABs
          _buildMiniFab(
            index: 0,
            icon: Icons.image_rounded,
            label: 'Photo',
            color: AppColors.lavenderCard,
            onTap: () => _selectOption(widget.onImageCapture),
          ),
          _buildMiniFab(
            index: 1,
            icon: Icons.mic_rounded,
            label: 'Voice',
            color: AppColors.peachCard,
            onTap: () => _selectOption(widget.onVoiceCapture),
          ),
          _buildMiniFab(
            index: 2,
            icon: Icons.edit_note_rounded,
            label: 'Text',
            color: AppColors.mintCard,
            onTap: () => _selectOption(widget.onTextCapture),
          ),

          // Main FAB
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final rotation = Tween<double>(begin: 0, end: 0.125)
                    .animate(CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutCubic,
                ));
                return Transform.rotate(
                  angle: rotation.value * math.pi * 2,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.vibrantTeal, Color(0xFF15918E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.vibrantTeal.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      _isOpen ? Icons.close : Icons.add,
                      key: ValueKey(_isOpen),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFab({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Stagger the animation for each mini fab
    final intervalStart = index * 0.1;
    final intervalEnd = 0.6 + index * 0.1;

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutBack),
    );

    // Position: stack vertically above the main FAB
    final bottomOffset = 72.0 + (index * 58.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          bottom: bottomOffset * animation.value,
          right: 4,
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: 0.5 + 0.5 * animation.value,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.deepTeal,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Mini FAB circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.deepTeal, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
