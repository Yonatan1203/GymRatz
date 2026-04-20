/// App-wide constants and RevenueCat configuration.
class AppConstants {
  AppConstants._();

  // RevenueCat API Keys — pass via: --dart-define=RC_GOOGLE_KEY=goog_xxx
  static const String revenueCatAppleApiKey =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: 'appl_REPLACE_ME');
  static const String revenueCatGoogleApiKey =
      String.fromEnvironment('RC_GOOGLE_KEY',
          defaultValue: 'test_QPrCcBDWPprQOPWibhFNchqaTPB');

  // RevenueCat identifiers
  static const String entitlementId = 'GymRatz';

  // Product identifiers (must match RevenueCat dashboard)
  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';

  // App info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://gymratz-app.github.io/privacy';
  static const String termsOfServiceUrl = 'https://gymratz-app.github.io/terms';
  static const String faqUrl = 'https://gymratz-app.github.io/faq';
}
