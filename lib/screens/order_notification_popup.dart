import 'package:flutter/material.dart';
import '../models/order_event.dart';
import '../services/notification_service.dart';

class OrderNotificationPopup extends StatefulWidget {
  final OrderEvent order;
  final VoidCallback onAcknowledge;

  const OrderNotificationPopup({
    Key? key,
    required this.order,
    required this.onAcknowledge,
  }) : super(key: key);

  @override
  State<OrderNotificationPopup> createState() => _OrderNotificationPopupState();
}

class _OrderNotificationPopupState extends State<OrderNotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // انیمیشن برای جلب توجه
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _acknowledge() {
    NotificationService().acknowledgeNotification(widget.order.id);
    widget.onAcknowledge();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // جلوگیری از بستن با دکمه back
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(40),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFF4500),
                    Color(0xFFFF6347),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.8),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // آیکون هشدار
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Color(0xFFFF0000),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // عنوان
                  const Text(
                    '🔥 سفارش جدید فوری! 🔥',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // جزئیات سفارش
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'شماره سفارش:',
                          '#${widget.order.id}',
                          Icons.tag,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          'مشتری:',
                          widget.order.customerName,
                          Icons.person,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          'مبلغ:',
                          '${widget.order.totalPrice.toStringAsFixed(0)} تومان',
                          Icons.attach_money,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          'جزئیات:',
                          widget.order.orderDetails,
                          Icons.description,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          'زمان:',
                          _formatDateTime(widget.order.createdAt),
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // دکمه تایید
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _acknowledge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        '✅ دیدم، شروع به آماده‌سازی می‌کنم',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // متن راهنما
                  const Text(
                    '⚠️ تا زمانی که تایید نکنید، این پنجره بسته نمی‌شود',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF0000), size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
