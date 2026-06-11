// lib/screens/admin/view_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_theme.dart';

class ViewBookingsScreen extends StatefulWidget {
  const ViewBookingsScreen({super.key});

  @override
  State<ViewBookingsScreen> createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends State<ViewBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _bookingService = BookingService();
  late TabController _tabController;
  List<BookingModel> _all = [];
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
      _all = await _bookingService.getAllBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<BookingModel> _filtered(String tab) {
    if (tab == 'All') return _all;
    return _all.where((b) => b.status.toLowerCase() == tab.toLowerCase()).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
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
                final list = _filtered(tab);
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.book_online,
                            size: 80, color: AppTheme.primaryGreenLight),
                        const SizedBox(height: 16),
                        Text('No $tab Bookings',
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
                    itemBuilder: (context, i) {
                      final b = list[i];
                      final sc = _statusColor(b.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      b.vehicleTitle ?? 'Vehicle',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: sc.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: sc),
                                    ),
                                    child: Text(
                                      b.status.toUpperCase(),
                                      style: TextStyle(
                                          color: sc,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _infoRow(Icons.grass, 'Farmer', b.farmerName ?? '-'),
                              _infoRow(Icons.agriculture, 'Owner', b.ownerName ?? '-'),
                              _infoRow(
                                Icons.calendar_today,
                                'Dates',
                                '${fmt.format(b.startDate)} → ${fmt.format(b.endDate)}',
                              ),
                              _infoRow(
                                Icons.currency_rupee,
                                'Amount',
                                '₹${b.totalAmount.toStringAsFixed(0)} (${b.paymentStatus})',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.greyText),
            const SizedBox(width: 6),
            Text('$label: ', style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
