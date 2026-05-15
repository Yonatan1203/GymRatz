# Google Play Internal Testing Deployment

Goal: Get GymRatz installable via a Google Play internal testing link.

## What's Already Done

- [x] Upload keystore generated (`android/gymratz-release.keystore`)
- [x] `key.properties` configured and gitignored
- [x] Firebase: `google-services.json`, SHA-1 fingerprint, Google Sign-In enabled
- [x] Legal pages hosted (privacy policy + terms of service)
- [x] RevenueCat SDK integrated in app
- [x] GitHub Secrets set: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`, `REVENUECAT_GOOGLE_KEY`
- [x] CI release workflow configured
- [x] Template app icon generated

---

## Step 1: Create Google Play Developer Account

**If you don't already have one:**

1. Go to https://play.google.com/console
2. Sign in with your Google account
3. Pay the $25 one-time registration fee
4. Fill out your developer profile (name, email, phone)
5. Wait for account verification (can take up to 48 hours, usually faster)

---

## Step 2: Create the App in Play Console

1. In Play Console, click **"Create app"**
2. Fill in:
   - **App name:** GymRatz
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free (subscriptions are handled in-app)
3. Accept the declarations and click **Create app**

---

## Step 3: Complete the Store Listing

Go to **Grow > Store listing** (or the setup checklist will guide you):

1. **Short description** (max 80 chars):
   > Track workouts, smash PRs, and level up your fitness journey.

2. **Full description** (max 4000 chars):
   > GymRatz helps you build and follow workout programs, track your progress with detailed exercise logs, and crush personal records. Whether you're training solo or working with a coach, GymRatz keeps your fitness journey organized and motivating.
   >
   > Features:
   > - Create and follow custom workout programs
   > - Log exercises with sets, reps, and weights
   > - Track personal records automatically
   > - Work with coaches who can assign programs
   > - Beautiful charts showing your progress over time

3. **App icon:** Upload `assets/icon/app_icon.png` (1024x1024, already generated)

4. **Feature graphic:** Required (1024x500 px). You can create a simple one:
   - Use https://www.canva.com — search "Google Play feature graphic" template
   - Use your brand color #003A6B as background, add "GymRatz" text and the dumbbell icon
   - Export as 1024x500 PNG

5. **Screenshots:** You need at least 2 phone screenshots
   - Run the app on your phone or emulator
   - Take screenshots of: home screen, workout logging, progress chart
   - Minimum 2 screenshots, recommended 4-8
   - Must be between 320px and 3840px, 16:9 or 9:16 aspect ratio

---

## Step 4: Complete the Content Rating Questionnaire

Go to **Policy > App content > Content rating**:

1. Click **Start questionnaire**
2. **Category:** Select "Utility, Productivity, Communication, or Other"
3. Answer the questions — for a fitness tracker with no violent/sexual/gambling content, most answers will be "No"
4. Click **Save** then **Submit**
5. You'll get a rating like "Everyone" — this is expected

---

## Step 5: Set Up the Internal Testing Track

Go to **Testing > Internal testing**:

1. Click **"Create new release"**
2. For the first time, you need to upload an AAB manually:
   - Build locally: `flutter build appbundle --release`
   - The AAB will be at `build/app/outputs/bundle/release/app-release.aab`
   - Upload this file
3. Give the release a name (e.g., "1.0.0 Internal Test")
4. Click **Save** then **Review release** then **Start rollout to Internal testing**

**Add testers:**
1. Go to **Testing > Internal testing > Testers**
2. Create an email list (e.g., "GymRatz Testers")
3. Add the email addresses of people you want to test
4. Copy the **internal testing link** — this is the URL you'll share!

---

## Step 6: Create Google Play Subscriptions

Go to **Monetize > Products > Subscriptions**:

### Create "monthly" subscription:
1. Click **Create subscription**
2. **Product ID:** `monthly`
3. **Name:** GymRatz Monthly
4. Click **Create**
5. Add a **base plan:**
   - Billing period: 1 month
   - Price: $4.99
   - Under "Offers", add a free trial offer: 7 days
6. **Activate** the base plan

### Create "yearly" subscription:
1. Click **Create subscription**
2. **Product ID:** `yearly`
3. **Name:** GymRatz Yearly
4. Click **Create**
5. Add a **base plan:**
   - Billing period: 1 year
   - Price: $39.99
   - Under "Offers", add a free trial offer: 7 days
6. **Activate** the base plan

---

## Step 7: Connect RevenueCat to Google Play

1. Log into https://app.revenuecat.com
2. Go to your GymRatz project
3. Under the Google Play app:
   - Verify the API key is correct (check if `test_QPrCcBDWPprQOPWibhFNchqaTPB` is a test or production key — for internal testing, test key is fine)
4. **Products tab:** Add products `monthly` and `yearly` (matching the Product IDs from Step 6)
5. **Entitlements tab:** Create entitlement `GymRatz`, attach both products
6. **Offerings tab:** Create offering `default`, add both products as packages (monthly → `$rc_monthly`, yearly → `$rc_annual`)

---

## Step 8: Create Play Store Service Account (for CI auto-upload)

This lets GitHub Actions upload builds directly. **You can skip this for now** and upload manually from Step 5 until you want automation.

1. Go to https://console.cloud.google.com
2. Select your project (or create one linked to your Play Console)
3. Go to **IAM & Admin > Service Accounts**
4. Click **Create Service Account**
   - Name: `gymratz-play-upload`
   - Role: no role needed here (permissions are set in Play Console)
5. Click on the created account > **Keys** > **Add Key** > **Create new key** > JSON
6. Download the JSON file
7. Go to Play Console > **Settings > API access**
   - Link the Google Cloud project if not linked
   - Find your service account and click **Manage Play Console permissions**
   - Grant: **Release to testing tracks** and **View app information and download bulk reports**
   - Apply to app: GymRatz
8. Add to GitHub Secrets:
   - Secret name: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
   - Value: the entire contents of the JSON file

---

## Step 9: First Build & Test

### Option A: Manual upload (simplest for first time)
```bash
# Build the release AAB
flutter build appbundle --release --dart-define=RC_GOOGLE_KEY=your_revenuecat_key

# Find it at: build/app/outputs/bundle/release/app-release.aab
# Upload manually to Play Console > Internal testing > Create new release
```

### Option B: CI upload (after Step 8 is done)
```bash
# Tag a release to trigger the CI workflow
git tag v1.0.0
git push origin v1.0.0

# Or trigger manually: GitHub repo > Actions > Release Build > Run workflow > android
```

### Testing on device:
1. Open the internal testing link on your Android device
2. Install from the Play Store
3. Verify:
   - Google Sign-In works
   - You can create a program and log a workout
   - Subscription paywall appears
   - Subscription purchase flow works (test cards in internal testing)

---

## Summary Checklist

| Step | Task | Required for link? |
|------|------|--------------------|
| 1 | Google Play Developer account | Yes |
| 2 | Create app in Play Console | Yes |
| 3 | Store listing (title, description, icon, screenshots) | Yes |
| 4 | Content rating questionnaire | Yes |
| 5 | Internal testing track + upload AAB + add testers | Yes |
| 6 | Create subscriptions | No (app works without, but paywall won't complete) |
| 7 | Connect RevenueCat | No (same as above) |
| 8 | Service account for CI | No (can upload manually) |
| 9 | Build & test | Yes |

**Minimum to get a working link: Steps 1-5 and 9.**
Subscriptions (6-7) can be set up after you verify the app installs and runs.
