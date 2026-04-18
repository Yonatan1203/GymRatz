# GymRatz v1.0 Production Readiness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform GymRatz from Beta/MVP to production-ready for Google Play and Apple App Store release.

**Architecture:** Flutter + Firebase (Auth, Firestore, Crashlytics, Analytics) + RevenueCat + Riverpod, feature-first with data/domain/presentation layers.

**Tech Stack:** Flutter/Dart, firebase_crashlytics, firebase_analytics, google_sign_in, sign_in_with_apple, flutter_local_notifications, flutter_launcher_icons, flutter_native_splash

**Branch:** All work on `feature/production-readiness` branch off `main`.

---

## Pre-requisites (User Actions)

Before starting, the user must provide:
- [ ] Apple Developer Account enrollment ($99/year at developer.apple.com)
- [ ] RevenueCat project with iOS + Android apps registered → API keys
- [ ] Rat icon asset (1024×1024 PNG minimum)
- [ ] Android release keystore password (user chooses)

Items not yet available can be skipped and filled in later — tasks are designed to work with placeholders where needed.

---

## File Structure Overview

### New Files to Create
```
lib/core/env.dart                                          — Environment config (dev/prod)
lib/core/analytics_service.dart                            — Analytics event wrapper
lib/core/notification_service.dart                         — Local notification management
lib/features/auth/presentation/widgets/social_auth_buttons.dart — Google/Apple sign-in buttons
lib/features/progression/domain/strength_strategy.dart     — Strength mode PO engine
lib/features/progression/domain/hypertrophy_strategy.dart  — Hypertrophy mode PO engine
lib/features/progression/domain/endurance_strategy.dart    — Endurance mode PO engine
lib/features/progression/domain/progression_strategy.dart  — Strategy interface
lib/features/progression/domain/models/session_metrics.dart — Extended session data model
lib/features/progression/domain/models/progression_history.dart — e1RM/score history tracking
lib/shared/widgets/async_value_widget.dart                 — Reusable AsyncValue handler
lib/shared/widgets/empty_state_widget.dart                 — Reusable empty state
lib/shared/widgets/offline_banner.dart                     — Connectivity indicator
assets/data/exercises.json                                 — Bundled exercise library (200+)
test/core/analytics_service_test.dart                      — Analytics service tests
test/progression/strength_strategy_test.dart               — Strength mode tests
test/progression/hypertrophy_strategy_test.dart            — Hypertrophy mode tests
test/progression/endurance_strategy_test.dart              — Endurance mode tests
test/progression/load_quantizer_test.dart                  — Load snapping tests
test/progression/session_analyzer_test.dart                — Session analysis tests
android/key.properties                                     — Release keystore config (gitignored)
```

### Files to Modify
```
lib/main.dart                                              — Add Crashlytics, Analytics init
lib/core/constants.dart                                    — Real RevenueCat keys, new constants
lib/core/exceptions.dart                                   — Extended error types
lib/app/app.dart                                           — Analytics observer
lib/app/router.dart                                        — Auth redirect updates
lib/app/providers/auth_providers.dart                      — Social auth providers
lib/app/providers/data_providers.dart                      — Exercise library provider update
lib/app/providers/service_providers.dart                   — New service providers
lib/app/providers/subscription_providers.dart              — Subscription state updates
lib/features/auth/data/auth_repository.dart                — Add Google/Apple sign-in methods
lib/features/auth/domain/auth_service.dart                 — Social auth orchestration
lib/features/auth/presentation/login_screen.dart           — Social auth buttons
lib/features/subscription/presentation/paywall_screen.dart — Real offerings display
lib/features/profile/presentation/profile_screen.dart      — Subscription status, delete account
lib/features/settings/presentation/settings_screen.dart    — Notification settings, legal links
lib/features/exercises/presentation/exercise_library_screen.dart — Bundled + user exercises
lib/features/onboarding/providers/onboarding_provider.dart — Local state persistence
lib/features/workout/presentation/workout_logging_screen.dart — Crash recovery, haptics
lib/features/home/presentation/home_screen.dart            — AsyncValue widget, empty states
lib/features/progression/domain/progression_engine.dart    — Route to 3-mode strategies
lib/features/progression/domain/session_analyzer.dart      — Extended metrics
lib/features/progression/domain/progression_suggestion.dart — Extended suggestion model
lib/shared/models/enums.dart                               — Add ProgressionMode.strength/hypertrophy/endurance
lib/shared/models/workout_set.dart                         — Add topSet flag, restSec
lib/shared/models/workout_exercise.dart                    — Add session metrics
lib/shared/models/exercise.dart                            — Add muscleGroups, instructions, isDefault
lib/shared/models/program_exercise.dart                    — progressionType → ProgressionMode enum
pubspec.yaml                                               — New dependencies
android/app/build.gradle.kts                               — Release signing
.gitignore                                                 — Add key.properties, .env
firestore.rules                                            — Add exercises subcollection
```

---

## Phase 1: Infrastructure & Configuration

### Task 1: Create feature branch and add Firebase Crashlytics

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create feature branch**

```bash
cd C:\Personal_Projects\GymRatz\Development\Version_0\GymRatz
git checkout -b feature/production-readiness
```

- [ ] **Step 2: Add firebase_crashlytics dependency**

In `pubspec.yaml`, add under dependencies:

```yaml
  firebase_crashlytics: ^4.3.2
```

Run:
```bash
flutter pub get
```

- [ ] **Step 3: Initialize Crashlytics in main.dart**

Replace the contents of `lib/main.dart` with:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'features/subscription/data/entitlement_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics — catch all Flutter and async errors
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Debug: disable reCAPTCHA for emulator
  if (kDebugMode) {
    await FirebaseFirestore.instance.disableNetwork().then((_) {
      FirebaseFirestore.instance.enableNetwork();
    });
  }

  // RevenueCat — gracefully handle placeholder keys
  try {
    await EntitlementRepository().initialize();
  } catch (e) {
    debugPrint('RevenueCat init skipped: $e');
  }

  runApp(const ProviderScope(child: GymRatzApp()));
}
```

- [ ] **Step 4: Verify build succeeds**

```bash
flutter build apk --debug
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/main.dart pubspec.lock
git commit -m "feat: add Firebase Crashlytics with error capturing"
```

---

### Task 2: Add Firebase Analytics with event service

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/analytics_service.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/providers/service_providers.dart`

- [ ] **Step 1: Add firebase_analytics dependency**

In `pubspec.yaml`, add under dependencies:

```yaml
  firebase_analytics: ^11.4.2
```

Run:
```bash
flutter pub get
```

- [ ] **Step 2: Create analytics service**

Create `lib/core/analytics_service.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logWorkoutStarted({
    required String programId,
    required String workoutDayId,
  }) =>
      _analytics.logEvent(name: 'workout_started', parameters: {
        'program_id': programId,
        'workout_day_id': workoutDayId,
      });

  Future<void> logWorkoutCompleted({
    required int durationSeconds,
    required int exerciseCount,
    required int totalSets,
    required double totalVolume,
  }) =>
      _analytics.logEvent(name: 'workout_completed', parameters: {
        'duration_seconds': durationSeconds,
        'exercise_count': exerciseCount,
        'total_sets': totalSets,
        'total_volume': totalVolume,
      });

  Future<void> logProgramCreated(String programName) =>
      _analytics.logEvent(name: 'program_created', parameters: {
        'program_name': programName,
      });

  Future<void> logAchievementUnlocked(String achievementId) =>
      _analytics.logEvent(name: 'achievement_unlocked', parameters: {
        'achievement_id': achievementId,
      });

  Future<void> logSubscriptionStarted(String planId) =>
      _analytics.logEvent(name: 'subscription_started', parameters: {
        'plan_id': planId,
      });

  Future<void> logSubscriptionRestored() =>
      _analytics.logEvent(name: 'subscription_restored');

  Future<void> logOnboardingCompleted(int stepCount) =>
      _analytics.logEvent(name: 'onboarding_completed', parameters: {
        'step_count': stepCount,
      });

  Future<void> logOnboardingAbandoned(int lastStep) =>
      _analytics.logEvent(name: 'onboarding_abandoned', parameters: {
        'last_step': lastStep,
      });

  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);
}
```

- [ ] **Step 3: Add analytics provider**

In `lib/app/providers/service_providers.dart`, add at the top:

```dart
import 'package:gymratz/core/analytics_service.dart';
```

Add provider:

```dart
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
```

- [ ] **Step 4: Add analytics observer to app**

In `lib/app/app.dart`, add the analytics observer to the router configuration. In the `MaterialApp.router` constructor, add after `routerConfig`:

```dart
// Inside the MaterialApp.router builder, add to the GoRouter:
observers: [ref.read(analyticsServiceProvider).observer],
```

Note: The exact integration depends on the GoRouter setup. If GoRouter doesn't directly accept observers, add the observer in `router.dart` where the GoRouter is created.

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/analytics_service.dart lib/app/providers/service_providers.dart lib/app/app.dart pubspec.yaml pubspec.lock
git commit -m "feat: add Firebase Analytics service with core event tracking"
```

---

### Task 3: Environment configuration (dev/prod)

**Files:**
- Create: `lib/core/env.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create environment config**

Create `lib/core/env.dart`:

```dart
enum Environment { dev, prod }

class Env {
  static Environment get current {
    const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
    return envStr == 'prod' ? Environment.prod : Environment.dev;
  }

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;

  /// Use verbose logging in dev
  static bool get verboseLogging => isDev;

  /// Only enable Crashlytics in prod
  static bool get crashlyticsEnabled => isProd;
}
```

