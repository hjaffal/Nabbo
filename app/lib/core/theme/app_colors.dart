import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary ───────────────────────────────────────────────────────────────
  /// Trust color. Headers, navigation, primary surfaces, app icon.
  static const Color deepTeal = Color(0xFF123F49);

  /// Main app screen background. Calm, light, not harsh white.
  static const Color iceBackground = Color(0xFFEAF5F5);

  /// Outer backgrounds, onboarding surfaces, large calm panels.
  static const Color mistBlue = Color(0xFFA8C9CF);

  // ─── Card Colors ───────────────────────────────────────────────────────────
  /// Review items, child cards, non-urgent action groups.
  static const Color lavenderCard = Color(0xFFD8C8F4);

  /// Completed, ready, packed, low-risk states.
  static const Color mintCard = Color(0xFFD6F4D2);

  /// Summaries, daily brief, next-action information.
  static const Color skyBlueCard = Color(0xFFAEE3F0);

  /// Gentle attention, snoozed items, review states.
  static const Color blushPink = Color(0xFFF1C4E8);

  // ─── Accents ───────────────────────────────────────────────────────────────
  /// Tiny highlight only: selected date, active underline, progress signal.
  static const Color limeAccent = Color(0xFFC9F83F);

  /// Real attention only: changes, risks, owner missing, overdue.
  static const Color coralAlert = Color(0xFFFF6B6B);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF123F49);
  static const Color textSecondary = Color(0xFF5A7A82);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFCDE5E9);

  // ─── Utility ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD4E5E8);
  static const Color divider = Color(0xFFE0ECED);
  static const Color shadow = Color(0x0A000000);
}
