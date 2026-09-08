class AppConstants {
  static const String appName = 'Tentacle CRM';

  static const Duration splashDuration = Duration(milliseconds: 1400);

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://150.241.245.88:8091/api/v1',
  );

  static String get socketBaseUrl => baseUrl.replaceFirst('/api/v1', '');
}
