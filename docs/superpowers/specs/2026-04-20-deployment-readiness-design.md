# Deployment Readiness Design Spec

**Date:** 2026-04-20
**Status:** Approved
**Goal:** Prepare GymRatz for deployment to App Store (TestFlight) and Google Play (Internal Testing) with a small group of testers.

---

## Overview

The app's UI/UX is complete. This spec covers everything needed to go from "working locally" to "testers can install it from the stores." Work is divided into 4 sequential phases, each building on the previous.

---

## Phase 1 — Cleanup & Foundation

### 1.1 Remove Dark/Light Mode Toggle

- Remove the quick-toggle button from the top-right corner of all screens
- Theme system remains intact (light, dark, system modes all still work)
- Settings screen provides the only theme control with three options: Light, Dark, System Default
- New users default to System Default

### 1.2 Subscription Model Rework

**Current state:** Free tier with "Upgrade to Pro" buttons scattered throughout the app, placeholder RevenueCat keys.

**New model:**
- All users start with a **7-day free trial** with full access
- Two paid plans: **Monthly ($4.99/mo)** and **Yearly ($39.99/yr)**
- No free tier exists after trial expiration

**Remove:**
- All "Upgrade to Pro" buttons and related UI elements throughout the app
- Free-tier gating logic (the concept of "free features" vs "pro features" goes away)

**Read-only mode (post-trial, no subscription):**
- User can view: workout history, programs, progress charts, achievements, profile
- User cannot: log workouts, create/edit programs, edit profile, modify training settings
- A persistent but non-intrusive banner guides them to subscribe
- Paywall screen shows monthly vs yearly comparison with savings highlighted

**Technical:**
- RevenueCat remains single source of truth for entitlement
- App checks entitlement on launch and before any write action
- Single `pro` entitlement granted by either subscription product
- Trial period configured in App Store Connect and Google Play Console (not client-side)

### 1.3 Main Program Backend

**Data model:**
- Add `mainProgramId` field to the user document in Firestore
- Value is either a program document ID or null (no main program)

**Programs screen:**
- Main program has a clear visual badge/label (e.g., "Active" badge)
- Other programs show a "Set as Main" action (button or menu option)
- Tapping "Set as Main" updates `mainProgramId` on the user document immediately
- No restrictions on switching — instant, unlimited

**Calendar integration:**
- Calendar pulls scheduled workouts only from the main program
- No main program = empty calendar (no placeholder data)
- Switching main program updates the calendar from today forward; past logged workouts are unaffected

**Workout tab integration:**
- If `mainProgramId` is null, workout tab shows empty state: "No main program set" + link/button to Programs page

---

## Phase 2 — Feature Fixes

### 2.1 Workout Tab Redesign

**Current state:** Shows "today's workout" only.

**New design: Weekly view (Monday–Sunday)**
- Displays all scheduled workouts from the main program for the current week
- Each day shows: day name, workout name, target muscle groups, completion status (scheduled / completed / missed)
- Today is visually highlighted
- Tapping a day's workout opens the workout logging screen for that specific day

**Out-of-date workout confirmation:**
- When a user taps to start a workout that is NOT today's date, show a confirmation dialog:
  - Title: "Different Day"
  - Message: "This workout is scheduled for [Day Name]. Are you sure you want to log it today?"
  - Actions: "Cancel" / "Start Anyway"
- User must confirm before the logging screen opens
- The workout is logged with today's actual date regardless (it records when you actually did it)

**Edge cases:**
- No main program: entire tab shows empty state (from Phase 1)
- Week has no scheduled workouts (program has fewer days than 7): show the scheduled days, others show as rest days

### 2.2 Backend Audit

Systematic end-to-end verification of all backend services. Each area is tested and produces a pass/fail result.

**Authentication:**
- Email/password: sign-up, login, logout, password reset
- Session persistence across app restarts
- Error handling: invalid credentials, network errors, duplicate emails

**Firestore operations (per collection):**
- Users: create, read, update profile fields
- Programs: create, read, update, delete, set main program
- Workouts: create (log), read history, update sets
- Exercises: read built-in library, create custom, update, delete custom
- Achievements: read, unlock/update

**Firestore security rules:**
- Verify owner-based access: user A cannot read/write user B's data
- Verify unauthenticated requests are rejected
- Verify all collections are covered by rules

