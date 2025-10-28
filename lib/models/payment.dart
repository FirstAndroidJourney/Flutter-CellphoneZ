import 'package:freezed_annotation/freezed_annotation.dart';
part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String orderId,
    required String userId,
    required double amount,
    required String status,
    String? method,
    String? transactionId,
    DateTime? createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
