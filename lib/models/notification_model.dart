// lib/models/notification_model.dart
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? type; // booking, payment, system
  final bool isRead;
  final String? relatedId; // booking_id or payment_id
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    this.relatedId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] ?? '',
        userId: j['user_id'] ?? '',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        type: j['type'],
        isRead: j['is_read'] ?? false,
        relatedId: j['related_id'],
        createdAt: DateTime.parse(
            j['created_at'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
        'related_id': relatedId,
      };
}
