// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      method: json['method'] as String?,
      transactionId: json['transactionId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'userId': instance.userId,
      'amount': instance.amount,
      'status': instance.status,
      'method': instance.method,
      'transactionId': instance.transactionId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
