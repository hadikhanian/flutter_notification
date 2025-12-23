import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();

  late TextEditingController _appKeyController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _channelController;
  late TextEditingController _eventNameController;
  late TextEditingController _authTokenController;
  late TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _appKeyController = TextEditingController(text: _settingsService.appKey ?? '');
    _hostController = TextEditingController(text: _settingsService.host ?? '');
    _portController = TextEditingController(text: _settingsService.port?.toString() ?? '443');
    _channelController = TextEditingController(text: _settingsService.channelName ?? '');
    _eventNameController = TextEditingController(text: _settingsService.eventName ?? 'CreateOrderEvent');
    _authTokenController = TextEditingController(text: _settingsService.authToken ?? '');
    _baseUrlController = TextEditingController(text: _settingsService.baseUrl ?? '');
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _settingsService.saveSettings(
        appKey: _appKeyController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        channelName: _channelController.text.trim(),
        eventName: _eventNameController.text.trim(),
        authToken: _authTokenController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تنظیمات ذخیره شد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // برگشت به صفحه اصلی
      Navigator.pop(context, true); // true = تنظیمات ذخیره شد
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا در ذخیره: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'تنظیمات اتصال',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _appKeyController,
              label: 'App Key',
              hint: 'مثال: ICS7DPZtPJyrRLjNFDBcsTiDzkNrj4QA',
              icon: Icons.key,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _hostController,
              label: 'Host',
              hint: 'مثال: ws1.binacity.com',
              icon: Icons.dns,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _portController,
              label: 'Port',
              hint: '443',
              icon: Icons.settings_ethernet,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _channelController,
              label: 'Channel Name',
              hint: 'مثال: private-Ecommerce.Orders.All',
              icon: Icons.podcasts,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _eventNameController,
              label: 'Event Name',
              hint: 'CreateOrderEvent',
              icon: Icons.event,
            ),
            const SizedBox(height: 30),

            const Divider(),
            const Text(
              'تنظیمات Private Channel (اختیاری)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _baseUrlController,
              label: 'Base URL',
              hint: 'https://ws1.binacity.com',
              icon: Icons.link,
              required: false,
            ),
            const SizedBox(height: 10),
            const Text(
              '💡 از این URL برای authorization و باز کردن سفارشات استفاده می‌شود',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _authTokenController,
              label: 'Auth Token',
              hint: 'Bearer token',
              icon: Icons.vpn_key,
              required: false,
            ),
            const SizedBox(height: 30),

            // دکمه ذخیره
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, size: 28),
                label: const Text(
                  'ذخیره تنظیمات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.successColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // دکمه لغو
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.cancel),
                label: const Text('لغو'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
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

  @override
  void dispose() {
    _appKeyController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _channelController.dispose();
    _eventNameController.dispose();
    _authTokenController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }
}
