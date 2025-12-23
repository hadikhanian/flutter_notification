import 'package:flutter/material.dart';

/// تنظیمات قابل تغییر برنامه
class AppConfig {
  // عنوان برنامه
  static const String appTitle = 'سیستم اعلان';

  // عنوان نوتیفیکیشن
  static const String notificationTitle = 'سفارش جدید';

  // متن دکمه acknowledge
  static const String acknowledgeButtonText = 'دیدم، شروع می‌کنم';

  // رنگ‌ها
  static const Color primaryColor = Color(0xFFFF4500); // نارنجی-قرمز
  static const Color accentColor = Color(0xFFFF6347); // قرمز گوجه‌ای
  static const Color criticalColor = Color(0xFFFF0000); // قرمز
  static const Color successColor = Color(0xFF4CAF50); // سبز
  static const Color warningColor = Color(0xFFFFC107); // زرد
  static const Color backgroundColor = Color(0xFFF5F5F5); // خاکستری روشن

  // گرادینت برای popup
  static const List<Color> popupGradient = [
    Color(0xFFFF0000),
    Color(0xFFFF4500),
    Color(0xFFFF6347),
  ];

  // اندازه‌ها
  static const double borderRadius = 15.0;
  static const double popupBorderRadius = 30.0;
  static const double iconSize = 80.0;

  // زمان‌ها
  static const Duration pingInterval = Duration(seconds: 30);
  static const Duration reconnectMaxDelay = Duration(seconds: 30);

  // فونت
  static const String fontFamily = 'Vazir';

  // آیکون‌ها
  static const IconData orderIcon = Icons.shopping_bag;
  static const IconData settingsIcon = Icons.settings;
  static const IconData connectIcon = Icons.link;
  static const IconData disconnectIcon = Icons.link_off;

  /// برای تغییر theme در build time
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
    );
  }

  /// برای استفاده در notification popup
  static BoxDecoration getPopupDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: popupGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(popupBorderRadius),
      boxShadow: [
        BoxShadow(
          color: criticalColor.withOpacity(0.8),
          blurRadius: 40,
          spreadRadius: 10,
        ),
      ],
      border: Border.all(
        color: Colors.white,
        width: 4,
      ),
    );
  }
}
