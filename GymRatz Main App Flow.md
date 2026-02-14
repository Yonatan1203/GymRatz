# GymRatz — Main App Flow (Short, Firebase + RevenueCat)

## Standalone onboarding (separate flow)
Onboarding is a standalone flow that runs only until the user creates an account or signs in (Firebase Auth). Once an account is registered/signed in, the user enters the Main App Flow and stays there unless they sign out. [web:142]

Flow:
- Launch → Auth check
- If signed out → Onboarding/Login (standalone)
- If signed in → Main App Flow

## Entry & subscription gating (after account exists)
After sign-in, the app checks RevenueCat `CustomerInfo` and unlocks premium features if entitlement `pro` is active; otherwise it shows the paywall/upsell. RevenueCat entitlements are the recommended way to manage access levels like `pro`. [web:139]



## Product summary
Progressive overload diary: user logs performance (weight/reps/RIR + context), app suggests next targets. Data is stored in Cloud Firestore (sync + offline cache) so it survives reinstall and works cross-device. [web:7]

## Entry & subscription gating
1. App launch → Firebase Auth check.
2. If signed out → Onboarding/Login.
3. If signed in → Fetch RevenueCat CustomerInfo and check entitlement `pro`. [web:139][web:135]
4. If `pro` active → full access; if not → show paywall/upsell + allow limited free view (you decide the limits). [web:139]

Notes:
- Provide a manual “Restore purchases” button (user-initiated) which calls RevenueCat restore flow. [web:135]

## Navigation (simple)
Bottom tabs (5):
1. Home (Calendar)
2. Today (Active workout)
3. Progress
4. Achievements
5. Profile/Settings

Side menu:
- Programs
- Export data
- Community (future)

## Core screens
### Home (Calendar)
- Monthly calendar: scheduled, completed, missed, today.
- Quick stats: weekly volume, streak, recent PR.
- Upcoming workout preview + “Log Ad‑Hoc Workout”.

### Today (Active workout)
- Shows today’s scheduled workout and context (Gym/Home/Street).
- Per exercise: last session summary + suggested target.
- Log set → saves immediately (works offline via Firestore cache), starts rest timer. [web:7]
- Complete workout → summary (volume delta, PRs, streak update).

### Programs
- Main Program (pinned) + saved programs/templates.
- Create/Edit: days → exercises → targets (rep range/RIR/progression rules) → schedule → save as Main.
- Switching program updates future calendar; past logs stay unchanged.

### Progress
- Recent workouts list.
- Per-exercise history: graph + table, PR highlights.

### Achievements
- Streaks + milestones (volume/strength/consistency/context).
- Unlock banners after workout completion.

### Profile/Settings
- Profile + units + progression settings.
- Notifications toggles.
- Data: export, delete/reset (if you support it).

## Data + sync model (what changed)
- **Source of truth for training data:** Firestore under `users/{uid}/...` (workouts, programs, PRs, achievements). Offline: Firestore caches data in-app and syncs when online. [web:7]
- **Source of truth for premium access:** RevenueCat entitlement `pro` (do not rely on local flags). [web:139]
- Cancel/resubscribe: user keeps training history because it’s in Firestore; subscription only gates features. [web:7]

## Key user flows (compressed)
Daily:
1) Reminder → open Today → log sets → complete → stats/achievements → calendar updates. [web:7]

Program change:
Programs → switch Main → future schedule recalculates → next Today uses new rules.

Ad-hoc workout:
Home → Log Ad‑Hoc → does not modify the scheduled program’s progression baseline (your business rule).

Community (future, links-first):
Upload/share program link → stored as a public `community_programs` doc; browsing is minimal.
