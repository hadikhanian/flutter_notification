import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../models/order_event.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<OrderEvent> _orderStreamController =
      StreamController<OrderEvent>.broadcast();

  Stream<OrderEvent> get orderStream => _orderStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // تنظیمات Laravel Reverb
  String _appKey = '';
  String _host = 'ws1.binacity.com';
  int _port = 443;
  String _channelName = 'private-Ecommerce.Orders.All';
  String _eventName = 'CreateOrderEvent';
  String _socketId = '';
  String? _authToken;
  String? _authEndpoint;

  // Reconnection
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 999; // تلاش بی‌نهایت
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  Future<void> initialize({
    required String appKey,
    required String host,
    int port = 443,
    required String channelName,
    String? eventName,
    String? authToken,
    String? authEndpoint,
  }) async {
    _appKey = appKey;
    _host = host;
    _port = port;
    _channelName = channelName;
    _authToken = authToken;
    _authEndpoint = authEndpoint;
    if (eventName != null) _eventName = eventName;

    _shouldReconnect = true;
    await _connect();
  }

  Future<void> _connect() async {
    try {
      // لغو تایمر reconnect اگر وجود دارد
      _reconnectTimer?.cancel();

      // ساخت WebSocket URL
      final scheme = _port == 443 || _port == 6001 ? 'wss' : 'ws';
      final wsUrl = Uri.parse('$scheme://$_host:$_port/app/$_appKey?protocol=7&client=js&version=8.0.0');

      print('🔌 در حال اتصال به: $wsUrl');

      // اتصال به WebSocket
      _channel = WebSocketChannel.connect(wsUrl);

      // گوش دادن به پیام‌ها
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      print('✅ اتصال برقرار شد');
      _isConnected = true;
      _reconnectAttempts = 0; // ریست تعداد تلاش‌ها

      // شروع ping/heartbeat هر 30 ثانیه
      _startPingTimer();
    } catch (e) {
      print('❌ خطا در اتصال: $e');
      _isConnected = false;
      _handleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final event = data['event'] as String?;

      print('📨 پیام دریافت شد: ${data['event']}');

      if (event == 'pusher:connection_established') {
        // اتصال برقرار شد، socketId را ذخیره کن
        final connectionData = jsonDecode(data['data']);
        _socketId = connectionData['socket_id'];
        print('🔌 Socket ID: $_socketId');

        // اکنون می‌توانیم به channel subscribe کنیم
        subscribeToChannel();
      } else if (event == 'pusher_internal:subscription_succeeded') {
        print('✅ عضویت موفق در channel: $_channelName');
      } else if (event == 'pusher:pong') {
        // پاسخ به ping
        print('💓 Pong دریافت شد');
      } else if (event == 'pusher:error') {
        // خطا از سمت سرور
        final errorData = data['data'];
        print('❌ خطا از سرور: $errorData');
        // اتصال ممکن است قطع شود
      } else if (event == _eventName) {
        // این event سفارش جدید است
        _handleOrderEvent(data);
      } else if (data['channel'] != null && event != null) {
        // سایر event های channel
        final channelEvent = data['data'];
        if (channelEvent != null && event == _eventName) {
          _handleOrderEvent({'data': channelEvent});
        }
      }
    } catch (e) {
      print('❌ خطا در پردازش پیام: $e');
      print('پیام دریافتی: $message');
    }
  }

  void _handleOrderEvent(Map<String, dynamic> eventData) {
    try {
      dynamic orderData = eventData['data'];

      // اگر data به صورت string است، آن را decode کن
      if (orderData is String) {
        orderData = jsonDecode(orderData);
      }

      print('📦 داده سفارش: $orderData');

      final orderEvent = OrderEvent.fromJson(orderData as Map<String, dynamic>);
      _orderStreamController.add(orderEvent);
      print('✅ سفارش جدید پردازش شد: ${orderEvent.id}');
    } catch (e, stackTrace) {
      print('❌ خطا در پردازش سفارش: $e');
      print('StackTrace: $stackTrace');
      print('Event data: $eventData');
    }
  }

  void _onError(error) {
    print('❌ خطا در WebSocket: $error');
    _isConnected = false;
    _handleReconnect();
  }

  void _onDone() {
    print('🔌 اتصال WebSocket قطع شد');
    _isConnected = false;
    _pingTimer?.cancel();
    _handleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          final pingMessage = jsonEncode({'event': 'pusher:ping', 'data': {}});
          _channel!.sink.add(pingMessage);
          print('💓 Ping ارسال شد');
        } catch (e) {
          print('❌ خطا در ارسال ping: $e');
        }
      }
    });
  }

  void _handleReconnect() {
    if (!_shouldReconnect) {
      print('⚠️ Reconnect غیرفعال است');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ حداکثر تلاش برای reconnect به پایان رسید');
      return;
    }

    _reconnectAttempts++;
    final delay = _getReconnectDelay();

    print('🔄 تلاش برای reconnect #$_reconnectAttempts بعد از $delay ثانیه...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _connect();
    });
  }

  int _getReconnectDelay() {
    // Exponential backoff: 1, 2, 4, 8, 16, 30 (max)
    if (_reconnectAttempts <= 1) return 1;
    if (_reconnectAttempts == 2) return 2;
    if (_reconnectAttempts == 3) return 4;
    if (_reconnectAttempts == 4) return 8;
    if (_reconnectAttempts == 5) return 16;
    return 30; // حداکثر 30 ثانیه
  }

  Future<void> subscribeToChannel() async {
    if (_channel == null) {
      throw Exception('WebSocket هنوز متصل نشده است');
    }

    try {
      String subscribeMessage;

      // بررسی اینکه channel خصوصی است یا عمومی
      if (_channelName.startsWith('private-')) {
        // برای channel های خصوصی نیاز به authorization داریم
        if (_authEndpoint == null || _authToken == null) {
          throw Exception('برای Private Channel نیاز به authEndpoint و authToken است');
        }

        // درخواست authorization
        final auth = await _getChannelAuth();

        subscribeMessage = jsonEncode({
          'event': 'pusher:subscribe',
          'data': {
            'channel': _channelName,
            'auth': auth['auth'],
            'channel_data': auth['channel_data'],
          }
        });
      } else {
        // channel عمومی
        subscribeMessage = jsonEncode({
          'event': 'pusher:subscribe',
          'data': {
            'channel': _channelName,
          }
        });
      }

      _channel!.sink.add(subscribeMessage);
      print('📡 درخواست عضویت در channel: $_channelName');
    } catch (e) {
      print('❌ خطا در subscribe: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getChannelAuth() async {
    try {
      final response = await http.post(
        Uri.parse(_authEndpoint!),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'socket_id': _socketId,
          'channel_name': _channelName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Authorization failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ خطا در دریافت authorization: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromChannel() async {
    if (_channel == null) return;

    try {
      final unsubscribeMessage = jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {
          'channel': _channelName,
        }
      });

      _channel!.sink.add(unsubscribeMessage);
      print('📡 لغو عضویت از channel: $_channelName');
    } catch (e) {
      print('❌ خطا در unsubscribe: $e');
    }
  }

  Future<void> disconnect() async {
    _shouldReconnect = false; // غیرفعال کردن reconnection
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      _isConnected = false;
      print('🔌 قطع اتصال از WebSocket');
    } catch (e) {
      print('❌ خطا در disconnect: $e');
    }
  }

  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _orderStreamController.close();
    disconnect();
  }
}
