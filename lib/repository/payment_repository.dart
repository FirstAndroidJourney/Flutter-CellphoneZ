import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentRepository {
  final supabase = Supabase.instance.client;
  final String table = 'payments';

  Future<List<Payment>> getPaymentsByUser(String userId) async {
    final res = await supabase
        .from(table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<void> insertPayment(Payment payment) async {
    await supabase.from(table).insert(payment.toJson());
  }

  Future<void> updateStatus(String paymentId, String status) async {
    await supabase.from(table).update({'status': status}).eq('id', paymentId);
  }
}