**Cloud Functions:**
- User creation trigger: verify default data is set up correctly for new accounts
- User deletion trigger: verify all user data is purged from all collections

**Offline behavior:**
- Log a workout with airplane mode on
- Verify data appears locally immediately
- Restore connectivity, verify data syncs to Firestore

**RevenueCat integration:**
- Entitlement check returns correct status for: active subscriber, trial user, expired user
- Subscription state transitions work (active → expired, expired → renewed)

**Data integrity:**
- No orphaned documents (workout references a deleted program, etc.)
- First-time user with empty collections doesn't cause crashes
- Account deletion removes all data cleanly

**Output:** A checklist document with pass/fail for each test. Failures become fix tasks.

---

## Phase 3 — Deployment Infrastructure

### 3.1 GitHub Actions CI/CD

**PR workflow (runs on every pull request to main):**
- `flutter analyze` — static analysis, catches lint errors
- `flutter test` — runs all unit/widget tests
- Build debug APK — catches compile errors
- Workflow fails if any step fails, blocking merge

**Release workflow (manual trigger from main branch):**
- Triggered manually via `workflow_dispatch` or on version tag push
- Builds signed release artifacts for both platforms
- Uploads to stores automatically

**Android release steps:**
1. Set up Flutter environment
2. Decode signing keystore from GitHub secret
3. Build AAB (`flutter build appbundle --release`)
4. Upload to Google Play Internal Testing track via Fastlane (`fastlane supply`)

**iOS release steps:**
1. Set up Flutter environment + Xcode
2. Install certificates and provisioning profiles (Fastlane Match or manual decode from secrets)
3. Build IPA (`flutter build ipa --release --export-options-plist=...`)
4. Upload to TestFlight via Fastlane (`fastlane pilot upload`)

**GitHub Secrets required:**
- `ANDROID_KEYSTORE_BASE64` — release keystore, base64 encoded
- `ANDROID_KEY_ALIAS` — key alias
- `ANDROID_KEY_PASSWORD` — key password
- `ANDROID_STORE_PASSWORD` — store password
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — service account for Play Console API
- `APPLE_CERTIFICATE_BASE64` — distribution certificate
- `APPLE_PROVISIONING_PROFILE_BASE64` — provisioning profile
- `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8` — App Store Connect API key
- `FIREBASE_OPTIONS` — if needed for build

### 3.2 Release Signing

**Android:**
- Generate release keystore: `keytool -genkey -v -keystore gymratz-release.keystore ...`
- Create `android/key.properties` (gitignored) for local builds
- Store keystore as base64 GitHub secret for CI
- Configure `android/app/build.gradle` to use release signing config

**iOS:**
- Enroll in Apple Developer Program ($99/year) — blocker, must be done manually
- Create App ID in Apple Developer portal (bundle ID: `com.gymratz.app` or similar)
- Create distribution certificate and provisioning profile
- Configure Xcode project with correct team ID and bundle ID
- For CI: export cert + profile as base64 secrets, or use Fastlane Match with a private git repo

### 3.3 Legal Content + Hosting

**Hosting: GitHub Pages (free)**
- Create a simple static site (can be a separate repo like `gymratz-legal` or a `/docs` folder in this repo published via GitHub Pages)
- URL: `gymratz-app.github.io` or custom domain later
- Minimal design — just needs to be readable and accessible

**Privacy Policy must cover:**
- What data is collected: email, name, body measurements, profile images, workout logs, app usage analytics
- How data is stored: Firebase (Google Cloud), data centers location
- Third-party services: RevenueCat (subscription management), Firebase Analytics
- Data retention: kept until account deletion
- User rights: can request data export, can delete account (in-app)
- Children: app not directed at children under 13
- Contact information for privacy inquiries

**Terms of Service must cover:**
- Service description and acceptable use
- Account responsibilities
- Subscription terms: billing cycle, auto-renewal, 7-day trial
- Refund policy: handled by Apple/Google per their store policies
- Content ownership: user owns their data
- Limitation of liability
- Termination conditions
- Governing law (personal name, your jurisdiction)

**Account Deletion Flow (required by both stores):**
- Located in: Settings > Account > Delete Account
- Confirmation dialog with warning: "This will permanently delete all your data including workout history, programs, and achievements. This cannot be undone."
- Requires re-authentication before deletion (security)
- Triggers Cloud Function that purges all user data from all Firestore collections
- Signs user out and returns to login screen

