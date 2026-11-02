/// Global application constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Family Expense Manager';
  static const String appVersion = '1.0.0';

  // Secure Storage Keys
  static const String keyAccessToken = 'fem_access_token';
  static const String keyRefreshToken = 'fem_refresh_token';
  static const String keyUserId = 'fem_user_id';
  static const String keyFamilyId = 'fem_family_id';
  static const String keyThemeMode = 'fem_theme_mode';

  // Pagination defaults
  static const int defaultPageSize = 20;

  // Animation & Transition durations
  static const Duration splashDelay = Duration(milliseconds: 1500);
  static const Duration animDurationShort = Duration(milliseconds: 200);
  static const Duration animDurationMedium = Duration(milliseconds: 350);
}