- [ ] **Step 2: Use Env in main.dart**

Update the Crashlytics guard in `lib/main.dart` from `if (!kDebugMode)` to:

```dart
import 'core/env.dart';

// In main():
if (Env.crashlyticsEnabled) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
```

- [ ] **Step 3: Verify both modes build**

```bash
flutter build apk --debug --dart-define=ENV=dev
flutter build apk --debug --dart-define=ENV=prod
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/env.dart lib/main.dart
git commit -m "feat: add environment configuration (dev/prod) with dart-define"
```

---

### Task 4: Android release build configuration

**Files:**
- Create: `android/key.properties` (gitignored)
- Modify: `android/app/build.gradle.kts`
- Modify: `.gitignore`

- [ ] **Step 1: Generate release keystore**

```bash
keytool -genkey -v -keystore android/gymratz-release.keystore -alias gymratz -keyalg RSA -keysize 2048 -validity 10000
```

Follow prompts — user provides password and organization details.

- [ ] **Step 2: Create key.properties**

Create `android/key.properties`:

```properties
storePassword=USER_PROVIDED_PASSWORD
keyPassword=USER_PROVIDED_PASSWORD
keyAlias=gymratz
storeFile=../gymratz-release.keystore
```

- [ ] **Step 3: Add to .gitignore**

Append to `.gitignore`:

```
# Release signing
android/key.properties
android/*.keystore
*.jks
```

- [ ] **Step 4: Update build.gradle.kts for release signing**

In `android/app/build.gradle.kts`, add the keystore loading and signing config. Add before the `android {` block:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside the `android {` block, add `signingConfigs` and update `buildTypes`:

```kotlin
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

- [ ] **Step 5: Create ProGuard rules for Firebase**

Create `android/app/proguard-rules.pro`:

```
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.revenuecat.purchases.** { *; }
```

- [ ] **Step 6: Verify release build**

```bash
flutter build apk --release
```

Expected: BUILD SUCCESSFUL with signed APK

- [ ] **Step 7: Commit**

```bash
git add android/app/build.gradle.kts android/app/proguard-rules.pro .gitignore
git commit -m "feat: configure Android release signing and ProGuard rules"
```

---

### Task 5: App icon and splash screen

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/icon/` (user provides icon file here)

- [ ] **Step 1: Add icon and splash dependencies**

In `pubspec.yaml`, add under `dev_dependencies`:

```yaml
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.6
```

Add configuration at the end of `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#003A6B"
  adaptive_icon_foreground: "assets/icon/app_icon.png"

flutter_native_splash:
  color: "#003A6B"
  image: "assets/icon/app_icon.png"
  android: true
  ios: true
  android_12:
    color: "#003A6B"
    image: "assets/icon/app_icon.png"
```

- [ ] **Step 2: Create icon directory and placeholder**

```bash
mkdir -p assets/icon
```

User places their 1024×1024 rat icon at `assets/icon/app_icon.png`.

- [ ] **Step 3: Generate icons and splash (once icon is provided)**

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

- [ ] **Step 4: Verify app name on both platforms**

Confirm `android/app/src/main/AndroidManifest.xml` has `android:label="GymRatz"`.
Confirm `ios/Runner/Info.plist` has `CFBundleDisplayName` = `GymRatz`.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml assets/icon/ android/ ios/
git commit -m "feat: add app icon and native splash screen configuration"
```

---

### Task 6: RevenueCat key configuration

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Update constants with real keys (or document placeholders)**

Update `lib/core/constants.dart`:

```dart
class AppConstants {
  // RevenueCat API Keys
  // Get from: https://app.revenuecat.com → Project → API Keys
  static const String revenueCatAppleApiKey =
      const String.fromEnvironment('RC_APPLE_KEY', defaultValue: 'appl_REPLACE_ME');
  static const String revenueCatGoogleApiKey =
      const String.fromEnvironment('RC_GOOGLE_KEY', defaultValue: 'goog_REPLACE_ME');

  // RevenueCat identifiers
  static const String entitlementId = 'pro';
  static const String defaultOfferingId = 'default';

  // Free tier limits
  static const int freeMaxActivePrograms = 1;
  static const int freeHistoryWeeks = 2;

