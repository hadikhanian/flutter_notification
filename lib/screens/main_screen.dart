import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/order_event.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import 'order_notification_popup.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

  bool _isConnected = false;
  bool _isConnecting = false;
  final List<OrderEvent> _receivedOrders = [];

  @override
  void initState() {
    super.initState();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final authToken = _authTokenController.text.trim();
      final authEndpoint = _authEndpointController.text.trim();

      await _wsService.initialize(
        appKey: _appKeyController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        channelName: _channelController.text.trim(),
        eventName: _eventNameController.text.trim(),
        authToken: authToken.isEmpty ? null : authToken,
        authEndpoint: authEndpoint.isEmpty ? null : authEndpoint,
      );

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

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
    setState(() {
      _isConnected = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔌 اتصال قطع شد'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سیستم اعلان سفارشات رستوران'),
        backgroundColor: const Color(0xFFFF4500),
        foregroundColor: Colors.white,
        actions: [
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text('متصل'),
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // پنل تنظیمات
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تنظیمات Laravel Reverb',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _appKeyController,
                        label: 'App Key',
                        hint: 'مثال: local',
                        icon: Icons.key,
                        enabled: !_isConnected,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _hostController,
                        label: 'Host',
                        hint: 'مثال: ws://127.0.0.1 یا wss://your-domain.com',
                        icon: Icons.dns,
                        enabled: !_isConnected,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _portController,
                        label: 'Port',
                        hint: '6001',
                        icon: Icons.settings_ethernet,
                        enabled: !_isConnected,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _channelController,
                        label: 'Channel Name',
                        hint: 'مثال: orders یا orders-channel',
                        icon: Icons.podcasts,
                        enabled: !_isConnected,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _eventNameController,
                        label: 'Event Name',
                        hint: 'CreateOrderEvent',
                        icon: Icons.event,
                        enabled: !_isConnected,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text(
                        'تنظیمات Private Channel (اختیاری)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _authTokenController,
                        label: 'Auth Token',
                        hint: 'Bearer token برای authorization',
                        icon: Icons.vpn_key,
                        enabled: !_isConnected,
                        required: false,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _authEndpointController,
                        label: 'Auth Endpoint',
                        hint: 'https://your-domain.com/broadcasting/auth',
                        icon: Icons.link,
                        enabled: !_isConnected,
                        required: false,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isConnecting
                              ? null
                              : (_isConnected ? _disconnect : _connect),
                          icon: Icon(
                            _isConnected ? Icons.link_off : Icons.link,
                          ),
                          label: Text(
                            _isConnecting
                                ? 'در حال اتصال...'
                                : (_isConnected
                                    ? 'قطع اتصال'
                                    : 'اتصال به سرور'),
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isConnected
                                ? Colors.red
                                : const Color(0xFFFF4500),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '💡 راهنما:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '1. App Key و Host را از تنظیمات Laravel Reverb خود وارد کنید\n'
                                '2. Channel Name را که در Laravel تعریف کرده‌اید وارد کنید\n'
                                '3. Event Name باید دقیقا با نام Event در Laravel مطابقت داشته باشد\n'
                                '4. پس از اتصال، هر سفارش جدید با یک پنجره فوری نمایش داده می‌شود',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // پنل لیست سفارشات
          Expanded(
            flex: 3,
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
                        backgroundColor: Colors.orange[100],
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
                                  Icons.inbox,
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
                                    backgroundColor: const Color(0xFFFF4500),
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
                                    '${order.totalPrice.toStringAsFixed(0)} تومان',
                                  ),
                                  trailing: Text(
                                    _formatTime(order.createdAt),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  isThreeLine: true,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'این فیلد الزامی است';
              }
              return null;
            }
          : null,
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
    _wsService.dispose();
    _notificationService.dispose();
    super.dispose();
  }
}
