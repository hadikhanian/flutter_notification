import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/order_event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isSoundPlaying = false;
  bool _notificationSupported = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // فقط برای Android, iOS, و Linux تلاش کنیم notification را initialize کنیم
      if (Platform.isAndroid || Platform.isIOS || Platform.isLinux) {
        _notifications = FlutterLocalNotificationsPlugin();

        // تنظیمات Android
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

        // تنظیمات iOS
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        // تنظیمات Linux
        const linuxSettings = LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        );

        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
          linux: linuxSettings,
        );

        await _notifications!.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        // درخواست مجوزها
        await _requestPermissions();

        _notificationSupported = true;
        print('✅ System Notification پشتیبانی می‌شود');
      } else {
        print('⚠️ System Notification برای Windows پشتیبانی نمی‌شود، فقط از صدا و popup استفاده می‌شود');
      }
    } catch (e) {
      print('⚠️ خطا در initialize notification (نادیده گرفته شد): $e');
      _notificationSupported = false;
    }

    // تنظیمات AudioPlayer
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      print('✅ AudioPlayer initialized');
    } catch (e) {
      print('❌ خطا در initialize AudioPlayer: $e');
    }

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  Future<void> _requestPermissions() async {
    if (_notifications == null) return;

    try {
      // Android
      final androidImplementation =
          _notifications!.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      // iOS
      final iosImplementation = _notifications!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true, // برای notification های critical
        );
      }
    } catch (e) {
      print('⚠️ خطا در درخواست مجوزها (نادیده گرفته شد): $e');
    }
  }

  Future<void> showCriticalOrderNotification(OrderEvent order) async {
    if (!_isInitialized) {
      await initialize();
    }

    // نمایش System Notification (اگر پشتیبانی شود)
    if (_notificationSupported) {
      try {
        await _showSystemNotification(order);
      } catch (e) {
        print('⚠️ خطا در نمایش System Notification: $e');
      }
    }

    // شروع پخش صدای هشدار (مهمترین بخش!)
    await _startAlarmSound();

    print('🚨 نمایش Notification برای سفارش #${order.id}');
  }

  Future<void> _showSystemNotification(OrderEvent order) async {
    final androidDetails = AndroidNotificationDetails(
      'critical_orders',
      'سفارشات فوری',
      channelDescription: 'اعلان‌های فوری سفارشات جدید',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      fullScreenIntent: true, // نمایش تمام صفحه
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false, // باید دستی بسته شود
      ongoing: true, // نمی‌توان آن را swipe کرد
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical, // برای critical notification
      sound: 'alarm.aiff',
    );

    const linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );

    if (_notifications != null) {
      await _notifications!.show(
        order.id,
        '🔥 سفارش جدید فوری! 🔥',
        order.toString(),
        notificationDetails,
        payload: order.id.toString(),
      );
    }
  }

  Future<void> _startAlarmSound() async {
    if (_isSoundPlaying) {
      print('⚠️ صدا در حال پخش است');
      return;
    }

    _isSoundPlaying = true;

    try {
      print('🔊 در حال تلاش برای پخش صدا از asset...');

      // تنظیم ReleaseMode برای loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      // پخش صدای هشدار از assets
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));

      print('✅ صدای هشدار با موفقیت شروع شد (loop mode)');
    } catch (e) {
      print('❌ خطا در پخش صدا از asset: $e');

      // تلاش برای پخش از URL backup
      try {
        print('🔊 تلاش برای پخش صدا از URL backup...');
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(UrlSource(
            'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'));
        print('✅ صدای backup با موفقیت شروع شد');
      } catch (e2) {
        print('❌ خطا در پخش صدای backup: $e2');
        _isSoundPlaying = false;
      }
    }
  }

  Future<void> stopAlarmSound() async {
    _isSoundPlaying = false;

    try {
      await _audioPlayer.stop();
      print('🔇 صدای هشدار متوقف شد');
    } catch (e) {
      print('⚠️ خطا در توقف صدا: $e');
    }
  }

  Future<void> acknowledgeNotification(int orderId) async {
    // حذف notification (اگر پشتیبانی شود)
    if (_notifications != null) {
      try {
        await _notifications!.cancel(orderId);
      } catch (e) {
        print('⚠️ خطا در cancel notification: $e');
      }
    }

    // توقف صدا
    await stopAlarmSound();

    print('✅ Notification #$orderId تایید شد');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification تپ شد: ${response.payload}');
    // این callback وقتی کاربر روی notification کلیک می‌کند فراخوانی می‌شود
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
