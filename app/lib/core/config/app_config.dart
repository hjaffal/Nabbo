/// Environment configuration for dev, staging, and production.
enum AppEnvironment { dev, staging, production }

class AppConfig {
  static AppEnvironment _env = AppEnvironment.dev;

  static AppEnvironment get environment => _env;

  static void initialize(AppEnvironment env) {
    _env = env;
  }

  static bool get isDev => _env == AppEnvironment.dev;
  static bool get isStaging => _env == AppEnvironment.staging;
  static bool get isProduction => _env == AppEnvironment.production;

  static String get emailDomain => 'nabboapp.com';

  static String get cloudRunBaseUrl => switch (_env) {
        AppEnvironment.dev => 'http://localhost:8080',
        AppEnvironment.staging =>
          'https://email-ingestion-946615442462.europe-west1.run.app',
        AppEnvironment.production =>
          'https://email-ingestion-946615442462.europe-west1.run.app',
      };

  static String get vertexAiLocation => 'europe-west1';
  static String get firebaseProjectId => 'nabbo-app-4d98a';

  static Duration get extractionTimeout => const Duration(seconds: 60);
  static int get maxRetriesOnFailure => 3;
  static int get maxCapturesPerDay => 100;
  static int get maxAttachmentSizeMb => 25;
}
