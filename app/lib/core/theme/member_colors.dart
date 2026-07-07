import 'dart:math';

import 'package:flutter/material.dart';

/// Predefined palette of soft, warm colors for family members.
/// Used throughout the app to visually identify members in cards and chips.
class MemberColors {
  MemberColors._();

  static const List<String> palette = [
    '#7B61D9', // purple
    '#FF6B6B', // coral
    '#4ECDC4', // teal
    '#FFB347', // orange
    '#77DD77', // green
    '#6BB5FF', // blue
    '#FF85A2', // pink
    '#B19CD9', // lavender
  ];

  /// Returns a random color hex from the palette.
  static String randomColor() {
    return palette[Random().nextInt(palette.length)];
  }

  /// Parses a hex color string to a Flutter Color.
  /// Falls back to primary purple if invalid.
  static Color fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF7B61D9);
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF7B61D9);
    }
  }
}