  // App info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://gymratz.app/privacy'; // TODO: user provides URL
  static const String termsOfServiceUrl = 'https://gymratz.app/terms'; // TODO: user provides URL
}
```

This allows passing real keys via `--dart-define=RC_APPLE_KEY=appl_xxx` without hardcoding them.

- [ ] **Step 2: Commit**

```bash
git add lib/core/constants.dart
git commit -m "feat: make RevenueCat keys configurable via dart-define"
```

---

### Task 6.5: Validate placeholder keys at runtime

**Files:**
- Modify: `lib/features/subscription/data/entitlement_repository.dart`

- [ ] **Step 1: Add key validation before RevenueCat init**

In `lib/features/subscription/data/entitlement_repository.dart`, update `initialize()`:

```dart
  Future<void> initialize() async {
    final apiKey = Platform.isIOS
        ? AppConstants.revenueCatAppleApiKey
        : AppConstants.revenueCatGoogleApiKey;

    if (apiKey.contains('REPLACE_ME')) {
      debugPrint('⚠️ RevenueCat: using placeholder API key — subscription features disabled');
      return;
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/subscription/data/entitlement_repository.dart
git commit -m "feat: validate RevenueCat keys at runtime, skip init for placeholders"
```

---

## Phase 2: Authentication & Subscription

### Task 7: Google Sign-In

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/auth/data/auth_repository.dart`
- Modify: `lib/features/auth/domain/auth_service.dart`

- [ ] **Step 1: Add google_sign_in dependency**

In `pubspec.yaml`, add:

```yaml
  google_sign_in: ^6.2.2
```

```bash
flutter pub get
```

- [ ] **Step 2: Add signInWithGoogle to AuthRepository**

In `lib/features/auth/data/auth_repository.dart`, add import:

```dart
import 'package:google_sign_in/google_sign_in.dart';
```

Add method to `AuthRepository` class:

```dart
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthErrorMessage(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Handle account-exists-with-different-credential by linking
  Future<UserCredential> _handleCredentialConflict(
    AuthCredential credential,
    String email,
  ) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (methods.isEmpty) rethrow;
    // If user already has an account, sign in and link
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return await currentUser.linkWithCredential(credential);
    }
    throw AuthException(
      'An account already exists with email $email. '
      'Please sign in with ${methods.first} first, then link this provider in settings.',
    );
  }
```

- [ ] **Step 3: Add signInWithGoogle to AuthService**

In `lib/features/auth/domain/auth_service.dart`, add method:

```dart
  Future<void> signInWithGoogle() async {
    final credential = await _authRepository.signInWithGoogle();
    final uid = credential.user!.uid;

    // Link with RevenueCat
    await _entitlementService.loginUser(uid);

    // Create profile if first time
    final hasExistingProfile = await hasProfile(uid);
    if (!hasExistingProfile) {
      final user = credential.user!;
      final profile = UserProfile(
        uid: uid,
        name: user.displayName ?? 'User',
        initials: _getInitials(user.displayName ?? 'User'),
        email: user.email ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userRepository.createUser(uid, profile);
      await _achievementService.initializeDefaultAchievements(uid);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
```

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/auth/data/auth_repository.dart lib/features/auth/domain/auth_service.dart
git commit -m "feat: add Google Sign-In authentication flow"
```

---

### Task 8: Apple Sign-In

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/auth/data/auth_repository.dart`
- Modify: `lib/features/auth/domain/auth_service.dart`

- [ ] **Step 1: Add sign_in_with_apple and crypto dependencies**

In `pubspec.yaml`, add:

```yaml
  sign_in_with_apple: ^6.1.4
  crypto: ^3.0.6
```

```bash
flutter pub get
```

- [ ] **Step 2: Add signInWithApple to AuthRepository**

In `lib/features/auth/data/auth_repository.dart`, add imports:

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
```

Add method to `AuthRepository`:

```dart
  Future<UserCredential> signInWithApple() async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      return await _auth.signInWithCredential(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('Apple sign-in was cancelled');
      }
      throw AuthException('Apple sign-in failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthErrorMessage(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
```

- [ ] **Step 3: Add signInWithApple to AuthService**

In `lib/features/auth/domain/auth_service.dart`, add method:

```dart
  Future<void> signInWithApple() async {
    final credential = await _authRepository.signInWithApple();
    final uid = credential.user!.uid;

    await _entitlementService.loginUser(uid);

    final hasExistingProfile = await hasProfile(uid);
    if (!hasExistingProfile) {
      final user = credential.user!;
      final profile = UserProfile(
        uid: uid,
        name: user.displayName ?? 'User',
        initials: _getInitials(user.displayName ?? 'User'),
        email: user.email ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userRepository.createUser(uid, profile);
      await _achievementService.initializeDefaultAchievements(uid);
    }
  }
```

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/auth/data/auth_repository.dart lib/features/auth/domain/auth_service.dart
git commit -m "feat: add Apple Sign-In authentication flow"
```

---

### Task 9: Social auth buttons on login screen

**Files:**
- Create: `lib/features/auth/presentation/widgets/social_auth_buttons.dart`
- Modify: `lib/features/auth/presentation/login_screen.dart`

- [ ] **Step 1: Create social auth buttons widget**

Create `lib/features/auth/presentation/widgets/social_auth_buttons.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  const SocialAuthButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _dividerRow(theme),
        SizedBox(height: 16.h),
        _socialButton(
          context,
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          onPressed: isLoading ? null : onGooglePressed,
        ),
        if (Platform.isIOS) ...[
          SizedBox(height: 12.h),
          _socialButton(
            context,
            label: 'Continue with Apple',
            icon: Icons.apple,
            onPressed: isLoading ? null : onApplePressed,
          ),
        ],
      ],
    );
  }

  Widget _dividerRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text('or', style: theme.textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }

  Widget _socialButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.sp),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add social auth to login screen**

In `lib/features/auth/presentation/login_screen.dart`, import the widget and auth service:

```dart
import 'widgets/social_auth_buttons.dart';
```

Add social auth methods to `_LoginScreenState`:

```dart
  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

Add `SocialAuthButtons` widget in the build method, after the existing sign-in button and before any footer:

```dart
SizedBox(height: 24.h),
SocialAuthButtons(
  onGooglePressed: _signInWithGoogle,
  onApplePressed: _signInWithApple,
  isLoading: _isLoading,
),
```

- [ ] **Step 3: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/widgets/social_auth_buttons.dart lib/features/auth/presentation/login_screen.dart
git commit -m "feat: add Google and Apple sign-in buttons to login screen"
```

---

### Task 10: Account deletion flow

**Files:**
- Modify: `lib/features/auth/data/auth_repository.dart`
- Modify: `lib/features/auth/domain/auth_service.dart`
- Modify: `lib/features/user/data/user_repository.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Add full data deletion to UserRepository**

In `lib/features/user/data/user_repository.dart`, add method:

```dart
  /// Deletes all user data including subcollections
  Future<void> deleteAllUserData(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);

    // Delete subcollections
    final subcollections = ['workouts', 'programs', 'achievements', 'prs', 'weightEntries', 'exercises'];
    for (final sub in subcollections) {
      final snap = await userDoc.collection(sub).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Delete user document
    await userDoc.delete();
  }
```

- [ ] **Step 2: Add full deleteAccount to AuthService**

Update the `deleteAccount` method in `lib/features/auth/domain/auth_service.dart`:

```dart
  Future<void> deleteAccount() async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) throw AuthException('No user signed in');

    // 1. Delete all Firestore data
    await _userRepository.deleteAllUserData(uid);

    // 2. Clear RevenueCat
    await _entitlementService.logoutUser();

    // 3. Delete Firebase Auth account (must be last — requires recent auth)
    await _authRepository.deleteAccount();
  }
```

- [ ] **Step 3: Add delete account UI to settings screen**

In `lib/features/settings/presentation/settings_screen.dart`, add a delete account handler method:

```dart
  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data including workouts, programs, and achievements. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      setState(() => _isLoading = true);
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
      if (mounted) {
        context.go('/onboarding/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

Wire this to the existing "Delete Account" or "Clear All Data" menu item in the settings screen.

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/auth_repository.dart lib/features/auth/domain/auth_service.dart lib/features/user/data/user_repository.dart lib/features/settings/presentation/settings_screen.dart
git commit -m "feat: add account deletion flow with full data cleanup"
```

---

### Task 11: Subscription flow completion

**Files:**
- Modify: `lib/features/subscription/presentation/paywall_screen.dart`
- Modify: `lib/features/profile/presentation/profile_screen.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Harden paywall screen error handling**

In `lib/features/subscription/presentation/paywall_screen.dart`, update the `_purchase` method to handle all error cases:

```dart
  Future<void> _purchase(Package package) async {
    setState(() => _purchasing = true);
    try {
      final service = ref.read(entitlementServiceProvider);
      await service.purchase(package);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to GymRatz Pro!')),
        );
        Navigator.pop(context);
      }
    } on PlatformException catch (e) {
      if (e.code == 'PURCHASE_CANCELLED') {
        // User cancelled — do nothing
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Purchase failed: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
```

- [ ] **Step 2: Add Restore Purchases to settings screen**

Ensure `lib/features/settings/presentation/settings_screen.dart` has a working restore action:

```dart
  Future<void> _restorePurchases() async {
    try {
      final service = ref.read(entitlementServiceProvider);
      await service.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }
```

- [ ] **Step 3: Add subscription status to profile screen**

In `lib/features/profile/presentation/profile_screen.dart`, show subscription status by reading `isProProvider`:

```dart
// In the menu section, add:
final isPro = ref.watch(isProProvider).valueOrNull ?? false;

// Display:
MenuItem(
  icon: LucideIcons.crown,
  title: isPro ? 'GymRatz Pro' : 'Upgrade to Pro',
  subtitle: isPro ? 'Active subscription' : 'Unlock all features',
  onTap: isPro ? null : () => context.push('/paywall'),
),
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/subscription/presentation/paywall_screen.dart lib/features/profile/presentation/profile_screen.dart lib/features/settings/presentation/settings_screen.dart
git commit -m "feat: complete subscription flow with restore, error handling, and status display"
```

---

## Phase 3: Core Feature Upgrades

### Task 12: Progressive overload — strategy interface and extended models

**Files:**
- Create: `lib/features/progression/domain/progression_strategy.dart`
- Create: `lib/features/progression/domain/models/session_metrics.dart`
- Create: `lib/features/progression/domain/models/progression_history.dart`
- Modify: `lib/shared/models/enums.dart`
- Modify: `lib/shared/models/workout_set.dart`
- Modify: `lib/features/progression/domain/progression_suggestion.dart`

- [ ] **Step 1: Update ProgressionMode enum**

In `lib/shared/models/enums.dart`, replace the `ProgressionMode` enum:

```dart
enum ProgressionMode {
  strength,
  hypertrophy,
  endurance;

  String get label {
    switch (this) {
      case ProgressionMode.strength:
        return 'Strength';
      case ProgressionMode.hypertrophy:
        return 'Hypertrophy';
      case ProgressionMode.endurance:
        return 'Endurance';
    }
  }

  /// Migration from old values
  static ProgressionMode fromLegacy(String? value) {
    switch (value?.toLowerCase()) {
      case 'loadfirst':
      case 'load first':
        return ProgressionMode.strength;
      case 'repsfirst':
      case 'reps first':
        return ProgressionMode.endurance;
      case 'mixed':
        return ProgressionMode.hypertrophy;
      default:
        return ProgressionMode.hypertrophy;
    }
  }
}
```

- [ ] **Step 2: Extend WorkoutSet with top set flag and rest**

In `lib/shared/models/workout_set.dart`, add fields:

```dart
class WorkoutSet {
  final int reps;
  final double weight;
  final int rir;
  final bool completed;
  final bool isWarmup;
  final bool isTopSet;
  final int restSeconds;
  final String? equipmentType;

  const WorkoutSet({
    this.reps = 0,
    this.weight = 0,
    this.rir = 0,
    this.completed = false,
    this.isWarmup = false,
    this.isTopSet = false,
    this.restSeconds = 0,
    this.equipmentType,
  });

  // Update toJson/fromJson/copyWith to include isTopSet and restSeconds
```

Update `toJson()`:
```dart
  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weight': weight,
    'rir': rir,
    'completed': completed,
    'isWarmup': isWarmup,
    'isTopSet': isTopSet,
    'restSeconds': restSeconds,
    'equipmentType': equipmentType,
  };
```

Update `fromJson()`:
```dart
  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    reps: json['reps'] ?? 0,
    weight: (json['weight'] ?? 0).toDouble(),
    rir: json['rir'] ?? 0,
    completed: json['completed'] ?? false,
    isWarmup: json['isWarmup'] ?? false,
    isTopSet: json['isTopSet'] ?? false,
    restSeconds: json['restSeconds'] ?? 0,
    equipmentType: json['equipmentType'],
  );
```

Update `copyWith()`:
```dart
  WorkoutSet copyWith({
    int? reps,
    double? weight,
    int? rir,
    bool? completed,
    bool? isWarmup,
    bool? isTopSet,
    int? restSeconds,
    String? equipmentType,
  }) => WorkoutSet(
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    rir: rir ?? this.rir,
    completed: completed ?? this.completed,
    isWarmup: isWarmup ?? this.isWarmup,
    isTopSet: isTopSet ?? this.isTopSet,
    restSeconds: restSeconds ?? this.restSeconds,
    equipmentType: equipmentType ?? this.equipmentType,
  );
```

- [ ] **Step 3: Create session metrics model**

Create `lib/features/progression/domain/models/session_metrics.dart`:

```dart
class SessionMetrics {
  final double sessionE1RM;
  final double smoothedE1RM;
  final int hardSetCount;
  final int totalReps;
  final int targetTotalReps;
  final double totalTonnage;
  final double density; // tonnage per minute
  final int totalTimeSeconds;
  final double topSetWeight;
  final int topSetReps;
  final int topSetRir;

  const SessionMetrics({
    this.sessionE1RM = 0,
    this.smoothedE1RM = 0,
    this.hardSetCount = 0,
    this.totalReps = 0,
    this.targetTotalReps = 0,
    this.totalTonnage = 0,
    this.density = 0,
    this.totalTimeSeconds = 0,
    this.topSetWeight = 0,
    this.topSetReps = 0,
    this.topSetRir = 0,
  });

  Map<String, dynamic> toJson() => {
    'sessionE1RM': sessionE1RM,
    'smoothedE1RM': smoothedE1RM,
    'hardSetCount': hardSetCount,
    'totalReps': totalReps,
    'targetTotalReps': targetTotalReps,
    'totalTonnage': totalTonnage,
    'density': density,
    'totalTimeSeconds': totalTimeSeconds,
    'topSetWeight': topSetWeight,
    'topSetReps': topSetReps,
    'topSetRir': topSetRir,
  };

  factory SessionMetrics.fromJson(Map<String, dynamic> json) => SessionMetrics(
    sessionE1RM: (json['sessionE1RM'] ?? 0).toDouble(),
    smoothedE1RM: (json['smoothedE1RM'] ?? 0).toDouble(),
    hardSetCount: json['hardSetCount'] ?? 0,
    totalReps: json['totalReps'] ?? 0,
    targetTotalReps: json['targetTotalReps'] ?? 0,
    totalTonnage: (json['totalTonnage'] ?? 0).toDouble(),
    density: (json['density'] ?? 0).toDouble(),
    totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
    topSetWeight: (json['topSetWeight'] ?? 0).toDouble(),
    topSetReps: json['topSetReps'] ?? 0,
    topSetRir: json['topSetRir'] ?? 0,
  );
}
```

- [ ] **Step 4: Create progression history model**

Create `lib/features/progression/domain/models/progression_history.dart`:

```dart
class ProgressionHistory {
  final List<double> e1rmHistory; // last N session e1RMs
  final List<double> smoothedE1rmHistory;
  final List<double> scoreHistory;
  final List<int> weeklyHardSets; // per muscle group
  final int consecutiveLowScores;
  final int exposuresSinceImprovement;

  const ProgressionHistory({
    this.e1rmHistory = const [],
    this.smoothedE1rmHistory = const [],
    this.scoreHistory = const [],
    this.weeklyHardSets = const [],
    this.consecutiveLowScores = 0,
    this.exposuresSinceImprovement = 0,
  });

  double get baselineE1RM {
    if (e1rmHistory.length < 3) {
      return e1rmHistory.isNotEmpty ? e1rmHistory.last : 0;
    }
    final last3 = e1rmHistory.sublist(e1rmHistory.length - 3);
    last3.sort();
    return last3[1]; // median of last 3
  }

  double get latestSmoothedE1RM =>
      smoothedE1rmHistory.isNotEmpty ? smoothedE1rmHistory.last : 0;

  bool get isPlateaued => exposuresSinceImprovement >= 3;

  Map<String, dynamic> toJson() => {
    'e1rmHistory': e1rmHistory,
    'smoothedE1rmHistory': smoothedE1rmHistory,
    'scoreHistory': scoreHistory,
    'weeklyHardSets': weeklyHardSets,
    'consecutiveLowScores': consecutiveLowScores,
    'exposuresSinceImprovement': exposuresSinceImprovement,
  };

  factory ProgressionHistory.fromJson(Map<String, dynamic> json) =>
      ProgressionHistory(
        e1rmHistory: List<double>.from(
            (json['e1rmHistory'] ?? []).map((e) => (e as num).toDouble())),
        smoothedE1rmHistory: List<double>.from(
            (json['smoothedE1rmHistory'] ?? []).map((e) => (e as num).toDouble())),
        scoreHistory: List<double>.from(
            (json['scoreHistory'] ?? []).map((e) => (e as num).toDouble())),
        weeklyHardSets: List<int>.from(json['weeklyHardSets'] ?? []),
        consecutiveLowScores: json['consecutiveLowScores'] ?? 0,
        exposuresSinceImprovement: json['exposuresSinceImprovement'] ?? 0,
      );

  ProgressionHistory copyWith({
    List<double>? e1rmHistory,
    List<double>? smoothedE1rmHistory,
    List<double>? scoreHistory,
    List<int>? weeklyHardSets,
    int? consecutiveLowScores,
    int? exposuresSinceImprovement,
  }) =>
      ProgressionHistory(
        e1rmHistory: e1rmHistory ?? this.e1rmHistory,
        smoothedE1rmHistory: smoothedE1rmHistory ?? this.smoothedE1rmHistory,
        scoreHistory: scoreHistory ?? this.scoreHistory,
        weeklyHardSets: weeklyHardSets ?? this.weeklyHardSets,
        consecutiveLowScores: consecutiveLowScores ?? this.consecutiveLowScores,
        exposuresSinceImprovement: exposuresSinceImprovement ?? this.exposuresSinceImprovement,
      );
}
```

- [ ] **Step 5: Create strategy interface**

Create `lib/features/progression/domain/progression_strategy.dart`:

```dart
import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_suggestion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

abstract class ProgressionStrategy {
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionHistory history,
  });

  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  });

  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  });

  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  });
}
```

- [ ] **Step 6: Extend ProgressionSuggestion**

Update `lib/features/progression/domain/progression_suggestion.dart`:

```dart
import 'models/session_metrics.dart';

