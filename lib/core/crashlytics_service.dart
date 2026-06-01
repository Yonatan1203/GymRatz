import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';

/// Thin wrapper around FirebaseCrashlytics for structured key/breadcrumb calls.
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._();

  final _c = FirebaseCrashlytics.instance;

  void setUser(String? uid) {
    _c.setUserIdentifier(uid ?? '');
    if (uid != null) _c.setCustomKey('uid', uid);
  }

  void setSubscriptionState(String state) =>
      _c.setCustomKey('subscription_state', state);

  void setWorkoutActive(bool active) =>
      _c.setCustomKey('workout_active', active);

  void setScreen(String name) => _c.setCustomKey('screen', name);

  void log(String message) => _c.log(message);
}

/// Navigator observer that updates the Crashlytics 'screen' custom key
/// whenever a named route is pushed or replaced.
class CrashlyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      CrashlyticsService().setScreen(name);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final name = newRoute?.settings.name;
    if (name != null && name.isNotEmpty) {
      CrashlyticsService().setScreen(name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = previousRoute?.settings.name;
    if (name != null && name.isNotEmpty) {
      CrashlyticsService().setScreen(name);
    }
  }
}
