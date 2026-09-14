class AppConstants {
  AppConstants._();

  static const String appName = 'ConnectCall';
  static const String appTagline = 'Connect with anyone, anywhere.';
  static const String appVersion = '1.0.0';

  // Zego Cloud App ID & Sign — replace with your own credentials
  static const int zegoAppId = 1657367531; // TODO: replace with real Zego App ID
  static const String zegoAppSign = '42f8ac7f8bdb0c99b958794e8af48754ad49f6def6363074766db3f341de6677'; // TODO: replace with real Zego App Sign

  // Shared Preferences keys
  static const String keyCurrentUser = 'current_user';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyThemeMode = 'theme_mode';

  // Call durations
  static const int callTimeoutSeconds = 60;
  static const int ringingDurationSeconds = 30;

  // Pagination
  static const int pageSize = 20;

  // Animation durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
