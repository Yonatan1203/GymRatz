import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/crashlytics_service.dart';
import '../core/pip_service.dart';
import '../shared/utils/app_scroll_behavior.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class GymRatzApp extends ConsumerWidget {
  const GymRatzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    // Side-effects: keep Crashlytics custom keys in sync with live session
    // state. Registered here so they are scoped to this widget's lifetime.
    ref.listen(authStateProvider, (_, next) {
      CrashlyticsService().setUser(next.valueOrNull?.uid);
    });
    ref.listen(isProProvider, (_, next) {
      final raw = next.valueOrNull;
      final label = raw == null ? 'loading' : (raw ? 'active' : 'expired');
      CrashlyticsService().setSubscriptionState(label);
    });
    ref.listen(activeWorkoutSessionProvider, (_, next) {
      CrashlyticsService().setWorkoutActive(next != null);
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 Pro
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp.router(
            title: 'GymRatz',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
            builder: (context, child) {
              return _PipWrapper(child: child ?? const SizedBox());
            },
          ),
        );
      },
    );
  }
}

/// App-level PiP wrapper that shows a minimal timer view when in PiP mode.
class _PipWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _PipWrapper({required this.child});

  @override
  ConsumerState<_PipWrapper> createState() => _PipWrapperState();
}

class _PipWrapperState extends ConsumerState<_PipWrapper> {
  bool _isInPip = false;

  @override
  void initState() {
    super.initState();
    PipService().onPipChanged = (inPip) {
      if (mounted) setState(() => _isInPip = inPip);
    };
  }

  @override
  void dispose() {
    PipService().onPipChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeWorkoutSessionProvider);

    if (_isInPip && activeSession != null) {
      return _buildPipView(context, activeSession);
    }

    return widget.child;
  }

  Widget _buildPipView(BuildContext context, ActiveWorkoutSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final restTimerValue = ref.watch(restTimerSecondsProvider).valueOrNull;
    final restActive = session.restActive && session.timerRunning && restTimerValue != null;
    final restSeconds = restTimerValue ?? 0;
    final timerDone = restActive && restSeconds == 0;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final coralColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final foreground = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final mutedForeground = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (timerDone)
              Icon(AppIcons.bell, size: 48, color: coralColor)
            else if (restActive)
              Text(
                '${(restSeconds ~/ 60).toString().padLeft(2, '0')}:${(restSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              Text(
                session.workoutName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: foreground),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              restActive ? (timerDone ? 'Rest Complete!' : 'Rest') : 'In Progress',
              style: TextStyle(fontSize: 14, color: mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