**In-app links:**
- Settings screen links to Privacy Policy and Terms of Service (opens in browser)
- Sign-up/login screen has links to both (required by stores)

---

## Phase 4 — Store Submission

### 4.1 App Store Connect (iOS)

**Prerequisites:** Apple Developer account active, signing configured.

**Setup:**
- Create new app in App Store Connect
- Bundle ID: match Xcode project (e.g., `com.gymratz.app`)
- Category: Health & Fitness
- Age rating: 4+ (no objectionable content)
- Pricing: Free (subscriptions are in-app purchases)

**TestFlight Internal Testing:**
- Add testers by Apple ID email
- Internal testers (up to 100) get builds immediately, no App Review needed
- Each build auto-expires after 90 days

**Required assets:**
- App icon: 1024x1024 PNG (no alpha)
- Screenshots: minimum 6.7" (iPhone 15 Pro Max) and 6.5" (iPhone 11 Pro Max)
- App description, keywords, support URL, privacy policy URL

**Subscriptions:**
- Create subscription group (e.g., "GymRatz Premium")
- Add two products: Monthly ($4.99) and Yearly ($39.99)
- Configure 7-day free trial on both
- Link product IDs to RevenueCat

### 4.2 Google Play Console (Android)

**Prerequisites:** Google Play Developer account (already have), release keystore configured.

**Setup:**
- Create new app in Google Play Console
- Category: Health & Fitness
- Content rating: complete questionnaire
- Data safety form: declare all collected data types and purposes
- Target audience and content: 18+ (fitness app)

**Internal Testing Track:**
- Create internal testing track
- Add testers by email or Google Group
- Testers get a link to opt-in, then can install from Play Store
- No review needed for internal track

**Required assets:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: minimum 2, recommended 8 (phone form factor)
- Short description (80 chars), full description (4000 chars)
- Privacy policy URL

**Subscriptions:**
- Create two subscription products in Google Play Console
- Monthly ($4.99) and Yearly ($39.99) with 7-day free trial
- Link product IDs to RevenueCat

### 4.3 RevenueCat Configuration

- Create RevenueCat project for GymRatz (if not already done)
- Add iOS app (with App Store Connect shared secret)
- Add Android app (with Google Play service credentials)
- Replace placeholder API keys in code with real RevenueCat public API keys
- Create products mapping to store product IDs
- Create `pro` entitlement, attach both subscription products
- Configure trial: 7-day (set in stores, RevenueCat detects automatically)
- Test with sandbox/test accounts on both platforms before going live

### 4.4 Tester Access

- Collect tester emails from your group
- iOS: Add to TestFlight internal testing group, they receive email invite
- Android: Add to internal testing track, share opt-in link
- Provide testers with: install instructions, known limitations, feedback channel
- Feedback channel: shared Google Doc, group chat, or simple form — whatever works for the group size

---

## Execution Order

```
Phase 1 (Cleanup & Foundation)
  └─ 1.1 Remove theme toggles
  └─ 1.2 Subscription model rework
  └─ 1.3 Main program backend
       ↓
Phase 2 (Feature Fixes)
  └─ 2.1 Workout tab weekly view
  └─ 2.2 Backend audit + fixes
       ↓
Phase 3 (Deployment Infra)
  └─ 3.1 GitHub Actions CI/CD
  └─ 3.2 Release signing
  └─ 3.3 Legal content + hosting + account deletion
       ↓
Phase 4 (Store Submission)
  └─ 4.1 App Store Connect setup
  └─ 4.2 Google Play Console setup
  └─ 4.3 RevenueCat real configuration
  └─ 4.4 Tester access distribution
```

---

## Out of Scope

- Public release / open beta
- App Store Review submission (this spec covers internal/TestFlight testing only)
- Marketing, ASO optimization
- Advanced analytics dashboards
- Push notifications (local notifications for reminders may be added later)
- Web version
- Google Sign-In / Apple Sign-In (can be added before public release, not required for internal testing)

---

## Blockers & Dependencies

| Blocker | Required For | Action |
|---------|-------------|--------|
| Apple Developer account enrollment | All iOS work (Phase 3+4) | Enroll ASAP, 24-48hr approval |
| Real RevenueCat API keys | Subscription testing | Create RevenueCat project |
| App icons and splash screen | Store submissions | Design or generate assets |
| Tester email list | Phase 4 | Collect from your group |
