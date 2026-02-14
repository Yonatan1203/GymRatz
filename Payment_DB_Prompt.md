1) Prompt for Claude (copy/paste)

You are a senior Flutter engineer. Build the subscription-only gym diary app foundation in Flutter with:
- Firebase (Auth + Firestore) for accounts and data (workouts, programs, PRs, achievements).
- RevenueCat for iOS+Android auto-renewable subscriptions with a 7-day free trial.
- A “pro” entitlement that gates premium features; free users can view limited history, pro users get full features.
- Offline-first workout logging (Firestore offline cache), then sync.
- Data must persist across reinstall/device as long as the user signs in again.

Deliverables:
1) Flutter project architecture (folders, state management suggestion, key services).
2) Exact pubspec dependencies for: firebase_core, firebase_auth, cloud_firestore, RevenueCat Purchases SDK, and any needed utilities.
3) Firebase initialization code using FlutterFire-generated firebase_options.dart and Firebase.initializeApp with DefaultFirebaseOptions.currentPlatform (include the main() snippet). 
4) Firestore schema proposal:
   - users/{uid}
   - users/{uid}/workouts/{workoutId}
   - users/{uid}/programs/{programId}
   - users/{uid}/prs/{exerciseId}
   - community_programs/{programId} (public, link-sharing focus)
   Include example document JSON 
You are a senior Flutter engineer. Implement the foundation for my gym diary app:

Tech:
- Flutter + Firebase (Auth + Cloud Firestore) for accounts and data.
- RevenueCat for iOS/Android subscriptions with a 7‑day free trial.
- One entitlement: `pro`, which gates premium features.

Build:
1) Project structure + required pubspec dependencies.
2) Firebase setup code: initializeApp using FlutterFire-generated firebase_options.dart.
3) Firestore schema + example docs:
   - users/{uid}
   - users/{uid}/workouts/{workoutId}
   - users/{uid}/programs/{programId}
   - users/{uid}/prs/{exerciseId}
   - community_programs/{programId} (public uploads/links)
4) Firestore Security Rules:
   - Users can read/write only their own data.
   - community_programs readable by authed users; only ownerUid can create/update; ownerUid immutable.
5) RevenueCat in Flutter:
   - Configure SDK, fetch offerings, show paywall screen, purchase, restore, check entitlement `pro`.
   - EntitlementService (stream/notifier) exposing isPro.
6) Offline-first logging with Firestore cache; sync later.
7) App flow: login/onboarding → main app → premium gating/upsell.

Constraints:
- No secrets in code. Use placeholders for API keys/product IDs.
- Provide code snippets in Dart + rules in a separate block.
Ask me only for: bundleId, applicationId, RevenueCat API key(s), and product identifiers.