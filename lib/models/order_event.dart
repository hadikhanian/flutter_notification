import 'package:json_annotation/json_annotation.dart';

part 'order_event.g.dart';

@JsonSerializable()
class OrderEvent {
  final int id;
  final String customerName;
  final String orderDetails;
  final double totalPrice;
  final DateTime createdAt;

  OrderEvent({
    required this.id,
    required this.customerName,
    required this.orderDetails,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderEventFromJson(json);

  Map<String, dynamic> toJson() => _$OrderEventToJson(this);

  @override
  String toString() {
    return 'سفارش جدید #$id - $customerName - ${totalPrice.toStringAsFixed(0)} تومان';
  }
}
