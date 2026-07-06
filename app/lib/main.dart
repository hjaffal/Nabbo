import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Use Nunito Sans as default font via Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    const ProviderScope(child: NabboApp()),
  );
}

class NabboApp extends ConsumerWidget {
  const NabboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    final theme = AppTheme.light.copyWith(
      textTheme: GoogleFonts.nunitoSansTextTheme(AppTheme.light.textTheme),
    );

    return MaterialApp.router(
      title: 'Nabbo',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
