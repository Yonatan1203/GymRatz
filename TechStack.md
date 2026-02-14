## Tech Stack (Firebase + RevenueCat)

### App
- Flutter (Dart), iOS 14+, Android 8+

### State management
- Riverpod (preferred) + Provider only for simple DI (optional)

### Data (offline-first)
- Cloud Firestore (primary cloud DB; live sync + offline support on iOS/Android) [web:120][web:118]
- Firebase Auth (user accounts / UID identity) [web:60]
- Optional: Drift (SQLite) only if you need heavy local analytics/history queries; otherwise skip.

### Payments
- RevenueCat (`purchases_flutter`) for subscriptions + entitlement gating (“pro”) [web:126]
- Apple/Google store subscriptions configured in App Store Connect / Play Console (RevenueCat links to these; it doesn’t replace creating the products) [web:74]

### Navigation / UI
- go_router
- fl_chart (progress charts)

### Notifications
- flutter_local_notifications (local reminders)

### Architecture
- Feature-first + clean-ish layers:
  - data (Firebase/RevenueCat integration, repos)
  - domain (entities/usecases)
  - presentation (UI)

### Key packages (core)
- flutter_riverpod
- firebase_core + firebase_auth + cloud_firestore [web:60][web:120]
- purchases_flutter [web:126]
- go_router
