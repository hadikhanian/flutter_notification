import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Keys
  static const String _keyAppKey = 'app_key';
  static const String _keyHost = 'host';
  static const String _keyPort = 'port';
  static const String _keyChannelName = 'channel_name';
  static const String _keyEventName = 'event_name';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyBaseUrl = 'base_url'; // تغییر از authEndpoint

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save settings
  Future<void> saveSettings({
    required String appKey,
    required String host,
    required int port,
    required String channelName,
    required String eventName,
    String? authToken,
    String? baseUrl,
  }) async {
    await _prefs?.setString(_keyAppKey, appKey);
    await _prefs?.setString(_keyHost, host);
    await _prefs?.setInt(_keyPort, port);
    await _prefs?.setString(_keyChannelName, channelName);
    await _prefs?.setString(_keyEventName, eventName);

    if (authToken != null && authToken.isNotEmpty) {
      await _prefs?.setString(_keyAuthToken, authToken);
    } else {
      await _prefs?.remove(_keyAuthToken);
    }

    if (baseUrl != null && baseUrl.isNotEmpty) {
      await _prefs?.setString(_keyBaseUrl, baseUrl);
    } else {
      await _prefs?.remove(_keyBaseUrl);
    }
  }

  // Get settings
  String? get appKey => _prefs?.getString(_keyAppKey);
  String? get host => _prefs?.getString(_keyHost);
  int? get port => _prefs?.getInt(_keyPort);
  String? get channelName => _prefs?.getString(_keyChannelName);
  String? get eventName => _prefs?.getString(_keyEventName);
  String? get authToken => _prefs?.getString(_keyAuthToken);
  String? get baseUrl => _prefs?.getString(_keyBaseUrl);

  // Check if settings exist
  bool get hasSettings {
    return appKey != null &&
        host != null &&
        port != null &&
        channelName != null &&
        eventName != null;
  }

  // Get auth endpoint from base URL
  String? get authEndpoint {
    final url = baseUrl;
    if (url == null || url.isEmpty) return null;

    // اضافه کردن /broadcasting/auth به base URL
    var endpoint = url.trim();
    if (!endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
      endpoint = 'https://$endpoint';
    }

    // حذف trailing slash
    if (endpoint.endsWith('/')) {
      endpoint = endpoint.substring(0, endpoint.length - 1);
    }

    return '$endpoint/broadcasting/auth';
  }

  // Get admin order URL
  String? getOrderUrl(int orderId) {
    final url = baseUrl;
    if (url == null || url.isEmpty) return null;

    var adminUrl = url.trim();
    if (!adminUrl.startsWith('http://') && !adminUrl.startsWith('https://')) {
      adminUrl = 'https://$adminUrl';
    }

    // حذف trailing slash
    if (adminUrl.endsWith('/')) {
      adminUrl = adminUrl.substring(0, adminUrl.length - 1);
    }

    return '$adminUrl/admin/orders/$orderId';
  }

  // Clear all settings
  Future<void> clearSettings() async {
    await _prefs?.clear();
  }
}
