/// App-wide constants and RevenueCat configuration.
class AppConstants {
  AppConstants._();

  // RevenueCat API Keys — pass via: --dart-define=RC_GOOGLE_KEY=goog_xxx
  static const String revenueCatAppleApiKey =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: 'appl_REPLACE_ME');
  static const String revenueCatGoogleApiKey =
      String.fromEnvironment('RC_GOOGLE_KEY',
          defaultValue: 'goog_FLzUpFxMnQOfgdqMveJwwCBdMuK');

  // RevenueCat identifiers
  static const String entitlementId = 'GymRatz';

  // Product identifiers (must match RevenueCat dashboard)
  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';

  // Coach tier product identifiers
  static const String productCoach5 = 'coach_5';
  static const String productCoach10 = 'coach_10';
  static const String productCoach20 = 'coach_20';

  // Max clients per coach tier
  static int maxClientsForTier(String tier) {
    switch (tier) {
      case productCoach5:
        return 5;
      case productCoach10:
        return 10;
      case productCoach20:
        return 20;
      default:
        return 0;
    }
  }

  // App info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://yonatan1203.github.io/GymRatz/legal/privacy.html';
  static const String termsOfServiceUrl = 'https://yonatan1203.github.io/GymRatz/legal/terms.html';
}
