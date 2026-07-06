import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Placeholder for localization until we set up full intl generation.
/// Supports: English, French, German, Spanish.
class AppLocalizations {
  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('es'),
  ];

  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
