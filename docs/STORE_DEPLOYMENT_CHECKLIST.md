# Store Deployment Checklist

## Prerequisites (Your Tasks)

### Apple (iOS / TestFlight)
- [ ] Enroll in Apple Developer Program ($99/year) at https://developer.apple.com/programs/enroll/
- [ ] Create App ID in Apple Developer portal (bundle ID: `com.gymratz.gymratz`)
- [ ] Create app in App Store Connect (https://appstoreconnect.apple.com)
- [ ] Set up In-App Purchases in App Store Connect:
  - Monthly: `monthly` — $4.99/month with 7-day free trial
  - Yearly: `yearly` — $39.99/year with 7-day free trial
- [ ] Create Subscription Group called "GymRatz Premium"
- [ ] Add Privacy Policy URL: `https://gymratz-app.github.io/privacy`
- [ ] Add tester emails to TestFlight internal testing group
- [ ] Generate App Store distribution certificate + provisioning profile
- [ ] Update `ios/fastlane/Appfile` with your Apple ID and Team ID

### Google Play (Android / Internal Testing)
- [ ] Create Google Play Developer account ($25 one-time) at https://play.google.com/console
- [ ] Create app in Google Play Console (package: `com.gymratz.gymratz`)
- [ ] Generate upload keystore:
  ```bash
  keytool -genkey -v -keystore gymratz-release.keystore -alias gymratz -keyalg RSA -keysize 2048 -validity 10000
  ```
- [ ] Create `android/key.properties` from `android/key.properties.example`
- [ ] Set up In-App Subscriptions in Play Console:
  - Product ID: `monthly` — $4.99/month with 7-day free trial
  - Product ID: `yearly` — $39.99/year with 7-day free trial
- [ ] Create internal testing track and add tester emails
- [ ] Create Play Store service account for CI uploads:
  - Google Cloud Console → IAM → Service Accounts
  - Grant "Service Account User" role
  - Download JSON key → save as `android/fastlane/play-store-key.json`
  - Link service account in Play Console → Settings → API access

### RevenueCat
- [ ] Create project at https://app.revenuecat.com
- [ ] Add Apple App Store app (paste App-Specific Shared Secret)
- [ ] Add Google Play Store app (paste service account JSON)
- [ ] Create entitlement: `GymRatz`
- [ ] Create products: `monthly`, `yearly` (link to store products)
- [ ] Create offering "default" with both packages
- [ ] Enable 7-day free trial on both products
- [ ] Copy API keys:
  - Apple API key → set as `RC_APPLE_KEY` in CI secrets
  - Google API key → set as `RC_GOOGLE_KEY` in CI secrets

### GitHub Pages (Legal)
- [ ] Create GitHub repository (e.g., `gymratz-app/gymratz-app.github.io`)
- [ ] Push `docs/legal/` content to the repo root
- [ ] Enable GitHub Pages in repo settings (source: main branch, root)
- [ ] Verify pages load: https://gymratz-app.github.io/privacy and /terms

### Firebase
- [ ] Verify Firebase project is on Blaze plan (required for Cloud Functions if used)
- [ ] Enable App Check for production security (optional but recommended)
- [ ] Add production SHA-1 and SHA-256 to Firebase Console (from release keystore):
  ```bash
  keytool -list -v -keystore gymratz-release.keystore -alias gymratz
  ```

---

## GitHub Actions Secrets (CI/CD)

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

### Android
- `KEYSTORE_BASE64` — base64-encoded keystore file
- `KEY_ALIAS` — keystore alias (e.g., "gymratz")
- `KEY_PASSWORD` — keystore password
- `STORE_PASSWORD` — store password
- `PLAY_STORE_JSON_KEY_BASE64` — base64-encoded service account JSON
- `RC_GOOGLE_KEY` — RevenueCat Google API key

### iOS
- `APPLE_CERTIFICATES_P12_BASE64` — distribution certificate
- `APPLE_CERTIFICATES_PASSWORD` — certificate password
- `APPLE_PROVISIONING_PROFILE_BASE64` — provisioning profile
- `APPLE_APP_ID` — App Store Connect app ID (numeric)
- `APP_STORE_CONNECT_API_KEY_ID` — API key ID
- `APP_STORE_CONNECT_ISSUER_ID` — Issuer ID
- `APP_STORE_CONNECT_API_KEY_BASE64` — .p8 key file
- `RC_APPLE_KEY` — RevenueCat Apple API key

---

## Build & Upload Commands

### Local Testing
```bash
# Android debug (with admin mode for testing without RevenueCat)
flutter run --dart-define=ADMIN_MODE=true

# Android release APK
flutter build apk --release --dart-define=RC_GOOGLE_KEY=your_key

# iOS release IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=RC_APPLE_KEY=your_key
```

### Fastlane (CI or local)
```bash
# Android → Play Store Internal Testing
cd android && fastlane internal

# iOS → TestFlight
cd ios && fastlane beta
```

### GitHub Actions (automated)
- Push a tag `v1.0.0` to trigger release workflow
- Or manually trigger from Actions tab with platform choice

---

## Post-Upload Checklist
- [ ] Verify TestFlight build appears and send to testers
- [ ] Verify Play Store internal testing track has the build
- [ ] Test subscription flow end-to-end on both platforms
- [ ] Test 7-day trial starts correctly
- [ ] Verify RevenueCat dashboard shows test purchases
- [ ] Test expired state (use RevenueCat sandbox to expire trial)
- [ ] Test restore purchases works
