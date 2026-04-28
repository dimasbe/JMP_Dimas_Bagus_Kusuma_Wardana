class AppConstants {
  // App Info
  static const String appName = 'Survey Produk';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String keyLoggedInUserId = 'logged_in_user_id';
  static const String keyLoggedInUsername = 'logged_in_username';
  static const String keyLoggedInNama = 'logged_in_nama';
  static const String keyLoginTime = 'login_time';

  // Database
  static const String dbName = 'survey_produk.db';
  static const int dbVersion = 1;

  // Default admin credentials (di-seed saat install pertama)
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';
  static const String defaultNama = 'Administrator';
}
