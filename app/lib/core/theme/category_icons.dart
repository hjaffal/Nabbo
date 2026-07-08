import 'package:flutter/material.dart';
import '../../features/items/data/models/item_model.dart';
import 'app_colors.dart';

/// Maps item categories to icons and colors.
/// Categories are free-form strings from AI — this table handles known ones
/// with partial matching, and falls back to type-based icons for unknown ones.
class CategoryIcons {
  CategoryIcons._();

  static const _iconMap = <String, IconData>{
    'basketball': Icons.sports_basketball_rounded,
    'football': Icons.sports_soccer_rounded,
    'soccer': Icons.sports_soccer_rounded,
    'swimming': Icons.pool_rounded,
    'swim': Icons.pool_rounded,
    'tennis': Icons.sports_tennis_rounded,
    'volleyball': Icons.sports_volleyball_rounded,
    'baseball': Icons.sports_baseball_rounded,
    'rugby': Icons.sports_rugby_rounded,
    'cricket': Icons.sports_cricket_rounded,
    'golf': Icons.golf_course_rounded,
    'cycling': Icons.directions_bike_rounded,
    'bike': Icons.directions_bike_rounded,
    'running': Icons.directions_run_rounded,
    'gymnastics': Icons.accessibility_new_rounded,
    'martial arts': Icons.sports_martial_arts_rounded,
    'karate': Icons.sports_martial_arts_rounded,
    'judo': Icons.sports_martial_arts_rounded,
    'dance': Icons.music_note_rounded,
    'ballet': Icons.music_note_rounded,
    'music': Icons.music_note_rounded,
    'piano': Icons.piano_rounded,
    'guitar': Icons.music_note_rounded,
    'school': Icons.school_rounded,
    'school trip': Icons.directions_bus_rounded,
    'field trip': Icons.directions_bus_rounded,
    'homework': Icons.menu_book_rounded,
    'exam': Icons.quiz_rounded,
    'test': Icons.quiz_rounded,
    'dentist': Icons.medical_services_rounded,
    'doctor': Icons.local_hospital_rounded,
    'hospital': Icons.local_hospital_rounded,
    'vaccination': Icons.vaccines_rounded,
    'medical': Icons.medical_services_rounded,
    'birthday': Icons.cake_rounded,
    'party': Icons.celebration_rounded,
    'payment': Icons.payment_rounded,
    'form': Icons.description_rounded,
    'document': Icons.description_rounded,
    'pickup': Icons.directions_car_rounded,
    'drop-off': Icons.directions_car_rounded,
    'dropoff': Icons.directions_car_rounded,
    'travel': Icons.flight_rounded,
    'flight': Icons.flight_rounded,
    'vacation': Icons.beach_access_rounded,
    'holiday': Icons.beach_access_rounded,
    'hiking': Icons.hiking_rounded,
    'hike': Icons.hiking_rounded,
    'camping': Icons.nature_rounded,
    'cinema': Icons.movie_rounded,
    'movie': Icons.movie_rounded,
    'theater': Icons.theater_comedy_rounded,
    'theatre': Icons.theater_comedy_rounded,
    'meeting': Icons.groups_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'grocery': Icons.shopping_cart_rounded,
    'cooking': Icons.restaurant_rounded,
    'dinner': Icons.restaurant_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'breakfast': Icons.free_breakfast_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'appointment': Icons.event_rounded,
    'call': Icons.phone_rounded,
    'email': Icons.email_rounded,
    'park': Icons.park_rounded,
    'playground': Icons.park_rounded,
    'zoo': Icons.pets_rounded,
    'museum': Icons.museum_rounded,
    'library': Icons.local_library_rounded,
    'church': Icons.church_rounded,
    'sport': Icons.fitness_center_rounded,
    'training': Icons.fitness_center_rounded,
    'practice': Icons.fitness_center_rounded,
  };

  static const _colorMap = <String, Color>{
    'basketball': Color(0xFFFF9800),
    'football': Color(0xFF4CAF50),
    'soccer': Color(0xFF4CAF50),
    'swimming': Color(0xFF2196F3),
    'swim': Color(0xFF2196F3),
    'tennis': Color(0xFF8BC34A),
    'dance': Color(0xFFE91E63),
    'ballet': Color(0xFFE91E63),
    'music': Color(0xFF9C27B0),
    'piano': Color(0xFF9C27B0),
    'school': Color(0xFF3F51B5),
    'school trip': Color(0xFFFF9800),
    'field trip': Color(0xFFFF9800),
    'homework': Color(0xFF3F51B5),
    'dentist': Color(0xFF009688),
    'doctor': Color(0xFFF44336),
    'medical': Color(0xFF009688),
    'vaccination': Color(0xFF009688),
    'birthday': Color(0xFFE91E63),
    'party': Color(0xFFE91E63),
    'payment': Color(0xFF4CAF50),
    'form': Color(0xFF2196F3),
    'pickup': Color(0xFF607D8B),
    'drop-off': Color(0xFF607D8B),
    'travel': Color(0xFF2196F3),
    'hiking': Color(0xFF4CAF50),
    'hike': Color(0xFF4CAF50),
    'camping': Color(0xFF4CAF50),
    'cinema': Color(0xFF9C27B0),
    'movie': Color(0xFF9C27B0),
    'theater': Color(0xFF9C27B0),
    'meeting': Color(0xFF2196F3),
    'shopping': Color(0xFFFF9800),
    'cooking': Color(0xFFFF9800),
    'sport': Color(0xFF4CAF50),
    'training': Color(0xFF4CAF50),
    'practice': Color(0xFF4CAF50),
  };

  /// Get icon for a category string. Uses partial matching.
  static IconData getIcon(String? category, ItemType type) {
    if (category != null && category.isNotEmpty) {
      final lower = category.toLowerCase();

      // Exact match first
      if (_iconMap.containsKey(lower)) return _iconMap[lower]!;

      // Partial match: check if category contains a known keyword
      for (final entry in _iconMap.entries) {
        if (lower.contains(entry.key) || entry.key.contains(lower)) {
          return entry.value;
        }
      }
    }

    // Fallback to type-based icon
    return switch (type) {
      ItemType.event => Icons.event_rounded,
      ItemType.task => Icons.check_circle_outline_rounded,
      ItemType.deadline => Icons.schedule_rounded,
    };
  }

  /// Get color for a category string. Uses partial matching.
  static Color getColor(String? category, ItemType type) {
    if (category != null && category.isNotEmpty) {
      final lower = category.toLowerCase();

      // Exact match first
      if (_colorMap.containsKey(lower)) return _colorMap[lower]!;

      // Partial match
      for (final entry in _colorMap.entries) {
        if (lower.contains(entry.key) || entry.key.contains(lower)) {
          return entry.value;
        }
      }
    }

    // Fallback to type-based color
    return switch (type) {
      ItemType.event => AppColors.primary,
      ItemType.task => AppColors.warmYellow,
      ItemType.deadline => AppColors.softCoral,
    };
  }

  /// Get background color (lighter version) for icon containers.
  static Color getBackgroundColor(String? category, ItemType type) {
    return getColor(category, type).withValues(alpha: 0.12);
  }
}
