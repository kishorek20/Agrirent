// lib/services/booking_service.dart
import '../models/booking_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class BookingService {
  final _svc = SupabaseService();

  static const _select = '''
    *,
    vehicles(title, image_urls, vehicle_type),
    farmer:users!bookings_farmer_id_fkey(full_name, phone),
    owner:users!bookings_owner_id_fkey(full_name, phone)
  ''';

  Future<String> createBooking(Map<String, dynamic> data) async {
    final row = await _svc.client.from(AppConstants.bookingsTable)
        .insert(data).select('id').single();
    return row['id'] as String;
  }

  Future<List<BookingModel>> getFarmerBookings(String farmerId) async {
    final rows = await _svc.client.from(AppConstants.bookingsTable)
        .select(_select).eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return (rows as List).map((b) => BookingModel.fromJson(b)).toList();
  }

  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    final rows = await _svc.client.from(AppConstants.bookingsTable)
        .select(_select).eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (rows as List).map((b) => BookingModel.fromJson(b)).toList();
  }

  Future<List<BookingModel>> getAllBookings() async {
    final rows = await _svc.client.from(AppConstants.bookingsTable)
        .select(_select).order('created_at', ascending: false);
    return (rows as List).map((b) => BookingModel.fromJson(b)).toList();
  }

  Future<void> updateBookingStatus(String id, String status) =>
      _svc.client.from(AppConstants.bookingsTable)
          .update({'status': status}).eq('id', id);

  Future<void> updatePaymentStatus(String id, String paymentStatus) =>
      _svc.client.from(AppConstants.bookingsTable)
          .update({'payment_status': paymentStatus}).eq('id', id);

  Future<void> cancelBooking(String id, String reason) =>
      _svc.client.from(AppConstants.bookingsTable).update({
        'status': AppConstants.bookingCancelled,
        'cancellation_reason': reason,
      }).eq('id', id);

  /// Returns true when no confirmed/active bookings overlap the given range.
  Future<bool> isVehicleAvailable(
      String vehicleId, DateTime start, DateTime end) async {
    final rows = await _svc.client.from(AppConstants.bookingsTable)
        .select('id')
        .eq('vehicle_id', vehicleId)
        .inFilter('status', ['confirmed', 'active'])
        .lt('start_date', end.toIso8601String())
        .gt('end_date', start.toIso8601String());
    return (rows as List).isEmpty;
  }

  /// Summarise paid earnings for a given owner.
  Future<Map<String, dynamic>> getOwnerEarnings(String ownerId) async {
    final rows = await _svc.client.from(AppConstants.bookingsTable)
        .select('total_amount, created_at')
        .eq('owner_id', ownerId)
        .eq('payment_status', 'paid');
    final list  = rows as List;
    final now   = DateTime.now();
    double total = 0, month = 0;
    for (final b in list) {
      final amt = (b['total_amount'] ?? 0).toDouble();
      total += amt;
      final dt = DateTime.parse(b['created_at']);
      if (dt.year == now.year && dt.month == now.month) month += amt;
    }
    return {'total_earnings': total, 'this_month': month, 'total_bookings': list.length};
  }
}
