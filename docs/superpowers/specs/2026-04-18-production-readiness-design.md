# GymRatz v1.0 — Production Readiness Design Spec

## Overview

Transform the GymRatz Flutter fitness tracking app from Beta/MVP state to a production-ready application suitable for release on Google Play and Apple App Store. The approach is **foundation-first**: harden infrastructure, then build missing features on a solid base, then polish and prepare for store submission.

**Target:** iOS + Android release with free tier + premium subscription ($5/month, 7-day trial)
**Architecture:** Flutter + Firebase (Auth, Firestore, Crashlytics, Analytics) + RevenueCat + Riverpod
**Scope:** Strict MVP — auth, onboarding, workout logging, programs, progress, achievements, subscription. No community features (deferred to v2).

---

## Current State Assessment

### What's Production-Ready
- All Firestore repositories implemented (workouts, programs, achievements, PRs, weight entries, user profiles)
- Riverpod providers properly wired with null-safety guards
- Firestore security rules locked down (owner-based access control)
- 18-step onboarding flow complete
- Workout logging functional with set-by-set tracking
- Basic progressive overload engine (LoadFirst/RepsFirst/Mixed)
- Cloud Functions basics (user create/delete triggers)
- Offline Firestore cache enabled (unlimited)

### What's Missing
- No Google/Apple Sign-In (Apple required for App Store)
- RevenueCat placeholder API keys (`appl_REPLACE_ME`, `goog_REPLACE_ME`)
- No Crashlytics, Analytics, or Performance monitoring
- No app icons, splash screen, or branding assets
- Android uses debug signing (no release keystore)
- iOS has no provisioning profiles
- Only 1 placeholder test file
- No offline persistence for onboarding state or in-progress workouts
- Exercise library is 55 hardcoded items in memory
- Progressive overload engine needs upgrade to full 3-mode system
- No local notifications
- No account deletion flow (required by both stores)
- No privacy policy or terms of service

---

## Phase 1: Infrastructure & Configuration

### 1.1 Firebase Observability
- Add `firebase_crashlytics` and `firebase_analytics` packages to `pubspec.yaml`
- Initialize both in `main.dart`:
  - Crashlytics: catch all Flutter framework errors via `FlutterError.onError`, catch async errors via `PlatformDispatcher.instance.onError`
  - Analytics: initialize `FirebaseAnalytics.instance`
- Add `firebase_performance` for network and screen render monitoring
- Define core analytics events:
  - `sign_up` (method: email/google/apple)
  - `login` (method: email/google/apple)
  - `workout_started`
  - `workout_completed` (duration, exercise_count, total_sets)
  - `program_created`
  - `achievement_unlocked` (achievement_id)
  - `subscription_started` (plan_id)
  - `subscription_restored`
  - `onboarding_completed` (step_count)
  - `onboarding_abandoned` (last_step)

### 1.2 Release Build Configuration

**Android:**
- Generate release keystore: `keytool -genkey -v -keystore gymratz-release.keystore -alias gymratz -keyalg RSA -keysize 2048 -validity 10000`
- Create `android/key.properties` (gitignored) with keystore path, password, alias
- Update `android/app/build.gradle.kts`:
  - Add `signingConfigs.release` block reading from `key.properties`
  - Set `buildTypes.release` to use release signing config
  - Enable R8/ProGuard with Firebase-compatible rules
- Set `applicationId` to `com.gymratz.gymratz`

**iOS:**
- Configure bundle identifier in Xcode
- Set up signing with Apple Developer account (once created)
- Add "Sign in with Apple" capability to App ID and entitlements
- Configure push notification entitlement (for future FCM, but capability needed now)

**Both platforms:**
- Version scheme: `1.0.0+1` (semver + build number, increment build number per release)

### 1.3 App Identity & Assets
- Configure `flutter_launcher_icons` package:
  - User provides rat icon asset
  - Generate all platform-specific icon sizes (Android adaptive icon + iOS icon set)
