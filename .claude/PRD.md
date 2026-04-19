# PRD.md

# GymRatz Product Requirements Document

## 1. Project overview

| Field                 | Details                                             |
| --------------------- | --------------------------------------------------- |
| Product name          | GymRatz                                             |
| Product type          | Subscription-based fitness and workout tracking app |
| Platforms             | iOS and Android                                     |
| Framework             | Flutter                                             |
| Backend               | Firebase                                            |
| Subscription platform | RevenueCat                                          |
| Release model         | Free app with premium subscription                  |
| Planned pricing       | $5/month with 7-day trial                           |
| Expected scale        | ~1,000 MAU at launch                                |
| Web app               | Not in scope                                        |

GymRatz is a mobile workout tracking app focused on structured training, progressive overload, exercise history, calendar-based workout planning, achievements, and premium subscription access. Users complete onboarding, create or sign into an account, and then use the app to follow programs, log workouts, track progress, and manage profile settings.

## 2. Product goal

GymRatz helps users train consistently and improve over time by making it easy to plan workouts, log sets, track progression, and stay motivated through streaks, achievements, reminders, and premium features. The product should feel fast, clear, and reliable during active workouts, especially in low-connectivity situations.

## 3. Users

### Primary users

- Lifters tracking gym workouts and progressive overload.
- Users training in gym, home, or street/bodyweight contexts.
- Beginners to advanced users with different experience levels captured during onboarding.

### User needs

- Quickly log workouts and sets during training.
- Track weight, reps, RIR, progress history, and PRs over time.
- Follow scheduled workouts on a calendar and maintain streaks.
- Use the app offline and sync later.
- Access premium features through a clean subscription flow.

## 4. Core experience

### Entry flow

On app launch, GymRatz checks Firebase Authentication state. Signed-out users enter the standalone onboarding/login flow, while signed-in users go directly into the main app flow.

### Onboarding flow

The onboarding is a standalone 18-step flow that collects fitness goals, experience, workout frequency, training context, workout style, nutrition focus, accountability preference, session length, injury history, units, plan preview, profile summary, email capture, notification opt-in, Apple Health connection, app showcase, and acquisition source. The flow includes a progress indicator and should preserve user selections on back navigation.

### Main app flow

After sign-in, the app checks RevenueCat customer info and unlocks premium features when the `pro` entitlement is active. If the entitlement is not active, the app shows a paywall or upsell while still allowing the defined free-tier experience.

## 5. Navigation

The main app uses five primary tabs:

1. Home / Calendar
2. Today / Active workout
3. Progress
4. Achievements
5. Profile / Settings

Secondary navigation may include:

- Programs
- Export data
- Community (future)

## 6. Features

### 6.1 Authentication

- Email/password authentication.
- Google sign-in.
- Apple sign-in where applicable.
- Sign out.
- Session persistence across launches.

### 6.2 Subscription

- RevenueCat integration on iOS and Android.
- Premium entitlement source of truth is RevenueCat, not local state.
- Support trial, purchase, cancel, upgrade, downgrade, and restore flows.
- Include a manual Restore Purchases action.

### 6.3 Onboarding

- 18 screens total with progress indicator.
- Fitness-specific questions and summary.
- Resume/edit onboarding answers later from profile/settings.

### 6.4 Home / Calendar

- Monthly calendar with scheduled, completed, missed, and current-day states.
- Quick stats such as weekly volume, streak, and recent PRs.
- Upcoming workout preview.
- Optional ad-hoc workout entry.

### 6.5 Today / Active workout

- Show today’s scheduled workout with context such as gym, home, or street.
- Show last session summary and suggested targets per exercise.
- Log sets with immediate save behavior.
- Rest timer support during workout flow.
- Complete workout summary with volume delta, PRs, and streak updates.

### 6.6 Programs

- Main program selection and saved templates.
- Create/edit program days and exercises.
- Configure rep ranges, target RIR, progression mode, and context.
- Switching main program updates future schedule while preserving past logs.

### 6.7 Progress

- Recent workouts list.
- Per-exercise history graph and/or table.
- PR highlights and trend tracking.
- Body measurement and related progress tracking if enabled.

### 6.8 Achievements

- Streak and milestone-based unlocks.
- Volume, strength, consistency, and context-specific achievements.
- Unlock banners after workout completion.

### 6.9 Profile / Settings

- User profile editing.
- Units selection: metric or imperial.
- Notification preferences and reminder times.
- Progression settings and increments by training context.
- Data export and delete/reset if supported.

### 6.10 Exercise system

- Built-in and user-created exercises.
- Equipment type metadata such as barbell, dumbbell, kettlebell, machine, cable, band, or bodyweight.
- Equipment reminders such as belt, straps, or chalk.
- Saved exercises and exercise creation flow.

## 7. Functional requirements

### Workout logging

- Users must be able to start and complete a workout session.
- Users must be able to log per-set weight, reps, RIR, warmup state, and rest timing.
- Workout logging should work offline and sync later through Firestore cache/sync behavior.