class ProgressionSuggestion {
  final double suggestedWeight;
  final int suggestedReps;
  final int suggestedSets;
  final String reasoning;
  final bool isDeload;
  final double? backoffWeight;
  final int? backoffSets;
  final double score;
  final SessionMetrics? metrics;

  const ProgressionSuggestion({
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.suggestedSets,
    required this.reasoning,
    this.isDeload = false,
    this.backoffWeight,
    this.backoffSets,
    this.score = 0,
    this.metrics,
  });
}
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/progression/domain/progression_strategy.dart lib/features/progression/domain/models/ lib/shared/models/enums.dart lib/shared/models/workout_set.dart lib/features/progression/domain/progression_suggestion.dart
git commit -m "feat: add progression strategy interface and extended models for 3-mode PO engine"
```

---

### Task 13: Strength mode strategy

**Files:**
- Create: `lib/features/progression/domain/strength_strategy.dart`
- Create: `test/progression/strength_strategy_test.dart`

- [ ] **Step 1: Write strength strategy tests**

Create `test/progression/strength_strategy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/strength_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/features/progression/domain/models/session_metrics.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  late StrengthStrategy strategy;

  setUp(() {
    strategy = StrengthStrategy();
  });

  group('e1RM calculation', () {
    test('computes e1RM using Epley formula', () {
      // 100kg x 5 reps → e1RM = 100 * (1 + 5/30) = 116.67
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
          const WorkoutSet(weight: 100, reps: 4, rir: 1, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, closeTo(116.67, 0.1));
    });

    test('caps reps at 12 for e1RM', () {
      // 60kg x 15 reps → capped to 12 → e1RM = 60 * (1 + 12/30) = 84
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 15, rir: 3, completed: true),
        ],
        repMin: 1,
        repMax: 6,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, closeTo(84, 0.1));
    });
  });

  group('score calculation', () {
    test('high score when e1RM exceeds baseline', () {
      final metrics = const SessionMetrics(
        sessionE1RM: 120,
        topSetRir: 2,
      );
      final history = const ProgressionHistory(
        e1rmHistory: [115, 116, 117],
      );
      final score = strategy.computeScore(metrics: metrics, history: history);
      expect(score, greaterThan(90));
    });

    test('low score when e1RM drops', () {
      final metrics = const SessionMetrics(
        sessionE1RM: 95,
        topSetRir: 0,
      );
      final history = const ProgressionHistory(
        e1rmHistory: [115, 116, 117],
      );
      final score = strategy.computeScore(metrics: metrics, history: history);
      expect(score, lessThan(80));
    });
  });

  group('progression rules', () {
    test('increases load +2% when score >= 97 and RIR >= 2', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true, isTopSet: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: const ProgressionHistory(
          e1rmHistory: [115, 115.5, 116],
        ),
      );
      expect(result.suggestedWeight, greaterThan(100));
      expect(result.isDeload, false);
    });

    test('deloads when plateau detected with low RIR', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 3, rir: 0, completed: true, isTopSet: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 0, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: ProgressionHistory(
          e1rmHistory: [110, 110, 110, 110],
          exposuresSinceImprovement: 4,
          scoreHistory: [75, 72],
        ),
      );
      expect(result.isDeload, true);
      expect(result.suggestedWeight, lessThan(100));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/progression/strength_strategy_test.dart
```

Expected: FAIL — `strength_strategy.dart` doesn't exist yet.

- [ ] **Step 3: Implement StrengthStrategy**

Create `lib/features/progression/domain/strength_strategy.dart`:

```dart
import 'dart:math';
import 'progression_strategy.dart';
import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_suggestion.dart';
import 'load_quantizer.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

class StrengthStrategy implements ProgressionStrategy {
  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    final workingSets = performedSets.where((s) => !s.isWarmup && s.completed).toList();
    if (workingSets.isEmpty) {
      return const SessionMetrics();
    }

    // e1RM via Epley: load * (1 + min(reps, 12) / 30)
    double maxE1RM = 0;
    double topWeight = 0;
    int topReps = 0;
    int topRir = 0;

    for (final set in workingSets) {
      final cappedReps = min(set.reps, 12);
      final e1rm = set.weight * (1 + cappedReps / 30);
      if (e1rm > maxE1RM) {
        maxE1RM = e1rm;
        topWeight = set.weight;
        topReps = set.reps;
        topRir = set.rir;
      }
    }

    // Smoothed e1RM: 0.7 * prev + 0.3 * current
    final prevSmoothed = history.latestSmoothedE1RM;
    final smoothed = prevSmoothed > 0
        ? 0.7 * prevSmoothed + 0.3 * maxE1RM
        : maxE1RM;

    final totalTonnage = workingSets.fold<double>(
        0, (sum, s) => sum + s.weight * s.reps);

