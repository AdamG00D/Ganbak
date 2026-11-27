class AppConfig {
  AppConfig._();

  static const String appName = 'Ganbak';
  static const String appNameAr = 'جنبك';
  static const String appVersion = '2.0';

  /// صفحة الكود (مفتوح المصدر، GPL-3.0).
  static const String repoUrl = 'https://github.com/AdamG00D/Ganbak';
  static const String license = 'GPL-3.0';

  /// معرّف خدمة الشبكة القريبة (Nearby Connections).
  static const String nearbyServiceId = 'com.adam.wasl.mesh';

  /// منفذ اتصالات الشبكة المحلية (TCP).
  static const int lanPort = 47331;

  /// منفذ الإعلان عن الأجهزة على الشبكة (UDP).
  static const int lanBeaconPort = 47332;
}
