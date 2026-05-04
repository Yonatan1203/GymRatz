import 'package:go_router/go_router.dart';

import '../features/coach/presentation/assign_program_screen.dart';
import '../features/coach/presentation/client_detail_screen.dart';
import '../features/coach/presentation/clients_screen.dart';
import '../features/coach/presentation/coach_approval_screen.dart';
import '../features/coach/presentation/coach_dashboard_screen.dart';
import '../features/coach/presentation/coach_programs_screen.dart';
import '../features/coach/presentation/coach_settings_screen.dart';
import '../features/coach/presentation/invite_management_screen.dart';
import '../shared/widgets/coach_scaffold.dart';
import 'router.dart';

StatefulShellRoute coachShellRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return CoachScaffold(navigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/dashboard',
            name: 'coach-dashboard',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const CoachDashboardScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/clients',
            name: 'coach-clients',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const ClientsScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/programs',
            name: 'coach-programs',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const CoachProgramsScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/settings',
            name: 'coach-settings',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const CoachSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

List<GoRoute> coachStandaloneRoutes() {
  return [
    GoRoute(
      path: '/coach/clients/:clientUid',
      name: 'client-detail',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: ClientDetailScreen(
          clientUid: state.pathParameters['clientUid'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/coach/clients/:clientUid/assign',
      name: 'assign-program',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: AssignProgramScreen(
          clientUid: state.pathParameters['clientUid'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/coach/invites',
      name: 'coach-invites',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: const InviteManagementScreen(),
      ),
    ),
    GoRoute(
      path: '/coach/approvals',
      name: 'coach-approvals',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: const CoachApprovalScreen(),
      ),
    ),
  ];
}
