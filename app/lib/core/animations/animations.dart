import 'package:flutter/material.dart';

/// Reusable animation curves and durations for the Nabbo design system.
class NabboAnimations {
  NabboAnimations._();

  // ─── Durations ─────────────────────────────────────────────────────────────
  static const Duration fastest = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration entrance = Duration(milliseconds: 800);
  static const Duration stagger = Duration(milliseconds: 100);

  // ─── Curves ────────────────────────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve snappyCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.easeOutQuart;
}
