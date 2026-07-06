import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A continuously floating/pulsing shape for ambient background decoration.
/// Creates gentle motion that makes the app feel alive without being distracting.
class FloatingBubble extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double floatDistance;
  final double rotationDegrees;

  const FloatingBubble({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
    this.floatDistance = 8.0,
    this.rotationDegrees = 3.0,
  });

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.floatDistance * value),
          child: Transform.rotate(
            angle: (widget.rotationDegrees * math.pi / 180) *
                (value - 0.5) *
                2,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
