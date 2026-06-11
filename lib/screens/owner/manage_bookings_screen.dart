// lib/screens/owner/manage_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _bookingService = BookingService();
  final _notificationService = NotificationService();
  late TabController _tabController;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  final _tabs = ['All', 'Pending', 'Confirmed', 'Active', 'Completed'];

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
      _bookings = await _bookingService.getOwnerBookings(user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(BookingModel booking, String newStatus) async {
    try {
      await _bookingService.updateBookingStatus(booking.id, newStatus);

      // Send notification to farmer based on status change
      switch (newStatus) {
        case 'confirmed':
          await _notificationService.notifyFarmerBookingConfirmed(
            farmerId: booking.farmerId,
            vehicleTitle: booking.vehicleTitle ?? 'Vehicle',
            bookingId: booking.id,
          );
          break;
        case 'rejected':
          await _notificationService.notifyFarmerBookingRejected(
            farmerId: booking.farmerId,
            vehicleTitle: booking.vehicleTitle ?? 'Vehicle',
            bookingId: booking.id,
          );
          break;
        case 'active':
          await _notificationService.notifyFarmerBookingActive(
            farmerId: booking.farmerId,
            vehicleTitle: booking.vehicleTitle ?? 'Vehicle',
            bookingId: booking.id,
          );
          break;
        case 'completed':
          await _notificationService.notifyFarmerBookingCompleted(
            farmerId: booking.farmerId,
            vehicleTitle: booking.vehicleTitle ?? 'Vehicle',
            bookingId: booking.id,
          );
          break;
      }

      await _loadBookings();
      if (mounted) {
        final msg = newStatus == 'confirmed'
            ? 'Booking confirmed! Farmer notified.'
            : newStatus == 'rejected'
                ? 'Booking rejected. Farmer notified.'
                : newStatus == 'active'
                    ? 'Booking marked active! Farmer notified.'
                    : 'Booking completed! Farmer notified.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor:
                newStatus == 'rejected' ? AppTheme.errorRed : AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<BookingModel> _filteredBookings(String tab) {
    if (tab == 'All') return _bookings;
    return _bookings
        .where((b) => b.status.toLowerCase() == tab.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentAmber,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final list = _filteredBookings(tab);
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox,
                            size: 80, color: AppTheme.primaryGreenLight),
                        const SizedBox(height: 16),
                        Text('No ${tab == 'All' ? '' : tab} Bookings',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadBookings,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _OwnerBookingCard(
                      booking: list[i],
                      onConfirm: list[i].status == 'pending'
                          ? () => _updateStatus(list[i], 'confirmed')
                          : null,
                      onReject: list[i].status == 'pending'
                          ? () => _updateStatus(list[i], 'rejected')
                          : null,
                      onComplete: list[i].status == 'active'
                          ? () => _updateStatus(list[i], 'completed')
                          : null,
                      onActivate: list[i].status == 'confirmed'
                          ? () => _updateStatus(list[i], 'active')
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _OwnerBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onActivate;

  const _OwnerBookingCard({
    required this.booking,
    this.onConfirm,
    this.onReject,
    this.onComplete,
    this.onActivate,
  });

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
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Farmer info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.lightGreen,
                  child: Text(
                    (booking.farmerName ?? 'F')[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.farmerName ?? 'Farmer',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (booking.farmerPhone != null)
                      Text(booking.farmerPhone!,
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Dates & amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fmt.format(booking.startDate)} → ${fmt.format(booking.endDate)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.durationDays} days',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: booking.paymentStatus == 'paid'
                            ? AppTheme.successGreen.withValues(alpha: 0.1)
                            : AppTheme.warningOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        booking.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          color: booking.paymentStatus == 'paid'
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Notes
            if (booking.bookingNotes != null &&
                booking.bookingNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.greyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📝 ${booking.bookingNotes}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],

            // Action buttons
            if (onConfirm != null || onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                        ),
                      ),
                    ),
                  if (onReject != null && onConfirm != null)
                    const SizedBox(width: 12),
                  if (onConfirm != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirm'),
                      ),
                    ),
                ],
              ),
            ],

            if (onActivate != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onActivate,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Mark as Active'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                  ),
                ),
              ),
            ],

            if (onComplete != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
