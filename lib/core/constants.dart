/// App-wide constants and RevenueCat configuration placeholders.
class AppConstants {
  AppConstants._();

  // RevenueCat API keys — replace with real keys before release
  static const String revenueCatAppleApiKey = 'appl_REPLACE_ME';
  static const String revenueCatGoogleApiKey = 'goog_REPLACE_ME';

  // RevenueCat entitlement & offering IDs
  static const String entitlementId = 'pro';
  static const String defaultOfferingId = 'default';

  // Free-tier limits
  static const int freeMaxActivePrograms = 1;
  static const int freeHistoryWeeks = 2;
}
