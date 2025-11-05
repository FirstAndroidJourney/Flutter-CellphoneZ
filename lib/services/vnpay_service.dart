import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

Future<void> payWithVNPay() async {
  final orderId = 'dddd1111-1111-1111-1111-dddddddddddd';
  final amount = 50000;

  final Uri url = Uri.parse(
      'https://cqfnmuttjjpdalrwvauy.supabase.co/functions/v1/vnpay_create'
      '?order_id=$orderId&amount=$amount');

  try {
    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZm5tdXR0ampwZGFscnd2YXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NjcxNTMsImV4cCI6MjA3NjU0MzE1M30.AI5q4aP88w2HSW1-ik8RxwiOBh3gwfjjcgSs0F9-h-4'
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final paymentUrl = data['paymentUrl'];

      if (await canLaunchUrl(Uri.parse(paymentUrl))) {
        await launchUrl(Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không mở được VNPay URL');
      }
    } else {
      print('Lỗi khi tạo link thanh toán: ${response.body}');
    }
  } catch (e) {
    print('Lỗi: $e');
  }
}
