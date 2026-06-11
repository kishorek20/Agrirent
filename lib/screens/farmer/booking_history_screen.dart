// lib/screens/farmer/booking_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _bookingService = BookingService();
  final _notificationService = NotificationService();
  late TabController _tabController;

  List<BookingModel> _allBookings = [];
  bool _isLoading = true;

  final _tabs = ['All', 'Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser!;
      _allBookings = await _bookingService.getFarmerBookings(user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<BookingModel> _filteredBookings(String tab) {
    if (tab == 'All') return _allBookings;
    return _allBookings
        .where((b) => b.status.toLowerCase() == tab.toLowerCase())
        .toList();
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final reason = await _showCancelDialog();
    if (reason == null) return;

    try {
      await _bookingService.cancelBooking(booking.id, reason);
      // Notify owner about cancellation
      final user = context.read<AuthProvider>().currentUser!;
      await _notificationService.notifyOwnerBookingCancelled(
        ownerId: booking.ownerId,
        farmerName: user.fullName,
        vehicleTitle: booking.vehicleTitle ?? 'Vehicle',
        bookingId: booking.id,
      );
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled. Owner has been notified.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentAmber,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final bookings = _filteredBookings(tab);
                if (bookings.isEmpty) {
                  return _emptyState(tab);
                }
                return RefreshIndicator(
                  onRefresh: _loadBookings,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) =>
                        _BookingCard(
                          booking: bookings[index],
                          onCancel: bookings[index].status == 'pending'
                              ? () => _cancelBooking(bookings[index])
                              : null,
                        ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _emptyState(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tab == 'All' ? Icons.calendar_today : Icons.inbox,
            size: 80,
            color: AppTheme.primaryGreenLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            tab == 'All' ? 'No Bookings Yet' : 'No $tab Bookings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by searching for available vehicles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;

  const _BookingCard({required this.booking, this.onCancel});

  Color get _statusColor {
    switch (booking.status) {
      case 'pending': return AppTheme.warningOrange;
      case 'confirmed': return AppTheme.skyBlue;
      case 'active': return AppTheme.primaryGreen;
      case 'completed': return AppTheme.greyText;
      case 'cancelled': return AppTheme.errorRed;
      case 'rejected': return AppTheme.errorRed;
      default: return AppTheme.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.vehicleTitle ?? 'Vehicle',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (booking.vehicleType != null) ...[
              const SizedBox(height: 4),
              Text(
                booking.vehicleType!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.primaryGreen),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Dates
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.greyText),
                const SizedBox(width: 6),
                Text(
                  '${fmt.format(booking.startDate)} → ${fmt.format(booking.endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppTheme.greyText),
                const SizedBox(width: 6),
                Text(
                  '${booking.durationDays} day${booking.durationDays > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Amount',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                // Payment status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.paymentStatus == 'paid'
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: booking.paymentStatus == 'paid'
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Cancel button for pending bookings
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                  ),
                ),
              ),
            ],

            // Cancellation reason
            if (booking.status == 'cancelled' &&
                booking.cancellationReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.errorRed.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Reason: ${booking.cancellationReason}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.errorRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
