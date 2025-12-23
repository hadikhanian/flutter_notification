// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderEvent _$OrderEventFromJson(Map<String, dynamic> json) => OrderEvent(
      id: json['id'] as int,
      customerName: json['customerName'] as String? ?? json['customer_name'] as String? ?? '-',
      orderDetails: json['orderDetails'] as String? ?? json['order_details'] as String? ?? '-',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? (json['total_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '-',
    );

Map<String, dynamic> _$OrderEventToJson(OrderEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerName': instance.customerName,
      'orderDetails': instance.orderDetails,
      'totalPrice': instance.totalPrice,
      'createdAt': instance.createdAt,
    };
