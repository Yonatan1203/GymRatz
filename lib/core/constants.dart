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
  static const String productWeekly = 'weekly';
  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';

  // Free tier limits
  static const int freeMaxActivePrograms = 1;
  static const int freeHistoryWeeks = 2;

  // App info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://gymratz.app/privacy';
  static const String termsOfServiceUrl = 'https://gymratz.app/terms';
}
