import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/order_event.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import 'order_notification_popup.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _appKeyController = TextEditingController();
  final _hostController = TextEditingController(text: 'ws1.binacity.com');
  final _portController = TextEditingController(text: '443');
  final _channelController = TextEditingController(text: 'private-Ecommerce.Orders.All');
  final _eventNameController = TextEditingController(text: 'CreateOrderEvent');
  final _authTokenController = TextEditingController();
  final _authEndpointController = TextEditingController(text: 'https://test.binacity.com/broadcasting/auth');

  final WebSocketService _wsService = WebSocketService();
  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService = SettingsService();

  bool _isConnected = false;
  bool _isConnecting = false;
  final List<OrderEvent> _receivedOrders = [];

  late AnimationController _pingAnimationController;
  late Animation<double> _pingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize ping animation
    _pingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pingAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pingAnimationController, curve: Curves.easeOut),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();

    // گوش دادن به سفارش‌های جدید
    _wsService.orderStream.listen((order) {
      setState(() {
        _receivedOrders.insert(0, order);
      });

      // نمایش notification سیستمی
      _notificationService.showCriticalOrderNotification(order);

      // نمایش popup always-on-top
      _showOrderPopup(order);
    });

    // گوش دادن به تغییرات connection status
    _wsService.connectionStatusStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          if (connected) {
            _isConnecting = false;
          }
        });
      }
    });

    // گوش دادن به ping events برای انیمیشن
    _wsService.pingEventStream.listen((_) {
      if (mounted && _isConnected) {
        _pingAnimationController.forward().then((_) {
          _pingAnimationController.reverse();
        });
      }
    });

    // Auto-connect if settings exist
    _autoConnectIfPossible();
  }

  Future<void> _autoConnectIfPossible() async {
    if (_settingsService.hasSettings) {
      print('📱 تنظیمات موجود است، اتصال خودکار...');
      await _connect();
    }
  }

  Future<void> _showOrderPopup(OrderEvent order) async {
    // تنظیم پنجره به حالت always-on-top و تمام صفحه
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    await windowManager.show();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false, // نمی‌توان با کلیک بیرون بست
      builder: (context) => OrderNotificationPopup(
        order: order,
        onAcknowledge: () async {
          // بازگشت به حالت عادی
          await windowManager.setAlwaysOnTop(false);
        },
      ),
    );
  }

  Future<void> _connect() async {
    if (!_settingsService.hasSettings) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚙️ لطفا ابتدا تنظیمات را از منوی Settings تکمیل کنید'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      await _wsService.initialize(
        appKey: _settingsService.appKey!,
        host: _settingsService.host!,
        port: _settingsService.port!,
        channelName: _settingsService.channelName!,
        eventName: _settingsService.eventName!,
        authToken: _settingsService.authToken,
        authEndpoint: _settingsService.authEndpoint,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ اتصال برقرار شد!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در اتصال: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await _wsService.disconnect();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔌 اتصال قطع شد'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    // If settings were saved, try to reconnect
    if (result == true && _settingsService.hasSettings) {
      if (_isConnected) {
        await _disconnect();
      }
      await _connect();
    }
  }

  Future<void> _openOrderInBrowser(OrderEvent order) async {
    final url = _settingsService.getOrderUrl(order.id);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ لطفا Base URL را در تنظیمات وارد کنید'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🌐 باز کردن URL: $url');
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      print('❌ خطا در باز کردن مرورگر: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطا در باز کردن مرورگر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConnectionIndicator() {
    return AnimatedBuilder(
      animation: _pingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pingAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppConfig.successColor
                  : (_isConnecting ? AppConfig.warningColor : Colors.grey),
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isConnected
                  ? [
                      BoxShadow(
                        color: AppConfig.successColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected
                      ? Icons.wifi
                      : (_isConnecting ? Icons.wifi_find : Icons.wifi_off),
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected
                      ? 'آنلاین'
                      : (_isConnecting ? 'در حال اتصال...' : 'آفلاین'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appTitle),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _buildConnectionIndicator(),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(AppConfig.settingsIcon),
            tooltip: 'تنظیمات',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // پنل کنترل
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConfig.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : (_isConnected ? _disconnect : _connect),
                  icon: Icon(
                    _isConnected ? AppConfig.disconnectIcon : AppConfig.connectIcon,
                  ),
                  label: Text(
                    _isConnecting
                        ? 'در حال اتصال...'
                        : (_isConnected ? 'قطع اتصال' : 'اتصال به سرور'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected
                        ? Colors.red
                        : AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // لیست سفارشات
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سفارشات دریافتی',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text('تعداد: ${_receivedOrders.length}'),
                        backgroundColor: AppConfig.primaryColor.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _receivedOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppConfig.orderIcon,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _isConnected
                                      ? 'در انتظار سفارشات جدید...'
                                      : 'لطفا ابتدا به سرور متصل شوید',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                if (!_isConnected && !_settingsService.hasSettings)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: ElevatedButton.icon(
                                      onPressed: _openSettings,
                                      icon: Icon(AppConfig.settingsIcon),
                                      label: const Text('تنظیمات اتصال'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppConfig.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _receivedOrders.length,
                            itemBuilder: (context, index) {
                              final order = _receivedOrders[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 3,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppConfig.primaryColor,
                                    child: Text(
                                      '#${order.id}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    order.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${order.orderDetails}\n'
                                    '${order.totalPrice.toStringAsFixed(0)} تومان\n'
                                    '${order.createdAt}',
                                  ),
                                  trailing: Icon(
                                    Icons.open_in_new,
                                    color: AppConfig.primaryColor,
                                  ),
                                  isThreeLine: true,
                                  onTap: () => _openOrderInBrowser(order),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _appKeyController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _channelController.dispose();
    _eventNameController.dispose();
    _authTokenController.dispose();
    _authEndpointController.dispose();
    _pingAnimationController.dispose();
    _wsService.dispose();
    _notificationService.dispose();
    super.dispose();
  }
}
