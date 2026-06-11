// lib/services/review_service.dart
import '../models/review_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class ReviewService {
  final _svc = SupabaseService();

  Future<List<ReviewModel>> getVehicleReviews(String vehicleId) async {
    final rows = await _svc.client.from(AppConstants.reviewsTable)
        .select('*, users(full_name)')
        .eq('vehicle_id', vehicleId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => ReviewModel.fromJson(r)).toList();
  }

  Future<void> addReview({
    required String bookingId, required String vehicleId,
    required String farmerId, required int rating, String? reviewText,
  }) async {
    await _svc.client.from(AppConstants.reviewsTable).insert({
      'booking_id': bookingId, 'vehicle_id': vehicleId,
      'farmer_id': farmerId, 'rating': rating, 'review_text': reviewText,
    });
  }

  Future<bool> hasReview(String bookingId) async {
    final row = await _svc.client.from(AppConstants.reviewsTable)
        .select('id').eq('booking_id', bookingId).maybeSingle();
    return row != null;
  }
}
