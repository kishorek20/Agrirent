// lib/services/payment_service.dart
import '../models/payment_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class PaymentService {
  final _svc = SupabaseService();

  /// Create a payment record linked to a booking.
  Future<String> createPayment({
    required String bookingId,
    required String farmerId,
    required String ownerId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final row = await _svc.client.from(AppConstants.paymentsTable).insert({
      'booking_id': bookingId,
      'farmer_id': farmerId,
      'owner_id': ownerId,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'payment_gateway': paymentMethod == 'Cash' ? 'offline' : 'online',
      'status': paymentMethod == 'Cash' ? 'pending' : 'success',
      'payment_date': DateTime.now().toIso8601String(),
    }).select('id').single();
    return row['id'] as String;
  }

  /// Update payment status (e.g. mark as success after gateway callback).
  Future<void> updatePaymentStatus(String paymentId, String status) =>
      _svc.client
          .from(AppConstants.paymentsTable)
          .update({'status': status}).eq('id', paymentId);

  /// Get payment for a booking.
  Future<PaymentModel?> getPaymentByBooking(String bookingId) async {
    final row = await _svc.client
        .from(AppConstants.paymentsTable)
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();
    return row == null ? null : PaymentModel.fromJson(row);
  }

  /// Get all payments for a farmer.
  Future<List<PaymentModel>> getFarmerPayments(String farmerId) async {
    final rows = await _svc.client
        .from(AppConstants.paymentsTable)
        .select()
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return (rows as List).map((p) => PaymentModel.fromJson(p)).toList();
  }

  /// Get all payments for an owner.
  Future<List<PaymentModel>> getOwnerPayments(String ownerId) async {
    final rows = await _svc.client
        .from(AppConstants.paymentsTable)
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (rows as List).map((p) => PaymentModel.fromJson(p)).toList();
  }
}
