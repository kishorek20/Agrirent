// lib/screens/shared/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser!;
      _notifications =
          await _notificationService.getUserNotifications(user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markAllRead() async {
    try {
      final user = context.read<AuthProvider>().currentUser!;
      await _notificationService.markAllAsRead(user.id);
      await _loadNotifications();
    } catch (_) {}
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'booking':
        return Icons.book_online;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'booking':
        return AppTheme.skyBlue;
      case 'payment':
        return AppTheme.successGreen;
      default:
        return AppTheme.accentAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text('Read All',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off,
                          size: 80,
                          color: AppTheme.primaryGreenLight
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No Notifications',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('You\'re all caught up!',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final color = _colorForType(n.type);
                      final timeAgo = _formatTimeAgo(n.createdAt);
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppTheme.errorRed,
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: n.isRead
                              ? Colors.white
                              : color.withValues(alpha: 0.05),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              if (!n.isRead) {
                                await _notificationService
                                    .markAsRead(n.id);
                                await _loadNotifications();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          color.withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                        _iconForType(n.type),
                                        color: color,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight: n
                                                              .isRead
                                                          ? FontWeight
                                                              .w500
                                                          : FontWeight
                                                              .bold,
                                                    ),
                                              ),
                                            ),
                                            if (!n.isRead)
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration:
                                                    BoxDecoration(
                                                  shape:
                                                      BoxShape.circle,
                                                  color: color,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n.message,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          maxLines: 3,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.greyText
                                                .withValues(
                                                    alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
