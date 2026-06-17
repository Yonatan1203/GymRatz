import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/crashlytics_service.dart';
import '../shared/utils/app_scroll_behavior.dart';
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
          ),
        );
      },
    );
  }
}
