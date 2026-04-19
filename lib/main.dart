import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app/app.dart';
import 'core/env.dart';
import 'core/notification_service.dart';
import 'features/subscription/data/entitlement_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Initialize Firebase with generated options.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence with unlimited cache.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Disable reCAPTCHA verification in debug builds (emulator-friendly).
    if (kDebugMode) {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    }

    // Initialize Crashlytics — only enable crash reporting in prod.
    if (Env.crashlyticsEnabled) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      // In non-prod environments, disable Crashlytics collection.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(false);
    }
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  // Defer non-critical init to after first frame to avoid ANR.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDeferredServices();
  });

  // Replace red error screen in release mode
  if (!kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The app encountered an error. Please try restarting.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };
  }

  runApp(const ProviderScope(child: GymRatzApp()));
}

/// Initialize RevenueCat and notifications after the first frame.
Future<void> _initDeferredServices() async {
  await Future.wait([
    _initRevenueCat(),
    _initNotifications(),
  ]);
}

Future<void> _initRevenueCat() async {
  try {
    await EntitlementRepository().initialize();
  } catch (e) {
    debugPrint('RevenueCat init skipped: $e');
  }
}

Future<void> _initNotifications() async {
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }
}
