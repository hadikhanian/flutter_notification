import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/order_event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isSoundPlaying = false;
  Timer? _soundLoopTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // درخواست مجوزها
    await _requestPermissions();

    // تنظیمات AudioPlayer
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(1.0);

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  Future<void> _requestPermissions() async {
    // Android
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // iOS
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // برای notification های critical
      );
    }
  }

  Future<void> showCriticalOrderNotification(OrderEvent order) async {
    if (!_isInitialized) {
      await initialize();
    }

    // نمایش System Notification
    await _showSystemNotification(order);

    // شروع پخش صدای هشدار
    await _startAlarmSound();

    print('🚨 نمایش Notification برای سفارش #${order.id}');
  }

  Future<void> _showSystemNotification(OrderEvent order) async {
    const androidDetails = AndroidNotificationDetails(
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
      timeout: LinuxNotificationTimeout.fromSeconds(0), // تا زمان بستن توسط کاربر
      category: LinuxNotificationCategory.imReceived(),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );

    await _notifications.show(
      order.id,
      '🔥 سفارش جدید فوری! 🔥',
      order.toString(),
      notificationDetails,
      payload: order.id.toString(),
    );
  }

  Future<void> _startAlarmSound() async {
    if (_isSoundPlaying) return;

    _isSoundPlaying = true;

    try {
      // پخش صدای هشدار از assets
      // اگر فایل صوتی موجود نباشد، از صدای پیش‌فرض استفاده می‌کند
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));

      // هر 5 ثانیه یکبار صدا را مجددا پخش می‌کند (برای loop)
      _soundLoopTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_isSoundPlaying) {
          await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
        }
      });

      print('🔊 صدای هشدار شروع شد');
    } catch (e) {
      print('❌ خطا در پخش صدا: $e');
      // اگر فایل صوتی پیدا نشد، از URL backup استفاده می‌کند
      try {
        await _audioPlayer.play(UrlSource(
            'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'));
      } catch (e2) {
        print('❌ خطا در پخش صدای backup: $e2');
      }
    }
  }

  Future<void> stopAlarmSound() async {
    _isSoundPlaying = false;
    _soundLoopTimer?.cancel();
    _soundLoopTimer = null;

    await _audioPlayer.stop();
    print('🔇 صدای هشدار متوقف شد');
  }

  Future<void> acknowledgeNotification(int orderId) async {
    // حذف notification
    await _notifications.cancel(orderId);

    // توقف صدا
    await stopAlarmSound();

    print('✅ Notification #$orderId تایید شد');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification تپ شد: ${response.payload}');
    // این callback وقتی کاربر روی notification کلیک می‌کند فراخوانی می‌شود
  }

  void dispose() {
    _soundLoopTimer?.cancel();
    _audioPlayer.dispose();
  }
}
