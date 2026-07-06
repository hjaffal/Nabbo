import 'package:flutter/material.dart';

/// Nabbo design tokens - Soft, warm, modern color palette
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFFF8F4F1);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF1ECE8);
  static const Color surfaceWarm = Color(0xFFFAF7F3);

  // Primary
  static const Color primary = Color(0xFF7B61D9);
  static const Color primaryLight = Color(0xFFE8DDFB);
  static const Color primaryDark = Color(0xFF5A3FB8);

  // Accent colors (pastels)
  static const Color warmYellow = Color(0xFFF7D24A);
  static const Color softGreen = Color(0xFF65CF8C);
  static const Color softCoral = Color(0xFFF96B6B);
  static const Color softBlue = Color(0xFF9CDDF0);
  static const Color lavender = Color(0xFFE8DDFB);

  // Pastel backgrounds for cards
  static const Color yellowLight = Color(0xFFFFF8E1);
  static const Color greenLight = Color(0xFFE8F8EE);
  static const Color coralLight = Color(0xFFFEECEC);
  static const Color blueLight = Color(0xFFE8F7FC);
  static const Color lavenderLight = Color(0xFFF3EFFE);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF8A8580);
  static const Color textMuted = Color(0xFFB5AFA8);

  // Borders & Shadows
  static const Color border = Color(0xFFEEE8E2);
  static const Color shadow = Color(0x0A000000);

  // Semantic
  static const Color success = Color(0xFF65CF8C);
  static const Color warning = Color(0xFFF7D24A);
  static const Color error = Color(0xFFF96B6B);
  static const Color info = Color(0xFF9CDDF0);

  // Confidence labels
  static const Color confidenceClear = Color(0xFF65CF8C);
  static const Color confidenceCheck = Color(0xFFF7D24A);
  static const Color confidenceMissing = Color(0xFFF96B6B);
  static const Color confidenceSuggested = Color(0xFF7B61D9);

  // Category colors for item type cards
  static const Color categoryEvent = Color(0xFFE8DDFB);
  static const Color categoryTask = Color(0xFFFFF8E1);
  static const Color categoryDeadline = Color(0xFFFEECEC);
  static const Color categoryPayment = Color(0xFFE8F7FC);
  static const Color categoryForm = Color(0xFFF3EFFE);
  static const Color categoryChecklist = Color(0xFFE8F8EE);
  static const Color categoryChange = Color(0xFFFFF8E1);
  static const Color categoryRisk = Color(0xFFFEECEC);

  // Aliases for backward compatibility with existing screens
  static const Color deepTeal = Color(0xFF7B61D9); // maps to primary
  static const Color vibrantTeal = Color(0xFF7B61D9);
  static const Color limeAccent = Color(0xFF65CF8C);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color coralAlert = Color(0xFFF96B6B);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFE8DDFB);
  static const Color lavenderCard = Color(0xFFF3EFFE);
  static const Color skyBlueCard = Color(0xFFE8F7FC);
  static const Color mintCard = Color(0xFFE8F8EE);
  static const Color peachCard = Color(0xFFFEECEC);
  static const Color sunshineCard = Color(0xFFFFF8E1);
  static const Color blushPink = Color(0xFFFEECEC);
}
