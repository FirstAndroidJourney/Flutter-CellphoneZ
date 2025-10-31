import 'package:flutter/material.dart';
import 'package:shop/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop/route/route_constants.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart'; // bản bạn đang dùng

final supabase = Supabase.instance.client;

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  Future<void> _startVNPayPayment(
      BuildContext context, String orderId, double amount) async {
    try {
      // 1️⃣ Gọi Supabase Edge Function để tạo URL thanh toán
      final response = await supabase.functions.invoke(
        'vnpay_create?order_id=$orderId&amount=$amount',
      );

      final paymentUrl = response.data['paymentUrl'] as String?;
      if (paymentUrl == null) {
        throw Exception('Không nhận được URL thanh toán từ server.');
      }

      debugPrint('🔗 VNPay URL: $paymentUrl');

      // 2️⃣ Mở webview VNPay (callback xử lý nội bộ)
      await VNPAYFlutter.instance.show(
        context: context,
        paymentUrl: paymentUrl,
        appBarTitle: "Thanh toán VNPay",
        onPaymentSuccess: (params) async {
          debugPrint('✅ Thanh toán thành công: $params');
          final txnRef = params['vnp_TxnRef'] ?? '';
          final orderId =
              txnRef.contains('_') ? txnRef.split('_').first : txnRef;

          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

          // ✅ Đợi WebView đóng hoàn toàn
          Future.delayed(const Duration(milliseconds: 300), () {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              paymentResultScreenRoute,
              (route) => false,
              arguments: {'orderId': orderId, 'status': 'success'},
            );
          });
        },
        onPaymentError: (params) async {
          debugPrint('❌ Thanh toán thất bại: $params');
          final txnRef = params['vnp_TxnRef'] ?? '';
          final orderId =
              txnRef.contains('_') ? txnRef.split('_').first : txnRef;

          Future.delayed(const Duration(milliseconds: 300), () {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              paymentResultScreenRoute,
              (route) => false,
              arguments: {'orderId': orderId, 'status': 'failed'},
            );
          });
        },
      );
    } catch (e) {
      debugPrint('💥 Lỗi VNPay: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thanh toán: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VNPay')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // 🔹 Gọi hàm thanh toán (demo: order_123, 50.000đ)
            await _startVNPayPayment(
                context, 'dddd1111-1111-1111-1111-dddddddddddd', 50000);
          },
          child: const Text('Thanh toán VNPay'),
        ),
      ),
    );
  }
}
