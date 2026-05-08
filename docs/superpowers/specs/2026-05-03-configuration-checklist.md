# GymRatz — Configuration Checklist

Everything that needs to be configured/provided before the app can be fully tested.

## Firebase

- [ ] Firebase Auth: verify Google Sign-In is enabled in console
- [ ] Firebase Auth: verify Apple Sign-In is enabled in console
- [ ] Deploy updated Firestore security rules (with coach rules)
- [ ] Create Firestore composite indexes (invite_codes by code+status)
- [ ] Create admin Firebase Auth account: `admin-user@gymratz.app` — note UID
- [ ] Create admin Firebase Auth account: `admin-coach@gymratz.app` — note UID
- [ ] Seed `users/{admin_user_uid}` doc with `role: "admin_user"`
- [ ] Seed `users/{admin_coach_uid}` doc with `role: "admin_coach"`
- [ ] Seed `coaches/{admin_coach_uid}` doc with unlimited plan
- [ ] Verify Firebase Crashlytics is enabled (optional for testing)

## RevenueCat

- [ ] Replace `RC_APPLE_KEY` placeholder (`appl_REPLACE_ME`) with real API key
- [ ] Verify `RC_GOOGLE_KEY` (`test_QPrCcBDWPprQOPWibhFNchqaTPB`) is correct
- [ ] Create subscription product: `coach_5` (5 clients tier)
- [ ] Create subscription product: `coach_10` (10 clients tier)
- [ ] Create subscription product: `coach_20` (20 clients tier)
- [ ] Verify individual products exist: `monthly`, `yearly`
- [ ] Verify entitlement `GymRatz` exists with all products attached
- [ ] Decide: reuse `GymRatz` entitlement for coach plans OR create separate `GymRatz_Coach`

## App Store Connect (iOS)

- [ ] Apple Developer Program membership active ($99/year)
- [ ] App registered in App Store Connect
- [ ] In-app purchase products created: `monthly`, `yearly`, `coach_5`, `coach_10`, `coach_20`
- [ ] Subscription group configured (group individual + coach plans)
- [ ] Sandbox test accounts created for purchase testing
- [ ] Sign In with Apple capability enabled on App ID

## Google Play Console (Android)

- [ ] Google Play Developer account active ($25 one-time)
- [ ] App registered in Play Console
- [ ] Subscription products created (same IDs: `monthly`, `yearly`, `coach_5`, `coach_10`, `coach_20`)
- [ ] License testing emails added (Settings > License testing)
- [ ] SHA-1 / SHA-256 fingerprints registered in Firebase project

## Build Environment Variables

| Variable | Purpose | Current Value | Action Needed |
|----------|---------|---------------|---------------|
| `RC_APPLE_KEY` | RevenueCat iOS API key | `appl_REPLACE_ME` | Replace with real key |
| `RC_GOOGLE_KEY` | RevenueCat Android API key | `test_QPrCcBDWPprQOPWibhFNchqaTPB` | Verify correct |
| `ADMIN_MODE` | Debug entitlement bypass | `false` | Can remove after role-based bypass |
| `ENV` | Environment (dev/prod) | `dev` | Keep as dev for testing |

## Required Files to Verify

| File | Location | Status |
|------|----------|--------|
| `google-services.json` | `android/app/` | Verify exists |
| `GoogleService-Info.plist` | `ios/Runner/` | Verify exists |
| `firebase_options.dart` | `lib/` | Exists |

## Google Sign-In (if used)

- [ ] OAuth 2.0 Client ID configured for iOS
- [ ] OAuth 2.0 Client ID configured for Android
- [ ] SHA-1 fingerprint added to Firebase project (Android)

## Apple Sign-In (if used)

- [ ] Sign In with Apple capability on App ID in Apple Developer portal
- [ ] Service ID configured (for web/Android flows if needed)

---

## Priority Order for Testing

1. Firebase Auth accounts (admin) — needed first
2. Firestore rules deployment — needed for any data access
3. RevenueCat keys — needed for subscription testing
4. Store products — needed for actual purchase flows
5. Everything else — nice to have for full production
