import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/household_setup_screen.dart';
import '../../features/onboarding/presentation/add_children_screen.dart';
import '../../features/onboarding/presentation/add_people_screen.dart';
import '../../features/onboarding/presentation/email_alias_screen.dart';
import '../../features/onboarding/presentation/first_capture_screen.dart';
import '../widgets/app_shell.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/review/presentation/review_inbox_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/household',
        builder: (context, state) => const HouseholdSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/children',
        builder: (context, state) => const AddChildrenScreen(),
      ),
      GoRoute(
        path: '/onboarding/people',
        builder: (context, state) => const AddPeopleScreen(),
      ),
      GoRoute(
        path: '/onboarding/email',
        builder: (context, state) => const EmailAliasScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-capture',
        builder: (context, state) => const FirstCaptureScreen(),
      ),

      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/review',
                builder: (context, state) => const ReviewInboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
