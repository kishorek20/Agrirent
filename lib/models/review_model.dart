// lib/models/review_model.dart
class ReviewModel {
  final String id;
  final String bookingId;
  final String vehicleId;
  final String farmerId;
  final int rating;
  final String? reviewText;
  final String? ownerReply;
  final bool isVisible;
  final DateTime createdAt;
  final String? farmerName;

  ReviewModel({
    required this.id, required this.bookingId, required this.vehicleId,
    required this.farmerId, required this.rating,
    this.reviewText, this.ownerReply, this.isVisible = true,
    required this.createdAt, this.farmerName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id: j['id'] ?? '', bookingId: j['booking_id'] ?? '',
    vehicleId: j['vehicle_id'] ?? '', farmerId: j['farmer_id'] ?? '',
    rating: j['rating'] ?? 0, reviewText: j['review_text'],
    ownerReply: j['owner_reply'], isVisible: j['is_visible'] ?? true,
    createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
    farmerName: j['users']?['full_name'],
  );

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId, 'vehicle_id': vehicleId,
    'farmer_id': farmerId, 'rating': rating, 'review_text': reviewText,
  };
}
