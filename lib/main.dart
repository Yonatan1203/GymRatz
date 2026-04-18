import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app/app.dart';
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

    // Initialize Crashlytics — only enable crash reporting in non-debug mode.
    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      // In debug mode, disable Crashlytics collection.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(false);
    }
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  // Initialize RevenueCat SDK (guarded — no-op if API keys are placeholders).
  try {
    await EntitlementRepository().initialize();
  } catch (e) {
    debugPrint('RevenueCat init skipped: $e');
  }

  runApp(const ProviderScope(child: GymRatzApp()));
}
