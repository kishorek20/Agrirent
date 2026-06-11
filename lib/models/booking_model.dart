// lib/models/booking_model.dart
class BookingModel {
  final String id;
  final String vehicleId;
  final String farmerId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double? totalDays;
  final double pricePerDay;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? bookingNotes;
  final String? cancellationReason;
  final DateTime createdAt;
  final String? vehicleTitle;
  final String? vehicleType;
  final String? vehicleImage;
  final String? farmerName;
  final String? farmerPhone;
  final String? ownerName;

  BookingModel({
    required this.id, required this.vehicleId, required this.farmerId,
    required this.ownerId, required this.startDate, required this.endDate,
    this.totalDays, required this.pricePerDay, required this.subtotal,
    this.taxAmount = 0, required this.totalAmount,
    required this.status, required this.paymentStatus,
    this.bookingNotes, this.cancellationReason, required this.createdAt,
    this.vehicleTitle, this.vehicleType, this.vehicleImage,
    this.farmerName, this.farmerPhone, this.ownerName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> j) {
    final imgs = j['vehicles']?['image_urls'];
    return BookingModel(
      id: j['id'] ?? '', vehicleId: j['vehicle_id'] ?? '',
      farmerId: j['farmer_id'] ?? '', ownerId: j['owner_id'] ?? '',
      startDate: DateTime.parse(j['start_date']),
      endDate:   DateTime.parse(j['end_date']),
      totalDays: j['total_days']?.toDouble(),
      pricePerDay: (j['price_per_day'] ?? 0).toDouble(),
      subtotal:    (j['subtotal']    ?? 0).toDouble(),
      taxAmount:   (j['tax_amount']  ?? 0).toDouble(),
      totalAmount: (j['total_amount'] ?? 0).toDouble(),
      status: j['status'] ?? 'pending',
      paymentStatus: j['payment_status'] ?? 'unpaid',
      bookingNotes: j['booking_notes'],
      cancellationReason: j['cancellation_reason'],
      createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
      vehicleTitle: j['vehicles']?['title'],
      vehicleType:  j['vehicles']?['vehicle_type'],
      vehicleImage: (imgs is List && imgs.isNotEmpty) ? imgs[0] : null,
      farmerName:  j['farmer']?['full_name'],
      farmerPhone: j['farmer']?['phone'],
      ownerName:   j['owner']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId, 'farmer_id': farmerId, 'owner_id': ownerId,
    'start_date': startDate.toIso8601String(),
    'end_date':   endDate.toIso8601String(),
    'total_days': totalDays, 'price_per_day': pricePerDay,
    'subtotal': subtotal, 'tax_amount': taxAmount,
    'total_amount': totalAmount, 'status': status,
    'payment_status': paymentStatus, 'booking_notes': bookingNotes,
  };

  int get durationDays => endDate.difference(startDate).inDays;
  String get formattedTotal => '₹\${totalAmount.toStringAsFixed(0)}';
}
