enum Environment { dev, prod }

class Env {
  static Environment get current {
    const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
    return envStr == 'prod' ? Environment.prod : Environment.dev;
  }

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;

  /// Use verbose logging in dev
  static bool get verboseLogging => isDev;

  /// Only enable Crashlytics in prod
  static bool get crashlyticsEnabled => isProd;
}
