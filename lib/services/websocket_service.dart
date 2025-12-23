import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../models/order_event.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  PusherChannelsFlutter? _pusher;
  final StreamController<OrderEvent> _orderStreamController =
      StreamController<OrderEvent>.broadcast();

  Stream<OrderEvent> get orderStream => _orderStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // تنظیمات Laravel Reverb
  String _appKey = '';
  String _host = '';
  int _port = 6001;
  String _channelName = '';
  String _eventName = 'CreateOrderEvent';

  Future<void> initialize({
    required String appKey,
    required String host,
    int port = 6001,
    required String channelName,
    String? eventName,
  }) async {
    _appKey = appKey;
    _host = host;
    _port = port;
    _channelName = channelName;
    if (eventName != null) _eventName = eventName;

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: _appKey,
        cluster: 'mt1', // برای Reverb معمولا از این استفاده می‌شود
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onEvent,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onAuthorizer: _onAuthorizer,
      );

      // تنظیم host و port برای Laravel Reverb
      await _pusher!.connect();

      print('🔌 در حال اتصال به Laravel Reverb...');
    } catch (e) {
      print('❌ خطا در initialize: $e');
      rethrow;
    }
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    print('🔄 وضعیت اتصال: $previousState -> $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  void _onError(String message, int? code, dynamic error) {
    print('❌ خطا در WebSocket: $message (code: $code)');
  }

  void _onEvent(PusherEvent event) {
    print('📨 رویداد دریافت شد: ${event.eventName} از channel: ${event.channelName}');

    if (event.eventName == _eventName) {
      try {
        final data = jsonDecode(event.data);
        final orderEvent = OrderEvent.fromJson(data);
        _orderStreamController.add(orderEvent);
        print('✅ سفارش جدید پردازش شد: ${orderEvent.id}');
      } catch (e) {
        print('❌ خطا در پردازش سفارش: $e');
      }
    }
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    print('✅ عضویت موفق در channel: $channelName');
  }

  void _onSubscriptionError(String message, dynamic error) {
    print('❌ خطا در عضویت: $message');
  }

  void _onDecryptionFailure(String event, String reason) {
    print('❌ خطای رمزگشایی: $event - $reason');
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    print('👤 عضو جدید: ${member.userId} به $channelName اضافه شد');
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    print('👤 عضو: ${member.userId} از $channelName حذف شد');
  }

  dynamic _onAuthorizer(String channelName, String socketId, dynamic options) {
    // برای channel های خصوصی می‌توانید اینجا authorization را پیاده‌سازی کنید
    return null;
  }

  Future<void> subscribeToChannel() async {
    if (_pusher == null) {
      throw Exception('Pusher هنوز initialize نشده است');
    }

    try {
      await _pusher!.subscribe(channelName: _channelName);
      print('📡 عضویت در channel: $_channelName');
    } catch (e) {
      print('❌ خطا در subscribe: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromChannel() async {
    if (_pusher == null) return;

    try {
      await _pusher!.unsubscribe(channelName: _channelName);
      print('📡 لغو عضویت از channel: $_channelName');
    } catch (e) {
      print('❌ خطا در unsubscribe: $e');
    }
  }

  Future<void> disconnect() async {
    if (_pusher == null) return;

    try {
      await _pusher!.disconnect();
      _isConnected = false;
      print('🔌 قطع اتصال از WebSocket');
    } catch (e) {
      print('❌ خطا در disconnect: $e');
    }
  }

  void dispose() {
    _orderStreamController.close();
    disconnect();
  }
}
