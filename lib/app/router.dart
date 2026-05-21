import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/onboarding/presentation/onboarding_welcome_screen.dart';
import '../features/onboarding/presentation/onboarding_goal_screen.dart';
import '../features/onboarding/presentation/onboarding_style_screen.dart';
import '../features/onboarding/presentation/onboarding_height_screen.dart';
import '../features/onboarding/presentation/onboarding_summary_screen.dart';
import '../features/onboarding/presentation/onboarding_email_screen.dart';
import '../features/onboarding/presentation/onboarding_health_screen.dart';
import '../features/onboarding/presentation/onboarding_showcase_screen.dart';
import '../features/onboarding/presentation/onboarding_discovery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/workout/presentation/workout_screen.dart';
import '../features/workout/presentation/workout_logging_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/programs/presentation/programs_screen.dart';
import '../features/programs/presentation/program_detail_screen.dart';
import '../features/programs/presentation/create_program_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/exercises/presentation/exercise_library_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/faq_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/achievements/presentation/achievements_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/subscription/presentation/paywall_screen.dart';
import '../features/coach/presentation/coach_application_screen.dart';
import '../features/coach/presentation/join_coach_screen.dart';
import '../shared/utils/platform_adapter.dart';
import '../shared/widgets/custom_scaffold.dart';
import 'coach_router.dart';
import 'providers/auth_providers.dart';
import 'providers/data_providers.dart';

// ─── Transition Helpers ───

CustomTransitionPage<void> fadeTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 200),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> slideTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return SlideTransition(position: slide, child: child);
    },
  );
}

CustomTransitionPage<void> horizontalSlideTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that don't require authentication.
const _publicPaths = {
  '/onboarding',
  '/onboarding/showcase',
  '/onboarding/goal',
  '/onboarding/style',
  '/onboarding/height',
  '/onboarding/health',
  '/onboarding/email',
  '/onboarding/summary',
  '/onboarding/discovery',
  '/login',
  '/forgot-password',
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final role = ref.watch(userRoleProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.uri.path;
      final isPublicRoute = _publicPaths.contains(currentPath);
      final isCoachRoute = currentPath.startsWith('/coach');
      final isCoachRole = role.isCoachRole;

      // Not signed in and trying to access protected route -> onboarding
      if (!isLoggedIn && !isPublicRoute) {
        return '/onboarding';
      }

      // Signed in and on auth/onboarding route -> check role
      if (isLoggedIn && (currentPath == '/login' || currentPath == '/onboarding')) {
        return isCoachRole ? '/coach/dashboard' : '/home';
      }

      // Coach role trying to access non-coach user routes -> coach dashboard
      if (isLoggedIn && isCoachRole && !isCoachRoute && !isPublicRoute &&
          currentPath != '/apply-coach' && currentPath != '/join-coach') {
        return '/coach/dashboard';
      }

      // User role trying to access /coach routes -> home
      if (isLoggedIn && !isCoachRole && isCoachRoute) {
        return '/home';
      }

      return null; // no redirect
    },
    routes: [
      // ─── Auth ───
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => PlatformAdapter.buildPage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => PlatformAdapter.buildPage(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // ─── Onboarding Flow ───
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingWelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/goal',
        name: 'onboarding-goal',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingGoalScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/style',
        name: 'onboarding-style',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingStyleScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/height',
        name: 'onboarding-height',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingHeightScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/summary',
        name: 'onboarding-summary',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/email',
        name: 'onboarding-email',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingEmailScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/health',
        name: 'onboarding-health',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingHealthScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/showcase',
        name: 'onboarding-showcase',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingShowcaseScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding/discovery',
        name: 'onboarding-discovery',
        pageBuilder: (context, state) => horizontalSlideTransitionPage(
          state: state,
          child: const OnboardingDiscoveryScreen(),
        ),
      ),

      // ─── Main App (Shell with Bottom Nav) ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                name: 'today',
                pageBuilder: (context, state) => fadeTransitionPage(
                  state: state,
                  child: const WorkoutScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                pageBuilder: (context, state) => fadeTransitionPage(
                  state: state,
                  child: const CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => fadeTransitionPage(
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/programs',
                name: 'programs',
                pageBuilder: (context, state) => fadeTransitionPage(
                  state: state,
                  child: const ProgramsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => fadeTransitionPage(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ─── Standalone Screens (no bottom nav) ───
      GoRoute(
        path: '/workout/:dayId',
        name: 'workout-logging',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: WorkoutLoggingScreen(
            dayId: state.pathParameters['dayId'] ?? '1',
          ),
        ),
      ),
      GoRoute(
        path: '/programs/detail/:id',
        name: 'program-detail',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: ProgramDetailScreen(
            programId: state.pathParameters['id'] ?? '1',
          ),
        ),
      ),
      GoRoute(
        path: '/programs/create',
        name: 'create-program',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const CreateProgramScreen(),
        ),
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const ProgressScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/exercises',
        name: 'exercises',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const ExerciseLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const AchievementsScreen(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const FaqScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const PaywallScreen(),
        ),
      ),

      // ─── Coach Shell (Bottom Nav) ───
      coachShellRoute(),

      // ─── Coach Standalone Screens ───
      ...coachStandaloneRoutes(),

      // ─── Coach Application Routes ───
      GoRoute(
        path: '/join-coach',
        name: 'join-coach',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const JoinCoachScreen(),
        ),
      ),
      GoRoute(
        path: '/apply-coach',
        name: 'apply-coach',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const CoachApplicationScreen(),
        ),
      ),
    ],
  );
});
