import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../providers/cart_provider.dart';
import '../../route/route_constants.dart';

class PaymentResultScreen extends StatefulWidget {
  final String orderId;
  final String? status;
  final List<String>? purchasedItemIds; // IDs của items đã mua để xóa khỏi giỏ

  const PaymentResultScreen({
    super.key,
    required this.orderId,
    this.status,
    this.purchasedItemIds,
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

    // Nếu PaymentScreen đã truyền status thì dùng luôn
    if (widget.status != null && widget.status!.isNotEmpty) {
      status = widget.status!;
    }

    // Kiểm tra lại trạng thái trong DB để chắc chắn
    _checkFinalStatus();
  }

  Future<void> _checkFinalStatus() async {
    try {
      final response = await supabase
          .from('payments')
          .select('status')
          .eq('order_id', widget.orderId)
          .maybeSingle();

      if (!mounted) return;

      final finalStatus = response?['status'] ?? widget.status ?? 'failed';

      setState(() {
        status = finalStatus;
      });

      // Nếu thanh toán thành công, xóa items khỏi giỏ hàng
      if (finalStatus == 'success' && widget.purchasedItemIds != null) {
        final cartProvider = context.read<CartProvider>();
        for (final itemId in widget.purchasedItemIds!) {
          await cartProvider.removeItem(itemId);
          final response =
              await supabase.from('cart_items').delete().eq('id', itemId);

          if (response.error != null) {
            debugPrint(
                '❌ Lỗi xóa item $itemId khỏi Supabase: ${response.error!.message}');
          } else {
            debugPrint('✅ Đã xóa item $itemId khỏi Supabase');
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra trạng thái thanh toán: $e');
      if (mounted) {
        setState(() {
          status = widget.status ?? 'failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: cellphoneZRed,
        foregroundColor: Colors.white,
        title: const Text('Kết quả thanh toán'),
        automaticallyImplyLeading: false, // Ẩn nút back
      ),
      body: Center(
        child: status == 'checking'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: cellphoneZRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang xử lý thanh toán...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      isSuccess
                          ? 'Thanh toán thành công!'
                          : 'Thanh toán thất bại',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      isSuccess
                          ? 'Đơn hàng của bạn đã được đặt thành công.\nChúng tôi sẽ liên hệ với bạn sớm nhất!'
                          : 'Đã có lỗi xảy ra trong quá trình thanh toán.\nVui lòng thử lại sau.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Order ID
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Mã đơn hàng: ${widget.orderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Column(
                      children: [
                        // Xem đơn hàng button (chỉ hiện khi success)
                        if (isSuccess)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
                                  orderConfirmationScreenRoute,
                                  arguments: {'orderId': widget.orderId},
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cellphoneZRed,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Xem đơn hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (isSuccess) const SizedBox(height: 12),

                        // Row buttons
                        Row(
                          children: [
                            if (!isSuccess)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cellphoneZRed,
                                    side:
                                        const BorderSide(color: cellphoneZRed),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Thử lại',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            if (!isSuccess) const SizedBox(width: 12),
                            Expanded(
                              child: isSuccess
                                  ? OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          entryPointScreenRoute,
                                          (route) => false,
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cellphoneZRed,
                                        side: const BorderSide(
                                            color: cellphoneZRed),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Về trang chủ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          entryPointScreenRoute,
                                          (route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cellphoneZRed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Về trang chủ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
