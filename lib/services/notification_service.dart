// lib/services/notification_service.dart
import '../models/notification_model.dart';
import 'supabase_service.dart';

class NotificationService {
  final _svc = SupabaseService();

  /// Send a notification to a user.
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    String? relatedId,
  }) async {
    await _svc.client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type ?? 'system',
      'is_read': false,
      'related_id': relatedId,
    });
  }

  /// Get all notifications for a user, newest first.
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final rows = await _svc.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((n) => NotificationModel.fromJson(n)).toList();
  }

  /// Count unread notifications.
  Future<int> getUnreadCount(String userId) async {
    final rows = await _svc.client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (rows as List).length;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _svc.client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  /// Mark all notifications for a user as read.
  Future<void> markAllAsRead(String userId) async {
    await _svc.client
        .from('notifications')
        .update({'is_read': true}).eq('user_id', userId);
  }

  /// Subscribe to real-time notification inserts for a user.
  Stream<NotificationModel> subscribeToNotifications(String userId) {
    return _svc.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.isNotEmpty
            ? NotificationModel.fromJson(rows.first)
            : NotificationModel(
                id: '',
                userId: userId,
                title: '',
                message: '',
                createdAt: DateTime.now(),
              ));
  }

  // ── Booking Notification Helpers ──────────────────────────────

  /// Notify owner that a farmer booked their vehicle.
  Future<void> notifyOwnerNewBooking({
    required String ownerId,
    required String farmerName,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: ownerId,
        title: 'New Booking Request! 🎉',
        message:
            '$farmerName has booked your "$vehicleTitle". Please review and confirm.',
        type: 'booking',
        relatedId: bookingId,
      );

  /// Notify farmer that owner confirmed their booking.
  Future<void> notifyFarmerBookingConfirmed({
    required String farmerId,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: farmerId,
        title: 'Booking Confirmed! ✅',
        message:
            'Your booking for "$vehicleTitle" has been confirmed by the owner.',
        type: 'booking',
        relatedId: bookingId,
      );

  /// Notify farmer that owner rejected their booking.
  Future<void> notifyFarmerBookingRejected({
    required String farmerId,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: farmerId,
        title: 'Booking Rejected ❌',
        message:
            'Your booking for "$vehicleTitle" was rejected by the owner. Try another vehicle.',
        type: 'booking',
        relatedId: bookingId,
      );

  /// Notify farmer that booking is now active.
  Future<void> notifyFarmerBookingActive({
    required String farmerId,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: farmerId,
        title: 'Booking Active! 🚜',
        message: 'Your booking for "$vehicleTitle" is now active. Happy farming!',
        type: 'booking',
        relatedId: bookingId,
      );

  /// Notify farmer that booking is completed.
  Future<void> notifyFarmerBookingCompleted({
    required String farmerId,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: farmerId,
        title: 'Booking Completed! 🎊',
        message:
            'Your booking for "$vehicleTitle" is completed. Please leave a review!',
        type: 'booking',
        relatedId: bookingId,
      );

  /// Notify owner that farmer cancelled a booking.
  Future<void> notifyOwnerBookingCancelled({
    required String ownerId,
    required String farmerName,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: ownerId,
        title: 'Booking Cancelled 🔴',
        message: '$farmerName cancelled their booking for "$vehicleTitle".',
        type: 'booking',
        relatedId: bookingId,
      );

  /// Notify about payment.
  Future<void> notifyPaymentReceived({
    required String ownerId,
    required String amount,
    required String vehicleTitle,
    required String bookingId,
  }) =>
      sendNotification(
        userId: ownerId,
        title: 'Payment Received! 💰',
        message: 'Payment of ₹$amount received for "$vehicleTitle".',
        type: 'payment',
        relatedId: bookingId,
      );
}