    return SessionMetrics(
      sessionE1RM: maxE1RM,
      smoothedE1RM: smoothed,
      hardSetCount: workingSets.where((s) => s.rir <= 3).length,
      totalReps: workingSets.fold(0, (sum, s) => sum + s.reps),
      totalTonnage: totalTonnage,
      topSetWeight: topWeight,
      topSetReps: topReps,
      topSetRir: topRir,
    );
  }

  @override
  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    final baseline = history.baselineE1RM;
    if (baseline <= 0) return 85; // neutral score if no history

    final e1rmRatio = (metrics.sessionE1RM / baseline).clamp(0.85, 1.10);
    final effortOk = metrics.topSetRir >= 1 ? 1.0 : 0.0;
    final score = 100 * (0.85 * e1rmRatio + 0.15 * effortOk);
    return score.clamp(0, 100);
  }

  @override
  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    // Plateau + avg RIR <= 1 for last 2 sessions
    if (history.isPlateaued && metrics.topSetRir <= 1) return true;

    // Performance drop: session e1RM < baseline * 0.97
    if (history.baselineE1RM > 0 &&
        metrics.sessionE1RM < history.baselineE1RM * 0.97) {
      return true;
    }

    return false;
  }

  @override
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionHistory history,
  }) {
    final metrics = computeMetrics(
      performedSets: performedSets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      history: history,
    );

    final score = computeScore(metrics: metrics, history: history);
    final workingSets = performedSets.where((s) => !s.isWarmup && s.completed).toList();
    final setCount = workingSets.length;

    // Check deload
    if (shouldDeload(score: score, metrics: metrics, history: history)) {
      final deloadWeight = LoadQuantizer.snap(
        currentWeight * 0.90, equipment, unit,
      );
      final deloadSets = max(2, (setCount * 0.6).floor());
      return ProgressionSuggestion(
        suggestedWeight: deloadWeight,
        suggestedReps: repMax,
        suggestedSets: deloadSets,
        reasoning: 'Deload: reduce load 10%, volume 40%, keep RIR 3-5',
        isDeload: true,
        score: score,
        metrics: metrics,
      );
    }

    // A) Increase load +2%
    if (score >= 97 && metrics.topSetRir >= 2) {
      final nextWeight = LoadQuantizer.snap(
        currentWeight * 1.02, equipment, unit,
      );
      final clampedWeight = LoadQuantizer.clampToWeeklyCap(
        currentWeight, nextWeight, equipment, unit,
      );
      return ProgressionSuggestion(
        suggestedWeight: clampedWeight,
        suggestedReps: repMin,
        suggestedSets: setCount,
        reasoning: 'Strong session (score ${score.toStringAsFixed(0)}) — increase load ~2%',
        backoffWeight: LoadQuantizer.snap(clampedWeight * 0.90, equipment, unit),
        backoffSets: max(2, setCount - 1),
        score: score,
        metrics: metrics,
      );
    }

    // A) Increase load +1%
    if (score >= 94 && metrics.topSetRir >= 1) {
      final nextWeight = LoadQuantizer.snap(
        currentWeight * 1.01, equipment, unit,
      );
      final clampedWeight = LoadQuantizer.clampToWeeklyCap(
        currentWeight, nextWeight, equipment, unit,
      );
      return ProgressionSuggestion(
        suggestedWeight: clampedWeight,
        suggestedReps: repMin,
        suggestedSets: setCount,
        reasoning: 'Good session (score ${score.toStringAsFixed(0)}) — increase load ~1%',
        backoffWeight: LoadQuantizer.snap(clampedWeight * 0.90, equipment, unit),
        backoffSets: max(2, setCount - 1),
        score: score,
        metrics: metrics,
      );
    }

    // B) Micro-progression: add +1 rep
    if (score >= 88 && metrics.topSetRir >= 1) {
      final nextReps = min(metrics.topSetReps + 1, repMax);
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: nextReps,
        suggestedSets: setCount,
        reasoning: 'Solid session — add 1 rep before increasing load',
        score: score,
        metrics: metrics,
      );
    }

    // C) Hold
    if (score >= 80) {
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: metrics.topSetReps,
        suggestedSets: setCount,
        reasoning: 'Maintaining — repeat same prescription',
        score: score,
        metrics: metrics,
      );
    }

    // D) Reduce
    final reducedWeight = LoadQuantizer.snap(
      currentWeight * 0.95, equipment, unit,
    );
    return ProgressionSuggestion(
      suggestedWeight: reducedWeight,
      suggestedReps: repMin,
      suggestedSets: setCount,
      reasoning: 'Tough session (score ${score.toStringAsFixed(0)}) — reduce load 5%',
      score: score,
      metrics: metrics,
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/progression/strength_strategy_test.dart
```

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/progression/domain/strength_strategy.dart test/progression/strength_strategy_test.dart
git commit -m "feat: implement Strength mode progression strategy with e1RM tracking"
```

---

### Task 14: Hypertrophy mode strategy

**Files:**
- Create: `lib/features/progression/domain/hypertrophy_strategy.dart`
- Create: `test/progression/hypertrophy_strategy_test.dart`

- [ ] **Step 1: Write hypertrophy strategy tests**

Create `test/progression/hypertrophy_strategy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/hypertrophy_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  late HypertrophyStrategy strategy;

  setUp(() {
    strategy = HypertrophyStrategy();
  });

  group('double progression', () {
    test('increases load when all sets hit top of rep range', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 30, reps: 12, rir: 2, completed: true),
          const WorkoutSet(weight: 30, reps: 12, rir: 2, completed: true),
          const WorkoutSet(weight: 30, reps: 12, rir: 1, completed: true),
        ],
        currentWeight: 30,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );
      expect(result.suggestedWeight, greaterThan(30));
    });

    test('adds reps when min reps met but not all at max', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 30, reps: 10, rir: 2, completed: true),
          const WorkoutSet(weight: 30, reps: 9, rir: 2, completed: true),
          const WorkoutSet(weight: 30, reps: 8, rir: 1, completed: true),
        ],
        currentWeight: 30,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );
      expect(result.suggestedWeight, equals(30));
      expect(result.suggestedReps, greaterThan(8));
    });

    test('reduces load when reps below range', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 30, reps: 6, rir: 0, completed: true),
          const WorkoutSet(weight: 30, reps: 5, rir: 0, completed: true),
          const WorkoutSet(weight: 30, reps: 5, rir: 0, completed: true),
        ],
        currentWeight: 30,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );
      expect(result.suggestedWeight, lessThan(30));
    });
  });

  group('deload', () {
    test('triggers deload after 2 consecutive low scores', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 30, reps: 7, rir: 0, completed: true),
          const WorkoutSet(weight: 30, reps: 6, rir: 0, completed: true),
          const WorkoutSet(weight: 30, reps: 6, rir: 0, completed: true),
        ],
        currentWeight: 30,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(
          consecutiveLowScores: 2,
          scoreHistory: [70, 65],
        ),
      );
      expect(result.isDeload, true);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/progression/hypertrophy_strategy_test.dart
```

- [ ] **Step 3: Implement HypertrophyStrategy**

Create `lib/features/progression/domain/hypertrophy_strategy.dart`:

```dart
import 'dart:math';
import 'progression_strategy.dart';
import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_suggestion.dart';
import 'load_quantizer.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

class HypertrophyStrategy implements ProgressionStrategy {
  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    final workingSets = performedSets.where((s) => !s.isWarmup && s.completed).toList();
    if (workingSets.isEmpty) return const SessionMetrics();

    final totalReps = workingSets.fold(0, (sum, s) => sum + s.reps);
    final targetTotalReps = workingSets.length * repMax;
    final hardSetCount = workingSets.where((s) => s.rir <= 3).length;
    final totalTonnage = workingSets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);

    // Find top set
    double topWeight = 0;
    int topReps = 0;
    int topRir = 0;
    for (final s in workingSets) {
      if (s.weight > topWeight || (s.weight == topWeight && s.reps > topReps)) {
        topWeight = s.weight;
        topReps = s.reps;
        topRir = s.rir;
      }
    }

    return SessionMetrics(
      hardSetCount: hardSetCount,
      totalReps: totalReps,
      targetTotalReps: targetTotalReps,
      totalTonnage: totalTonnage,
      topSetWeight: topWeight,
      topSetReps: topReps,
      topSetRir: topRir,
    );
  }

  @override
  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    if (metrics.targetTotalReps <= 0) return 85;

    final repRatio = (metrics.totalReps / metrics.targetTotalReps).clamp(0.6, 1.2);
    final effortFactor = ((metrics.topSetRir - 1) / 3).clamp(0.0, 1.0);
    final score = 100 * (0.7 * repRatio + 0.3 * effortFactor);
    return score.clamp(0, 100);
  }

  @override
  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    // 2 consecutive sessions < 75 score
    if (history.consecutiveLowScores >= 2) return true;
    return false;
  }

  @override
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionHistory history,
  }) {
    final metrics = computeMetrics(
      performedSets: performedSets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      history: history,
    );
    final score = computeScore(metrics: metrics, history: history);
    final workingSets = performedSets.where((s) => !s.isWarmup && s.completed).toList();
    final setCount = workingSets.length;

    // Deload check
    if (shouldDeload(score: score, metrics: metrics, history: history)) {
      final deloadSets = max(2, (setCount * 0.5).floor());
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: repMin,
        suggestedSets: deloadSets,
        reasoning: 'Deload: reduce volume 50%, keep load, RIR 3-5',
        isDeload: true,
        score: score,
        metrics: metrics,
      );
    }

    final reps = workingSets.map((s) => s.reps).toList();
    final minReps = reps.reduce(min);
    final maxReps = reps.reduce(max);
    final lastSetRir = workingSets.last.rir;

    // A) Increase load — all sets hit range, max set at top, last set RIR >= 1
    if (minReps >= repMin && maxReps >= repMax && lastSetRir >= 1) {
      final increment = LoadQuantizer.minIncrement(equipment, unit);
      final nextWeight = LoadQuantizer.snap(
        currentWeight + increment, equipment, unit,
      );
      final clamped = LoadQuantizer.clampToWeeklyCap(
        currentWeight, nextWeight, equipment, unit,
      );
      return ProgressionSuggestion(
        suggestedWeight: clamped,
        suggestedReps: repMin,
        suggestedSets: setCount,
        reasoning: 'All sets hit top of range — increase load',
        score: score,
        metrics: metrics,
      );
    }

    // B) Add reps — min reps met, still room to grow
    if (minReps >= repMin && lastSetRir >= 1) {
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: min(minReps + 1, repMax),
        suggestedSets: setCount,
        reasoning: 'Add reps to lagging sets before increasing load',
        score: score,
        metrics: metrics,
      );
    }

    // C) Reduce — below range or RIR 0
    if (minReps < repMin || lastSetRir == 0) {
      final reduced = LoadQuantizer.snap(
        currentWeight * 0.95, equipment, unit,
      );
      return ProgressionSuggestion(
        suggestedWeight: reduced,
        suggestedReps: repMin,
        suggestedSets: setCount,
        reasoning: 'Reps below range or grinding — reduce load 5%',
        score: score,
        metrics: metrics,
      );
    }

    // Default: maintain
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: minReps,
      suggestedSets: setCount,
      reasoning: 'Maintaining current prescription',
      score: score,
      metrics: metrics,
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/progression/hypertrophy_strategy_test.dart
```

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/progression/domain/hypertrophy_strategy.dart test/progression/hypertrophy_strategy_test.dart
git commit -m "feat: implement Hypertrophy mode with double progression and volume tracking"
```

---

### Task 15: Endurance mode strategy

**Files:**
- Create: `lib/features/progression/domain/endurance_strategy.dart`
- Create: `test/progression/endurance_strategy_test.dart`

- [ ] **Step 1: Write endurance strategy tests**

Create `test/progression/endurance_strategy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/endurance_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  late EnduranceStrategy strategy;

  setUp(() {
    strategy = EnduranceStrategy();
  });

  group('reps-first progression', () {
    test('increases load when all sets hit top of range', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 20, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 20, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 20, reps: 25, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 20,
        repMin: 15,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );
      expect(result.suggestedWeight, greaterThan(20));
    });

    test('adds reps when in range but not at max', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 20, reps: 18, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 20, reps: 17, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 20, reps: 15, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 20,
        repMin: 15,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );
      expect(result.suggestedWeight, equals(20));
      expect(result.suggestedReps, greaterThan(15));
    });
  });

  group('deload', () {
    test('deloads after 3 stagnant exposures', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 20, reps: 15, rir: 1, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 20, reps: 14, rir: 0, completed: true, restSeconds: 60),
        ],
        currentWeight: 20,
        repMin: 15,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(
          exposuresSinceImprovement: 4,
        ),
      );
      expect(result.isDeload, true);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/progression/endurance_strategy_test.dart
