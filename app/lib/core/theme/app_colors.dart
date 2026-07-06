import 'package:flutter/material.dart';

/// Nabbo design tokens — Fresh, clean, modern color palette
/// Inspired by health/wellness app design: white backgrounds, bold purple accents,
/// colorful emoji-style icons, and high-contrast text (black or white only).
class AppColors {
  AppColors._();

  // Backgrounds — clean and bright
  static const Color background = Color(0xFFF9F9FB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4F3F8);
  static const Color surfaceWarm = Color(0xFFFAF9FE);

  // Primary — soft purple (matches the reference)
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFEDE8FF);
  static const Color primaryDark = Color(0xFF4A3ABF);
  static const Color primarySoft = Color(0xFFA393F5);

  // Accent colors — vivid and fresh
  static const Color warmYellow = Color(0xFFF5C842);
  static const Color softGreen = Color(0xFF4CD080);
  static const Color softCoral = Color(0xFFFF6B6B);
  static const Color softBlue = Color(0xFF74B9FF);
  static const Color lavender = Color(0xFFDDD6FE);
  static const Color orange = Color(0xFFFF9F43);
  static const Color pink = Color(0xFFFF7EB3);

  // Pastel backgrounds for emotion/category chips
  static const Color yellowLight = Color(0xFFFFF9E6);
  static const Color greenLight = Color(0xFFE8FBF0);
  static const Color coralLight = Color(0xFFFFF0F0);
  static const Color blueLight = Color(0xFFEDF6FF);
  static const Color lavenderLight = Color(0xFFF3EFFF);
  static const Color orangeLight = Color(0xFFFFF4E6);
  static const Color pinkLight = Color(0xFFFFF0F7);

  // Text — high contrast, either black or white
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF1A1A2E);

  // Borders & Shadows — subtle
  static const Color border = Color(0xFFEEEDF2);
  static const Color borderLight = Color(0xFFF5F4F8);
  static const Color shadow = Color(0x08000000);

  // Semantic
  static const Color success = Color(0xFF4CD080);
  static const Color warning = Color(0xFFF5C842);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF74B9FF);

  // Confidence labels
  static const Color confidenceClear = Color(0xFF4CD080);
  static const Color confidenceCheck = Color(0xFFF5C842);
  static const Color confidenceMissing = Color(0xFFFF6B6B);
  static const Color confidenceSuggested = Color(0xFF6C5CE7);

  // Category colors for cards (fresh vivid style)
  static const Color categoryEvent = Color(0xFFF3EFFF);
  static const Color categoryTask = Color(0xFFFFF9E6);
  static const Color categoryDeadline = Color(0xFFFFF0F0);
  static const Color categoryPayment = Color(0xFFEDF6FF);
  static const Color categoryForm = Color(0xFFF3EFFF);
  static const Color categoryChecklist = Color(0xFFE8FBF0);
  static const Color categoryChange = Color(0xFFFFF9E6);
  static const Color categoryRisk = Color(0xFFFFF0F0);

  // Chip/tag accent colors (for mood chips, status badges)
  static const Color chipPurple = Color(0xFF6C5CE7);
  static const Color chipYellow = Color(0xFFF5C842);
  static const Color chipGreen = Color(0xFF4CD080);
  static const Color chipCoral = Color(0xFFFF6B6B);
  static const Color chipBlue = Color(0xFF74B9FF);
  static const Color chipOrange = Color(0xFFFF9F43);
  static const Color chipPink = Color(0xFFFF7EB3);

  // Aliases for backward compatibility
  static const Color deepTeal = Color(0xFF6C5CE7); // maps to primary
  static const Color vibrantTeal = Color(0xFF6C5CE7);
  static const Color limeAccent = Color(0xFF4CD080);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color coralAlert = Color(0xFFFF6B6B);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFE8E4FF);
  static const Color lavenderCard = Color(0xFFF3EFFF);
  static const Color skyBlueCard = Color(0xFFEDF6FF);
  static const Color mintCard = Color(0xFFE8FBF0);
  static const Color peachCard = Color(0xFFFFF0F0);
  static const Color sunshineCard = Color(0xFFFFF9E6);
  static const Color blushPink = Color(0xFFFFF0F7);
}
