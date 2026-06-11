// lib/models/payment_model.dart
class PaymentModel {
  final String id;
  final String bookingId;
  final String farmerId;
  final String ownerId;
  final double amount;
  final String? paymentMethod;
  final String? transactionId;
  final String status;
  final DateTime? paymentDate;
  final DateTime createdAt;

  PaymentModel({
    required this.id, required this.bookingId, required this.farmerId,
    required this.ownerId, required this.amount, this.paymentMethod,
    this.transactionId, required this.status, this.paymentDate,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: j['id'] ?? '', bookingId: j['booking_id'] ?? '',
    farmerId: j['farmer_id'] ?? '', ownerId: j['owner_id'] ?? '',
    amount: (j['amount'] ?? 0).toDouble(),
    paymentMethod: j['payment_method'], transactionId: j['transaction_id'],
    status: j['status'] ?? 'pending',
    paymentDate: j['payment_date'] != null ? DateTime.parse(j['payment_date']) : null,
    createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
  );
}
