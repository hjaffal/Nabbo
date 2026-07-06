import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary ───────────────────────────────────────────────────────────────
  /// Trust color. Headers, navigation, primary surfaces, app icon.
  static const Color deepTeal = Color(0xFF0E3740);

  /// Main app screen background — slightly warmer, less clinical.
  static const Color iceBackground = Color(0xFFF0F7F7);

  /// Outer backgrounds, onboarding surfaces, large calm panels.
  static const Color mistBlue = Color(0xFF8FBFC8);

  // ─── Card Colors (more saturated) ─────────────────────────────────────────
  /// Review items, child cards, non-urgent action groups.
  static const Color lavenderCard = Color(0xFFCBB3F5);

  /// Completed, ready, packed, low-risk states.
  static const Color mintCard = Color(0xFFB0EEAC);

  /// Summaries, daily brief, next-action information.
  static const Color skyBlueCard = Color(0xFF8ED8F0);

  /// Gentle attention, snoozed items, review states.
  static const Color blushPink = Color(0xFFF5A8DC);

  /// Warm peach for family/household related cards.
  static const Color peachCard = Color(0xFFFFCDA8);

  /// Sunshine yellow for checklist/packed states.
  static const Color sunshineCard = Color(0xFFFFF0A0);

  // ─── Accents ───────────────────────────────────────────────────────────────
  /// Active selection, progress signal — more vivid.
  static const Color limeAccent = Color(0xFFB8F230);

  /// Real attention only: changes, risks, owner missing, overdue.
  static const Color coralAlert = Color(0xFFFF5A5A);

  /// Vibrant teal for secondary CTAs and active nav.
  static const Color vibrantTeal = Color(0xFF1BA3A3);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0E3740);
  static const Color textSecondary = Color(0xFF4D7780);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFBFE0E6);

  // ─── Utility ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFCCE0E3);
  static const Color divider = Color(0xFFDCEEF0);
  static const Color shadow = Color(0x12000000);
}