```

- [ ] **Step 3: Implement EnduranceStrategy**

Create `lib/features/progression/domain/endurance_strategy.dart`:

```dart
import 'dart:math';
import 'progression_strategy.dart';
import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_suggestion.dart';
import 'load_quantizer.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

class EnduranceStrategy implements ProgressionStrategy {
  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    final workingSets = performedSets.where((s) => !s.isWarmup && s.completed).toList();
    if (workingSets.isEmpty) return const SessionMetrics();

    final totalReps = workingSets.fold(0, (sum, s) => sum + s.reps);
    final totalTonnage = workingSets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);
    final totalRestSeconds = workingSets.fold(0, (sum, s) => sum + s.restSeconds);

    // Approximate session time: 20s per set (for 15-25 reps) + rest
    final approxSetDuration = 20 * workingSets.length;
    final totalTimeSeconds = approxSetDuration + totalRestSeconds;
    final totalTimeMin = totalTimeSeconds / 60;
    final density = totalTimeMin > 0 ? totalTonnage / totalTimeMin : 0;

    double topWeight = 0;
    int topReps = 0;
    int topRir = 0;
    for (final s in workingSets) {
      if (s.weight >= topWeight) {
        topWeight = s.weight;
        topReps = s.reps;
        topRir = s.rir;
      }
    }

    return SessionMetrics(
      totalReps: totalReps,
      targetTotalReps: workingSets.length * repMax,
      totalTonnage: totalTonnage,
      density: density,
      totalTimeSeconds: totalTimeSeconds,
      topSetWeight: topWeight,
      topSetReps: topReps,
      topSetRir: topRir,
    );
  }

  @override
  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    if (metrics.targetTotalReps <= 0) return 85;

    final repRatio = (metrics.totalReps / metrics.targetTotalReps).clamp(0.6, 1.2);
    final effortFactor = ((metrics.topSetRir - 1) / 4).clamp(0.0, 1.0);
    return (100 * (0.7 * repRatio + 0.3 * effortFactor)).clamp(0, 100);
  }

  @override
  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    // Plateau: density hasn't improved for 3+ exposures
    return history.exposuresSinceImprovement >= 3;
  }

  @override
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionHistory history,
  }) {
    final metrics = computeMetrics(
      performedSets: performedSets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      history: history,
    );
    final score = computeScore(metrics: metrics, history: history);
    final workingSets = performedSets.where((s) => !s.isWarmup && s.completed).toList();
    final setCount = workingSets.length;

    // Deload
    if (shouldDeload(score: score, metrics: metrics, history: history)) {
      final deloadSets = max(2, (setCount * 0.6).floor());
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: repMin,
        suggestedSets: deloadSets,
        reasoning: 'Deload: reduce volume 40%, increase rest, RIR 3-5',
        isDeload: true,
        score: score,
        metrics: metrics,
      );
    }

    final reps = workingSets.map((s) => s.reps).toList();
    final minReps = reps.reduce(min);
    final lastSetRir = workingSets.last.rir;

    // A) All sets at top of range → increase load or add set (cap at 4)
    if (minReps >= repMax && lastSetRir >= 2) {
      if (setCount < 4) {
        return ProgressionSuggestion(
          suggestedWeight: currentWeight,
          suggestedReps: repMin,
          suggestedSets: setCount + 1,
          reasoning: 'All sets at max reps — add 1 set',
          score: score,
          metrics: metrics,
        );
      }
      final increment = LoadQuantizer.minIncrement(equipment, unit);
      final nextWeight = LoadQuantizer.snap(
        currentWeight + increment, equipment, unit,
      );
      return ProgressionSuggestion(
        suggestedWeight: nextWeight,
        suggestedReps: repMin,
        suggestedSets: setCount,
        reasoning: 'All sets at max reps, max sets — increase load',
        score: score,
        metrics: metrics,
      );
    }

    // B) In range — add reps
    if (minReps >= repMin && lastSetRir >= 2) {
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: min(minReps + 2, repMax),
        suggestedSets: setCount,
        reasoning: 'Add 1-2 reps to lowest set',
        score: score,
        metrics: metrics,
      );
    }

    // C) Below range or grinding — reduce load or increase rest
    final reduced = LoadQuantizer.snap(currentWeight * 0.95, equipment, unit);
    return ProgressionSuggestion(
      suggestedWeight: reduced,
      suggestedReps: repMin,
      suggestedSets: setCount,
      reasoning: 'Below range — reduce load 5% or increase rest',
      score: score,
      metrics: metrics,
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/progression/endurance_strategy_test.dart
```

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/progression/domain/endurance_strategy.dart test/progression/endurance_strategy_test.dart
git commit -m "feat: implement Endurance mode with density tracking and reps-first progression"
```

---

### Task 16: Integrate 3-mode engine and migrate old system

**Files:**
- Modify: `lib/features/progression/domain/progression_engine.dart`
- Modify: `lib/shared/models/program_exercise.dart`

- [ ] **Step 1: Update ProgressionEngine to route to strategies**

Replace `lib/features/progression/domain/progression_engine.dart`:

```dart
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';
import 'strength_strategy.dart';
import 'hypertrophy_strategy.dart';
import 'endurance_strategy.dart';
import 'models/progression_history.dart';

class ProgressionEngine {
  static final Map<ProgressionMode, ProgressionStrategy> _strategies = {
    ProgressionMode.strength: StrengthStrategy(),
    ProgressionMode.hypertrophy: HypertrophyStrategy(),
    ProgressionMode.endurance: EnduranceStrategy(),
  };

  static ProgressionStrategy getStrategy(ProgressionMode mode) {
    return _strategies[mode] ?? HypertrophyStrategy();
  }

  /// Main entry point — same signature pattern as before for backward compatibility
  static ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionMode mode,
    ProgressionHistory history = const ProgressionHistory(),
  }) {
    final strategy = getStrategy(mode);
    return strategy.suggest(
      performedSets: performedSets,
      currentWeight: currentWeight,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      equipment: equipment,
      unit: unit,
      history: history,
    );
  }
}
```

- [ ] **Step 2: Update ProgramExercise to use ProgressionMode enum**

In `lib/shared/models/program_exercise.dart`, change `progressionType` from `String` to `ProgressionMode`:

Update the field:
```dart
  final ProgressionMode progressionMode;
```

Update constructor default:
```dart
  this.progressionMode = ProgressionMode.hypertrophy,
```

Update `toJson()`:
```dart
  'progressionMode': progressionMode.name,
```

Update `fromJson()`:
```dart
  progressionMode: json['progressionMode'] != null
      ? ProgressionMode.values.firstWhere(
          (e) => e.name == json['progressionMode'],
          orElse: () => ProgressionMode.fromLegacy(json['progressionType']),
        )
      : ProgressionMode.fromLegacy(json['progressionType']),
```

This handles migration from old `progressionType` string field to new `progressionMode` enum.

- [ ] **Step 3: Update all references to old progression methods**

Search the codebase for references to the old `ProgressionEngine.suggest()` signature and `progressionType` string, update them to use the new `ProgressionMode` enum and `mode` parameter.

Key files to check:
- `lib/features/workout/presentation/workout_logging_screen.dart` — update suggestion calls
- `lib/features/programs/presentation/create_program_screen.dart` — update program creation
- `lib/app/providers/service_providers.dart` — update provider if needed

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/progression/ lib/shared/models/program_exercise.dart lib/shared/models/enums.dart
git commit -m "feat: integrate 3-mode progression engine with legacy migration"
```

---

### Task 17: Bundled exercise library

**Files:**
- Create: `assets/data/exercises.json`
- Modify: `lib/shared/models/exercise.dart`
- Create: `lib/features/exercises/data/exercise_repository.dart`
- Modify: `lib/app/providers/data_providers.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Extend Exercise model**

In `lib/shared/models/exercise.dart`, add fields:

```dart
class Exercise {
  final String id;
  final String name;
  final String category;
  final String type;
  final String muscle;
  final String equipment;
  final EquipmentType equipmentType;
  final String difficulty;
  final bool isFavorite;
  final List<String> muscleGroups;  // NEW: primary + secondary
  final String? instructions;       // NEW
  final bool isDefault;             // NEW: true = bundled, false = user-created

  const Exercise({
    required this.id,
    required this.name,
    this.category = '',
    this.type = '',
    this.muscle = '',
    this.equipment = '',
    this.equipmentType = EquipmentType.barbell,
    this.difficulty = 'Intermediate',
    this.isFavorite = false,
    this.muscleGroups = const [],
    this.instructions,
    this.isDefault = true,
  });
```

Update `toJson()`, `fromJson()`, and `copyWith()` to include the 3 new fields.

- [ ] **Step 2: Create bundled exercise JSON**

Create `assets/data/exercises.json` with a comprehensive exercise database. Structure:

```json
[
  {
    "id": "barbell_bench_press",
    "name": "Barbell Bench Press",
    "category": "Push",
    "type": "Compound",
    "muscle": "Chest",
    "equipment": "Barbell",
    "equipmentType": "barbell",
    "difficulty": "Intermediate",
    "muscleGroups": ["Chest", "Triceps", "Front Delts"],
    "instructions": "Lie on flat bench, grip bar slightly wider than shoulders, lower to chest, press up."
  }
]
```

Include 200+ exercises covering: Barbell (bench, squat, deadlift, OHP, rows, curls), Dumbbell (presses, flies, rows, curls, lateral raises), Machine (leg press, lat pulldown, cable crossover, leg curl, leg extension), Bodyweight (push-ups, pull-ups, dips, lunges), Cable (face pulls, tricep pushdowns, cable curls), Kettlebell (swings, goblet squats, Turkish get-ups).

- [ ] **Step 3: Register asset in pubspec.yaml**

In `pubspec.yaml`, add under `assets`:

```yaml
    - assets/data/
```

- [ ] **Step 4: Create ExerciseRepository**

Create `lib/features/exercises/data/exercise_repository.dart`:

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/exercise.dart';

class ExerciseRepository {
  final FirebaseFirestore _firestore;

  ExerciseRepository(this._firestore);

  /// Load bundled exercises from assets
  Future<List<Exercise>> loadBundledExercises() async {
    final jsonStr = await rootBundle.loadString('assets/data/exercises.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>)
            .copyWith(isDefault: true))
        .toList();
  }

  /// Load user-created exercises from Firestore
  Stream<List<Exercise>> watchUserExercises(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Exercise.fromJson(doc.data()).copyWith(isDefault: false))
            .toList());
  }

  /// Save a user-created exercise
  Future<void> createExercise(String uid, Exercise exercise) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .doc(exercise.id)
        .set(exercise.copyWith(isDefault: false).toJson());
  }

  /// Delete a user-created exercise
  Future<void> deleteExercise(String uid, String exerciseId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .doc(exerciseId)
        .delete();
  }
}
```

- [ ] **Step 5: Update data providers**

In `lib/app/providers/data_providers.dart`, update the exercise library provider to merge bundled + user exercises:

```dart
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final firestore = ref.watch(firestoreProvider)!;
  return ExerciseRepository(firestore);
});

final bundledExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.loadBundledExercises();
});

final userExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchUserExercises(uid);
});

final allExercisesProvider = Provider<List<Exercise>>((ref) {
  final bundled = ref.watch(bundledExercisesProvider).valueOrNull ?? [];
  final userExercises = ref.watch(userExercisesProvider).valueOrNull ?? [];

  // Merge: user exercises override bundled by name match
  final userNames = userExercises.map((e) => e.name.toLowerCase()).toSet();
  final filtered = bundled.where((e) => !userNames.contains(e.name.toLowerCase())).toList();
  return [...filtered, ...userExercises];
});
```

- [ ] **Step 6: Update firestore.rules for exercises subcollection**

In `firestore.rules`, add inside the `match /users/{uid}` block:

```
    match /exercises/{exerciseId} {
      allow read, write: if isOwner(uid);
    }
```

- [ ] **Step 7: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 8: Commit**

```bash
git add assets/data/exercises.json lib/shared/models/exercise.dart lib/features/exercises/data/exercise_repository.dart lib/app/providers/data_providers.dart pubspec.yaml firestore.rules
git commit -m "feat: add bundled exercise library with Firestore user exercise sync"
```

---

### Task 18: Local notifications

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/notification_service.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add flutter_local_notifications dependency**

In `pubspec.yaml`:

```yaml
  flutter_local_notifications: ^18.0.1
  permission_handler: ^11.3.1
```

```bash
flutter pub get
```

- [ ] **Step 2: Create NotificationService**

Create `lib/core/notification_service.dart`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _keyReminderEnabled = 'notif_reminder_enabled';
  static const _keyReminderHour = 'notif_reminder_hour';
  static const _keyReminderMinute = 'notif_reminder_minute';
  static const _keyStreakEnabled = 'notif_streak_enabled';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> weekdays, // 1=Mon, 7=Sun
  }) async {
    // Cancel existing reminders
    await cancelWorkoutReminders();

    for (final day in weekdays) {
      await _plugin.zonedSchedule(
        day, // unique ID per day
        'Time to train!',
        'Your workout is waiting. Let\'s go! 💪',
        _nextInstanceOfDayTime(day, hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminders',
            'Workout Reminders',
            channelDescription: 'Daily workout reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    // Save preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, true);
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> cancelWorkoutReminders() async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(day);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, false);
  }

  TZDateTime _nextInstanceOfDayTime(int weekday, int hour, int minute) {
    final now = TZDateTime.now(local);
    var scheduled = TZDateTime(local, now.year, now.month, now.day, hour, minute);

    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }
}
```

Note: This requires `timezone` package. Add to pubspec.yaml:
```yaml
  timezone: ^0.9.4
```

Add to the top of `notification_service.dart`:
```dart
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
```

Replace `TZDateTime` references with `tz.TZDateTime` and `local` with `tz.local`.

In `initialize()`, add:
```dart
tz_data.initializeTimeZones();
```

- [ ] **Step 3: Initialize in main.dart**

In `lib/main.dart`, after RevenueCat init:

```dart
import 'core/notification_service.dart';

// In main(), after RevenueCat:
await NotificationService().initialize();
```

- [ ] **Step 4: Add notification controls to settings screen**

In `lib/features/settings/presentation/settings_screen.dart`, wire the notification toggles to `NotificationService`:

```dart
// In the notifications section, connect toggles to:
NotificationService().scheduleWorkoutReminder(
  hour: selectedHour,
  minute: selectedMinute,
  weekdays: selectedDays,
);
// or
NotificationService().cancelWorkoutReminders();
```