- Configure `flutter_native_splash` package:
  - Blue monochrome splash (#003A6B background or #FFFFFF with blue logo)
  - Matches design system
- Set app display name to "GymRatz" on both platforms (`AndroidManifest.xml` label + iOS `Info.plist` `CFBundleDisplayName`)

### 1.4 RevenueCat Configuration
- User provides real API keys from RevenueCat dashboard
- Replace placeholders in `lib/core/constants.dart`:
  - `revenueCatAppleApiKey` — real Apple key
  - `revenueCatGoogleApiKey` — real Google key
- Verify entitlement ID `pro` matches RevenueCat dashboard configuration
- Configure offerings and packages in RevenueCat dashboard (monthly $5, 7-day trial)

### 1.5 Environment Configuration
- Create `lib/core/env.dart` with enum `Environment { dev, prod }`
- Use `--dart-define=ENV=dev` / `--dart-define=ENV=prod` for build-time switching
- Dev mode: verbose logging, Firestore emulator option, sandbox RevenueCat
- Prod mode: Crashlytics enabled, production Firebase, live RevenueCat
- Add `.env.example` documenting required configuration

---

## Phase 2: Authentication & Subscription

### 2.1 Google Sign-In
- Add `google_sign_in` package to `pubspec.yaml`
- Implement `signInWithGoogle()` in `AuthRepository`:
  ```
  GoogleSignIn → GoogleSignInAccount → GoogleSignInAuthentication → AuthCredential → Firebase signInWithCredential
  ```
- Add Google Sign-In button to `login_screen.dart` following existing UI patterns
- Configure OAuth:
  - Android: Add SHA-1 (debug + release) to Firebase Console
  - iOS: Add reversed client ID from `GoogleService-Info.plist` to URL schemes in `Info.plist`

### 2.2 Apple Sign-In
- Add `sign_in_with_apple` package to `pubspec.yaml`
- Implement `signInWithApple()` in `AuthRepository`:
  ```
  SignInWithApple.getAppleIDCredential → OAuthCredential → Firebase signInWithCredential
  ```
- Add Apple Sign-In button on login screen — **iOS only** (use `Platform.isIOS` guard)
- Apple Developer setup:
  - Enable "Sign in with Apple" capability on App ID
  - Configure Service ID for web-based redirect (Firebase requirement)
  - Enable Apple provider in Firebase Auth console

### 2.3 Auth Flow Hardening
- Handle account linking: if user signs up with email then tries Google with the same email, offer to link accounts rather than showing a cryptic error
- Map all Firebase auth error codes to user-friendly messages (extend existing `_mapFirebaseError`)
- Add loading indicators during social auth flows (Google/Apple popups can take several seconds)
- Store auth method in user profile document (`authProvider: "email" | "google" | "apple"`) for display in profile screen

### 2.4 Subscription Flow Completion
- Wire `paywall_screen.dart` to real RevenueCat offerings:
  - Display actual pricing from `getOfferings()` (not hardcoded)
  - Show trial duration from package metadata
  - Handle purchase errors (user cancelled, payment declined, network error)
- Implement entitlement checks at feature gates:
  - Define which features are premium vs free-tier in a central config
  - Gate premium features with a consistent `isPro` check
- Add subscription status display in profile/settings:
  - Current plan, renewal date, trial status
  - "Manage Subscription" deep link to platform subscription settings
  - "Restore Purchases" button (required by App Store guidelines)

### 2.5 Account Management
- Account deletion flow (required by both App Store and Google Play):
  1. User taps "Delete Account" in settings
  2. Show confirmation dialog explaining data loss
  3. Re-authenticate user (Firebase requires recent auth for deletion)
  4. Delete Firestore user data (all subcollections)
  5. Delete Firebase Auth account
  6. Clear RevenueCat subscriber data
  7. Sign out and return to login screen
- Password change flow for email-authenticated users

---

## Phase 3: Core Feature Upgrades

### 3.1 Progressive Overload Engine — Full 3-Mode System

Replace the current simple engine with the full system from `Progressive_overload_schemes.md`.

**Strength Mode:**
- Target: Load increase at low-moderate reps, fatigue control
- Template: 3-6 sets × 1-6 reps, RIR 1-3
- Primary metric: e1RM (Epley formula: `weight × (1 + reps / 30)`)
- Scoring tiers:
  - Score ≥97% of previous e1RM → increase load +2%
  - Score ≥94% → increase load +1%
  - Score ≥90% → micro-progression (add reps at same load)
  - Score ≥85% → hold (repeat prescription)
  - Score <85% → reduce load -5%
- Plateau detection: no e1RM increase for ≥3 consecutive exposures
- Deload trigger: plateau + low RIR, or performance drop >3%
- Deload prescription: -10% load for 1 week, RIR 3-5

**Hypertrophy Mode:**
- Target: Effective reps near failure, volume progression
- Template: 2-5 sets × 6-15 reps, RIR 1-3
- Primary metric: Double progression (rep range + load)
- Progression logic:
  - All sets hit top of rep range → increase load (smallest available increment)
  - Most sets hit range → add reps to lagging sets
  - Sets below range → hold or reduce
- Volume tracking: count "hard sets" (RIR ≤3) per muscle group per week
  - Weekly targets: Beginner 6-10, Intermediate 10-16, Advanced 14-22
- Volume auto-regulation: suggest adding/removing sets based on target vs actual
- Deload trigger: 2 consecutive sessions with low scores or fatigue indicators

**Endurance Mode:**
- Target: Reps/density at submaximal loads
- Template: 2-4 sets × 12-25 reps, RIR 2-4
- Primary metric: Density (total work / time)
- Progression: reps-first at fixed load → rest reduction → timed density blocks
- Deload: reduce volume, increase rest, maintain RIR 3-5

**Shared Infrastructure:**
- `ProgressionEngine` class with strategy pattern — `StrengthStrategy`, `HypertrophyStrategy`, `EnduranceStrategy`
- Session metrics model: top set flag, hard set count, rest durations, block timing
- Equipment-aware load snapping (preserved from current system):
  - Barbell: 2.5kg / 5lb increments
  - Dumbbell: 2kg or 2.5kg / 5lb per hand
  - Machine stack: 2.5kg or 5kg / 5lb or 10lb
  - Plate-loaded: same as barbell
  - Bodyweight: reps → sets → harder variation → added load
- Safety caps: max 10% weekly load increase
- Backward compatibility: existing workout data migrates cleanly (LoadFirst maps to Hypertrophy, RepsFirst maps to Endurance, Mixed inferred from context)

### 3.2 Exercise Library — Bundled + Firestore Sync

**Bundled Database:**
- Create `assets/data/exercises.json` with 200+ exercises
- Each exercise entry: `id`, `name`, `category` (push/pull/legs/core/cardio), `muscleGroups` (primary + secondary), `equipmentType`, `instructions`, `isDefault: true`
- Cover all major equipment types: barbell, dumbbell, kettlebell, cable, machine, band, bodyweight
- Organized by movement pattern and muscle group

**Loading Strategy:**
- App reads bundled JSON at runtime for the default exercise catalog — these are NOT copied into each user's Firestore (avoids 200+ document writes per signup)
- User's Firestore (`users/{uid}/exercises/`) stores ONLY user-created and user-modified exercises
- At display time, merge bundled defaults + user exercises, with user entries taking precedence on name conflicts
- User-created exercises marked with `isDefault: false` to distinguish from bundled defaults

**Sync Mechanism:**
- Global exercise collection: `exercises_global/` (read-only for clients)
- On app launch, compare local `lastSyncTimestamp` with global collection's `lastUpdated`
- If global is newer, merge new/updated exercises (only `isDefault: true` entries)
- Never overwrite user-created exercises
- Sync runs in background, doesn't block app usage

**UI Integration:**
- Exercise library screen: search by name, filter by muscle group, filter by equipment
- "Custom" tab showing user-created exercises
- Exercise detail with instructions and equipment info
- "Add to Program" action from library

### 3.3 Local Notifications

**Package:** `flutter_local_notifications`

**Notification Types:**
- **Workout reminders:** User configures preferred training days and reminder time in settings. Scheduled repeating notifications on selected days.
- **Rest day nudge:** If no workout logged for 2+ days, trigger a "Don't forget to train!" notification
- **Streak maintenance:** When user has an active streak ≥3 days, send reminder on training days: "Keep your X-day streak alive!"

**Implementation:**
- `NotificationService` class managing all scheduling
- Permission handling: iOS requests via `requestPermissions()`, Android 13+ requests `POST_NOTIFICATIONS`
- Settings screen controls: toggle each notification type, set reminder time
- Store notification preferences in SharedPreferences (fast access, no Firestore dependency)
- Cancel/reschedule notifications when user changes settings or completes a workout

---

## Phase 4: Quality & Polish

### 4.1 Error/Loading/Empty States
- Create reusable `AsyncValueWidget<T>` that handles Riverpod's `AsyncValue` pattern:
  - `.loading()` → skeleton shimmer or centered spinner
  - `.error()` → error message + retry button
  - `.data()` → render content
- Create `EmptyStateWidget` with illustration placeholder + message + CTA button
- Audit every screen and apply consistent patterns:
  - Home: empty calendar + "Create your first program"
  - Programs: "No programs yet" + create button
  - Progress: "Complete your first workout to see progress"
  - Achievements: show locked achievements (not empty)
  - Exercise library: "No exercises found" for empty search results
- Global error boundary: `ErrorWidget.builder` override for release mode — shows recovery dialog instead of red error screen

### 4.2 Offline Resilience
- **Connectivity indicator:** Subtle top banner when device is offline ("You're offline — data will sync when connected")
- **In-progress workout protection:**
  - Save workout state to SharedPreferences after each set logged
  - On app restart, check for incomplete workout and offer to resume
  - Clear saved state on workout completion
- **Onboarding state persistence:**
  - Cache onboarding selections in SharedPreferences at each step
  - On app crash/restart during onboarding, resume from last completed step
  - Clear cache after successful account creation
- **Firestore offline verification:**
  - Test all CRUD operations function correctly when offline
  - Verify conflict resolution when same data modified offline on two devices

### 4.3 UI Polish Pass
- **Design system audit:** Verify all screens use `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius` from theme — no hardcoded values
- **Responsive layout:** Test on iPhone SE (375pt), iPhone 15 Pro Max (430pt), small Android (360dp), large Android tablet — ensure no overflow, clipping, or text truncation
- **Dark mode:** Verify every screen renders correctly in dark mode (theme toggle exists — verify consistency)
- **Keyboard handling:** Ensure all forms with text fields scroll correctly, no input hidden behind keyboard, proper `FocusNode` management
- **Haptic feedback:** Add subtle haptics on:
  - Completing a set (light impact)
  - Finishing a workout (medium impact)
  - Unlocking achievement (success notification)
  - Rest timer completion (notification)
- **Animation polish:** Smooth page transitions, list item animations, progress bar fills

### 4.4 Performance
- **Lazy loading:** Paginate workout history and exercise library queries (Firestore `limit()` + cursor pagination)
- **Widget rebuild optimization:** Audit Riverpod `watch` vs `select` usage — use `select` to only rebuild on relevant state changes
- **Image handling:** Cache profile photos with proper memory/disk cache limits
- **Scrolling:** Profile the workout logging screen (most interaction-heavy) — ensure 60fps during rapid set entry
- **Startup time:** Defer non-critical initialization (analytics, notifications) to post-first-frame

---

## Phase 5: Store Readiness

### 5.1 Legal & Compliance
- **Privacy policy:** Create hosted page covering:
  - Data collected (email, workout data, body measurements, device info)
  - Third-party services (Firebase, RevenueCat, Google Analytics)
  - Data retention and deletion (account deletion available in-app)
  - Contact information
- **Terms of service:** Standard SaaS terms covering usage, subscription billing, liability
- **In-app links:** Add privacy policy and terms links in:
  - Settings screen
  - Sign-up flow (checkbox or footer link)
  - App Store / Google Play listing
- **GDPR:** Account deletion (Phase 2) covers the right to erasure. No EU-specific consent management needed at 1,000 MAU scale unless targeting EU specifically.

### 5.2 Store Listings
- **App metadata:**
  - App name: "GymRatz — Workout Tracker"
  - Short description: "Track workouts, build programs, crush PRs"
  - Full description: Feature-focused copy highlighting progressive overload, offline logging, achievements
  - Category: Health & Fitness
  - Keywords/tags: workout tracker, gym, progressive overload, fitness, weight training
- **Visual assets:**
  - App icon (from Phase 1.3)
  - Feature graphic 1024×500 (Google Play)
  - Screenshots: minimum 4 per platform — onboarding, home/calendar, active workout, progress
  - User provides or takes screenshots from running app on real devices
- **Content rating:** Complete questionnaire on both platforms (no violent/sexual content — straightforward)

### 5.3 Apple App Store Specific
- Register app in App Store Connect
- App Review guidelines compliance:
  - Subscription pricing clearly displayed before purchase
  - "Restore Purchases" button visible and functional
  - No misleading free claims (free with premium features clearly stated)
  - Sign in with Apple available
- App Tracking Transparency:
  - If Firebase Analytics collects IDFA → add ATT prompt
  - If not collecting IDFA → declare "App Does Not Track" in App Store Connect
- Export compliance: standard HTTPS encryption declaration (no custom encryption)
- Age rating: 4+ (fitness tracking, no objectionable content)

### 5.4 Google Play Specific
- **Data safety form:** Declare all data types:
  - Personal info (email, name) — collected, not shared
  - Health & fitness (workout data, body measurements) — collected, not shared
  - App activity (analytics) — collected, not shared
  - Device info (crash logs) — collected, not shared
- **Target API level:** Ensure `compileSdkVersion` and `targetSdkVersion` meet current Google Play requirements
- **Release tracks:** Internal testing → Closed beta (invite testers) → Production
- **App signing:** Enroll in Google Play App Signing (upload key vs signing key)

### 5.5 Final QA Checklist
- [ ] Fresh install flow: launch → onboarding → signup → first workout → completion
- [ ] Login flow: existing user → login → lands on home with data
- [ ] Social auth: Google sign-in on Android + iOS, Apple sign-in on iOS
- [ ] Subscription: purchase → verify entitlement → cancel → verify downgrade → restore
- [ ] Offline workout: airplane mode → log full workout → reconnect → verify Firestore sync
- [ ] Account deletion: delete → verify Firestore wiped → verify auth account removed → verify RevenueCat cleared
- [ ] Force kill: kill app mid-workout → reopen → verify recovery prompt
- [ ] Background/foreground: background during workout → return → verify state preserved
- [ ] Notifications: verify reminders fire at configured times
- [ ] Progressive overload: complete workouts across all 3 modes → verify suggestions are correct
- [ ] Edge cases: no internet on first launch, expired subscription, very long workout (50+ sets)
- [ ] Performance: smooth scrolling, fast navigation, no ANRs or jank
- [ ] Both platforms: run full checklist on real iOS device + real Android device

---

## What You Need to Provide

| Item | When Needed | Notes |
|------|-------------|-------|
| Apple Developer Account | Phase 1 (iOS signing) | $99/year enrollment at developer.apple.com |
| RevenueCat API keys | Phase 1.4 | Create project at app.revenuecat.com, register iOS + Android apps |
| Rat icon asset | Phase 1.3 | High-res PNG (1024×1024 minimum) for app icon generation |
| Android release keystore password | Phase 1.2 | You choose, I configure |
| Privacy policy hosting | Phase 5.1 | Can use GitHub Pages, Notion, or any hosted URL |
| Store screenshots | Phase 5.2 | Taken from running app on real devices |

---

## Migration & Compatibility

- Existing Firestore data structure is preserved — no breaking schema changes
- Progressive overload mode migration: `LoadFirst` → `Hypertrophy`, `RepsFirst` → `Endurance`, `Mixed` → inferred from exercise context
- Bundled exercise library seeds alongside existing sample data without duplication (matched by exercise name)
- All changes developed on a dedicated branch, merged to main when validated

---

## Out of Scope (v2)

- Community programs and ratings
- Public program sharing
- Social features and user profiles
- Advanced comparisons (population/animal)
- Auto-generated programs from exercise history
- FCM push notifications (server-triggered)
- Apple Health / Google Fit integration
- Data export
- Body measurement tracking beyond weight
- Web app