### Calendar and scheduling

- Scheduled workouts must appear on a calendar.
- Completed, missed, rest-day, and scheduled statuses must be represented clearly.
- Changing the main program should affect future scheduling only.

### Progression

- The system should support exercise progression settings with rep ranges, target RIR, increments, and progression modes such as load-first, reps-first, and mixed.
- Last-session performance should be available to suggest next targets.

### Premium gating

- Premium access should be checked after authentication via RevenueCat entitlement.
- Subscription status may be mirrored to Firebase, but entitlement should remain the premium source of truth.

### Notifications

- Daily reminders, trial-end messaging, streak alerts, and renewal tips should be supported through FCM or related infrastructure.

## 8. Non-functional requirements

### Performance

- Active workout interactions must feel fast and reliable during training.
- Scrolling and navigation should remain smooth on modern iOS and Android devices.

### Offline support

- Workout logging should function offline and synchronize later.
- Partial in-progress data should be protected from accidental loss during spotty connectivity.

### Security

- Users should only read and write their own Firestore data through security rules.
- Sensitive account and subscription flows must avoid insecure local-only gating.

### Reliability

- Crash reporting and analytics should be configured via Firebase tools.
- Core flows should cover loading, empty, and error states.

## 9. Data model summary

### Core entities

The product domain includes users, user profiles, user settings, exercises, exercise equipment reminders, programs, program days, program day exercises, workout sessions, workout session exercises, workout sets, exercise progression configs, exercise progression state, calendar entries, streak state, achievements, and user achievements.

### Important implementation notes

- User settings include notifications, rest timer defaults, available increments by context, progression mode, and language.
- Program entities define structure for training plans, program days, and exercise prescriptions.
- Workout entities capture actual performed sessions and detailed set logs.
- Achievement entities support unlock state and progress tracking.
- Community program entities are future-facing and require backend support beyond the core diary feature set.

## 10. Design system

GymRatz uses a blue monochrome palette with:

- Primary: `#3776A1`
- Primary dark: `#003A6B`
- Primary light: `#89CFF1`
- Accent: `#5293BB`
- Accent medium: `#6EB1D6`
- Accent deep: `#1B5886`
- Background: `#FFFFFF`
- Surface: `#F5F7FA`
- Text primary: `#111827`
- Text secondary: `#6B7280`
- Text tertiary: `#9CA3AF`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`

The UI should remain clean, fitness-focused, and readable during active use, especially on the Today screen and onboarding flow.

## 11. Analytics and observability

Track at minimum:

- Sign-up completion.
- Sign-in success/failure.
- Subscription events.
- Workouts started/completed.
- Retention-related events.
- Crashes and stability signals via Crashlytics.

## 12. Technical stack

- Flutter for app development.
- Firebase Authentication for auth.
- Cloud Firestore for app data.
- Firebase Storage for small profile images if needed.
- Firebase Cloud Messaging for notifications.
- Firebase Analytics and Crashlytics for observability.
- RevenueCat for subscriptions.
- Optional Cloud Functions for scheduled tasks and data cleanup.

## 13. Constraints

- No web version in this release.
- iOS and Android are the target platforms.
- Phone auth is intentionally excluded to reduce cost/complexity.
- Infrastructure should remain cost-aware at around 1,000 MAU.

## 14. Risks

- Scope creep across onboarding, subscriptions, community, and advanced progression.
- Data complexity in workout/program/progression models.
- Subscription edge cases across trial, restore, cancel, and renewal.
- Offline sync correctness during active workout logging.

## 15. Milestones

### Milestone 1: Foundation

- Flutter app structure
- Firebase integration
- Auth flow
- Theme and design system
- RevenueCat SDK setup

### Milestone 2: Onboarding and entry

- 18-step onboarding
- Account creation/sign-in
- Auth state routing into app flow

### Milestone 3: Core workout experience

- Home/calendar
- Today workout flow
- Programs
- Offline set logging

### Milestone 4: Progress and motivation

- Progress views
- Achievements
- Notifications
- Analytics instrumentation

### Milestone 5: Launch readiness

- QA across iOS/Android
- Restore purchases and subscription testing
- Store assets and legal requirements
- Beta distribution and release prep

## 16. Acceptance criteria

- A signed-out user enters onboarding/login and a signed-in user enters the main app correctly.
- A subscribed user gets premium access based on RevenueCat entitlement.
- A user can log a workout with sets, reps, weight, and RIR even when temporarily offline.
- The calendar reflects scheduled and completed workouts correctly.
- The app exposes progress history and achievement state without blocking the core workout flow.
- Core subscription flows, auth flows, and workout logging flows are testable and stable on iOS and Android.

## 17. Future scope

- Community programs and ratings.
- Public program sharing.
- Advanced comparisons or novelty stats such as population/animal comparisons, if productized thoughtfully.
- More automation around generated programs from logged exercises.