- [ ] **Step 5: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/notification_service.dart lib/main.dart lib/features/settings/presentation/settings_screen.dart pubspec.yaml pubspec.lock
git commit -m "feat: add local notifications for workout reminders and streak alerts"
```

---

## Phase 4: Quality & Polish

### Task 19: Reusable AsyncValue and EmptyState widgets

**Files:**
- Create: `lib/shared/widgets/async_value_widget.dart`
- Create: `lib/shared/widgets/empty_state_widget.dart`

- [ ] **Step 1: Create AsyncValueWidget**

Create `lib/shared/widgets/async_value_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stack)? error;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call() ?? _defaultLoading(),
      error: (e, s) => error?.call(e, s) ?? _defaultError(context, e),
    );
  }

  Widget _defaultLoading() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _defaultError(BuildContext context, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: theme.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create EmptyStateWidget**

Create `lib/shared/widgets/empty_state_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp, color: theme.colorScheme.primary.withOpacity(0.4)),
            SizedBox(height: 16.h),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text(subtitle, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/async_value_widget.dart lib/shared/widgets/empty_state_widget.dart
git commit -m "feat: add reusable AsyncValueWidget and EmptyStateWidget"
```

---

### Task 20: Offline resilience — connectivity banner, workout recovery, and onboarding persistence

**Files:**
- Create: `lib/shared/widgets/offline_banner.dart`
- Modify: `lib/shared/widgets/custom_scaffold.dart`
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart`
- Modify: `lib/features/workout/presentation/workout_logging_screen.dart`

Note: `connectivity_plus` is already in pubspec.yaml — no new dependency needed for the offline banner.

- [ ] **Step 1: Create offline banner**

Create `lib/shared/widgets/offline_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
          color: Colors.orange.shade800,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 14.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                'You\'re offline — data will sync when connected',
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Add offline banner to CustomScaffold**

In `lib/shared/widgets/custom_scaffold.dart`, add the `OfflineBanner` at the top of the body stack:

```dart
import 'offline_banner.dart';

// In the build method, wrap the body in a Column:
Column(
  children: [
    const OfflineBanner(),
    Expanded(child: body),
  ],
)
```

- [ ] **Step 3: Add onboarding state persistence**

In `lib/features/onboarding/providers/onboarding_provider.dart`, add SharedPreferences caching.

Add import:
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
```

Add save/restore methods to `OnboardingNotifier`:

```dart
  static const _cacheKey = 'onboarding_state_cache';

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'goal': state.goal,
      'experience': state.experience,
      'style': state.style,
      'injuries': state.injuries.toList(),
      'units': state.units,
      'height': state.height,
      'weight': state.weight,
    };
    await prefs.setString(_cacheKey, json.encode(data));
  }

  Future<void> restoreFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return;

    final data = json.decode(cached) as Map<String, dynamic>;
    state = state.copyWith(
      goal: data['goal'],
      experience: data['experience'],
      style: data['style'],
      injuries: Set<String>.from(data['injuries'] ?? []),
      units: data['units'],
      height: data['height'],
      weight: data['weight'],
    );
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
```

Call `_saveToCache()` at the end of each setter method. Call `clearCache()` after successful `completeOnboarding()`.

- [ ] **Step 4: Add in-progress workout state recovery**

In `lib/features/workout/presentation/workout_logging_screen.dart`, add save/restore logic:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Add to _WorkoutLoggingScreenState:
static const _workoutCacheKey = 'in_progress_workout';

/// Save current workout state after each set update
Future<void> _saveWorkoutState() async {
  final prefs = await SharedPreferences.getInstance();
  final data = {
    'dayId': widget.dayId,
    'workoutName': _workoutName,
    'elapsedSeconds': _elapsedSeconds,
    'exercises': _exercises.map((e) => e.toJson()).toList(),
    'sets': _sets.map((key, value) => MapEntry(key, value.map((s) => s.toJson()).toList())),
    'savedAt': DateTime.now().toIso8601String(),
  };
  await prefs.setString(_workoutCacheKey, json.encode(data));
}

/// Check for and restore incomplete workout on screen init
Future<bool> _checkForRecovery() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(_workoutCacheKey);
  if (cached == null) return false;

  final data = json.decode(cached) as Map<String, dynamic>;
  final savedAt = DateTime.parse(data['savedAt']);
  // Only offer recovery if saved within last 24 hours
  if (DateTime.now().difference(savedAt).inHours > 24) {
    await prefs.remove(_workoutCacheKey);
    return false;
  }
  return true;
}

static Future<void> clearWorkoutCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_workoutCacheKey);
}
```

Call `_saveWorkoutState()` inside `_updateSet()` after each set modification.
Call `clearWorkoutCache()` when workout is completed.
In `initState()`, call `_checkForRecovery()` and show a dialog offering to resume if cached state exists.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/offline_banner.dart lib/shared/widgets/custom_scaffold.dart lib/features/onboarding/providers/onboarding_provider.dart lib/features/workout/presentation/workout_logging_screen.dart
git commit -m "feat: add offline banner, workout recovery, and onboarding state persistence"
```

---

### Task 21: Apply AsyncValue and EmptyState across screens

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`
- Modify: `lib/features/programs/presentation/programs_screen.dart`
- Modify: `lib/features/progress/presentation/progress_screen.dart`
- Modify: `lib/features/exercises/presentation/exercise_library_screen.dart`

- [ ] **Step 1: Update home screen**

In `lib/features/home/presentation/home_screen.dart`, replace manual `.when()` calls with `AsyncValueWidget`:

```dart
import '../../shared/widgets/async_value_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';

// Replace pattern:
// userProfile.when(loading: () => ..., error: (e, _) => ..., data: (profile) => ...)
// With:
AsyncValueWidget(
  value: userProfile,
  data: (profile) => _buildContent(profile),
)
```

- [ ] **Step 2: Add empty states to programs screen**

In `lib/features/programs/presentation/programs_screen.dart`, add empty state when no programs:

```dart
if (programs.isEmpty)
  EmptyStateWidget(
    icon: LucideIcons.dumbbell,
    title: 'No programs yet',
    subtitle: 'Create your first training program to get started',
    actionLabel: 'Create Program',
    onAction: () => context.push('/programs/create'),
  )
```

- [ ] **Step 3: Add empty states to progress and exercise screens**

Apply same patterns to `progress_screen.dart` and `exercise_library_screen.dart`.

- [ ] **Step 4: Verify build**

```bash
flutter build apk --debug
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart lib/features/programs/presentation/programs_screen.dart lib/features/progress/presentation/progress_screen.dart lib/features/exercises/presentation/exercise_library_screen.dart
git commit -m "feat: apply consistent AsyncValue and EmptyState patterns across all screens"
```

---

### Task 21.5: Haptic feedback on key interactions

**Files:**
- Modify: `lib/features/workout/presentation/workout_logging_screen.dart`
- Modify: `lib/features/achievements/presentation/achievements_screen.dart`

- [ ] **Step 1: Add haptic feedback to workout actions**

In `lib/features/workout/presentation/workout_logging_screen.dart`, import:

```dart
import 'package:flutter/services.dart';
```

Add haptics at key points:

```dart
// After marking a set as completed:
HapticFeedback.lightImpact();

// After completing entire workout:
HapticFeedback.mediumImpact();

// When rest timer completes:
HapticFeedback.selectionClick();
```

- [ ] **Step 2: Add haptic to achievement unlock**

In `lib/features/achievements/presentation/achievements_screen.dart`, when displaying an unlock banner:

```dart
HapticFeedback.heavyImpact();
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/workout/presentation/workout_logging_screen.dart lib/features/achievements/presentation/achievements_screen.dart
git commit -m "feat: add haptic feedback on set completion, workout finish, and achievement unlock"
```

---

### Task 22: Global error boundary

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add ErrorWidget.builder override**

In `lib/main.dart`, before `runApp()`:

```dart
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
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: add global error boundary for release mode"
```

---

### Task 23: Add legal links and version display

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Add privacy policy and terms links to settings**

In `lib/features/settings/presentation/settings_screen.dart`, add menu items in the Support section:

```dart
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';

// In the support section:
MenuItem(
  icon: LucideIcons.shield,
  title: 'Privacy Policy',
  onTap: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl)),
),
MenuItem(
  icon: LucideIcons.fileText,
  title: 'Terms of Service',
  onTap: () => launchUrl(Uri.parse(AppConstants.termsOfServiceUrl)),
),
```

Add `url_launcher` to `pubspec.yaml`:

```yaml
  url_launcher: ^6.3.1
```

- [ ] **Step 2: Verify build**

```bash
flutter pub get && flutter build apk --debug
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart lib/core/constants.dart pubspec.yaml pubspec.lock
git commit -m "feat: add legal links and URL launcher to settings"
```

---

## Phase 5: Store Readiness

### Task 24: Final QA checklist and store prep

This task is a manual verification checklist. No code changes — just testing.

- [ ] **Step 1: Run full test suite**

```bash
flutter test
```

All tests must pass.

- [ ] **Step 2: Build release APK and verify**

```bash
flutter build apk --release --dart-define=ENV=prod
```

- [ ] **Step 3: Build iOS (requires Mac with Xcode)**

```bash
flutter build ios --release --dart-define=ENV=prod
```

- [ ] **Step 4: Run through QA checklist**

Refer to the spec's Phase 5.5 Final QA Checklist:
- Fresh install flow
- Login flow
- Social auth (Google + Apple)
- Subscription lifecycle
- Offline workout
- Account deletion
- Force kill recovery
- Background/foreground
- Notifications
- Progressive overload across all 3 modes
- Edge cases
- Performance on both platforms

- [ ] **Step 5: Store listing preparation**

Gather:
- App screenshots (at least 4 per platform)
- Feature graphic (1024×500 for Google Play)
- Complete store description text
- Content rating questionnaires
- Data safety / App privacy declarations

- [ ] **Step 6: Final commit and tag**

```bash
git add -A
git commit -m "chore: final QA and store readiness preparation"
git tag v1.0.0
```

---

## Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| Phase 1 | Tasks 1-6.5 | Infrastructure: Crashlytics, Analytics, env config, release build, app icon, RevenueCat keys |
| Phase 2 | Tasks 7-11 | Auth: Google/Apple sign-in, account linking, account deletion, subscription flow |
| Phase 3 | Tasks 12-18 | Features: 3-mode PO engine (Strength/Hypertrophy/Endurance), exercise library, local notifications |
| Phase 4 | Tasks 19-23 | Quality: AsyncValue widgets, offline resilience, workout recovery, haptics, error boundaries, legal links |
| Phase 5 | Task 24 | Store: QA checklist, screenshots, store listings, release build |

Total: **~26 tasks** across **5 phases**

Each task is independently committable and the app should build successfully after each one.

### Key Dependencies (User-Provided)
- Apple Developer Account → needed before iOS signing (Task 4 iOS portion)
- RevenueCat API keys → needed before subscription testing (can use placeholders until then)
- Rat icon PNG → needed before app icon generation (Task 5)
- Privacy policy URL → needed before store submission (Task 23)
