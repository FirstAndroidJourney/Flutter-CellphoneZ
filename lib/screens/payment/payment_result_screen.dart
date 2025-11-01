import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentResultScreen extends StatefulWidget {
  final String orderId;
  final String? status; // ✅ optional status truyền từ PaymentScreen

  const PaymentResultScreen({
    super.key,
    required this.orderId,
    this.status,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  final supabase = Supabase.instance.client;
  String status = 'checking';

  @override
  void initState() {
    super.initState();

    // ✅ Nếu PaymentScreen đã truyền status thì dùng luôn
    if (widget.status != null && widget.status!.isNotEmpty) {
      status = widget.status!;
    }

    // ✅ Kiểm tra lại trạng thái trong DB để chắc chắn (optional)
    _checkFinalStatus();
  }

  Future<void> _checkFinalStatus() async {
    final response = await supabase
        .from('payments')
        .select('status')
        .eq('order_id', widget.orderId)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      status = response?['status'] ?? widget.status ?? 'failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thanh toán')),
      body: Center(
        child: status == 'checking'
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess
                        ? 'Thanh toán thành công 🎉'
                        : 'Thanh toán thất bại ❌',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Về trang chủ'),
                  ),
                ],
              ),
      ),
    );
  }
}
