// lib/screens/admin/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/booking_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _bookingService = BookingService();
  final _vehicleService = VehicleService();

  int _totalVehicles = 0;
  int _approvedVehicles = 0;
  int _totalBookings = 0;
  int _completedBookings = 0;
  int _cancelledBookings = 0;
  double _totalRevenue = 0;
  bool _isLoading = true;

  // Monthly booking counts (dummy for chart)
  final List<double> _monthlyBookings = [
    4, 8, 6, 12, 10, 18, 15, 22, 19, 25, 20, 30,
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getAllVehicles();
      final bookings = await _bookingService.getAllBookings();

      _totalVehicles = vehicles.length;
      _approvedVehicles = vehicles.where((v) => v.isApproved).length;
      _totalBookings = bookings.length;
      _completedBookings =
          bookings.where((b) => b.status == 'completed').length;
      _cancelledBookings =
          bookings.where((b) => b.status == 'cancelled').length;
      _totalRevenue = bookings
          .where((b) => b.paymentStatus == 'paid')
          .fold(0, (sum, b) => sum + b.totalAmount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Revenue Banner ─────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), AppTheme.primaryGreenDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.monetization_on,
                              color: Colors.white70, size: 36),
                          const SizedBox(height: 8),
                          const Text('Total Platform Revenue',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Stats Grid ─────────────────────────────
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _AnalyticsCard(
                          label: 'Total Vehicles',
                          value: '$_totalVehicles',
                          sub: '$_approvedVehicles approved',
                          icon: Icons.agriculture,
                          color: AppTheme.primaryGreen,
                        ),
                        _AnalyticsCard(
                          label: 'Total Bookings',
                          value: '$_totalBookings',
                          sub: '$_completedBookings completed',
                          icon: Icons.book_online,
                          color: AppTheme.skyBlue,
                        ),
                        _AnalyticsCard(
                          label: 'Completion Rate',
                          value: _totalBookings > 0
                              ? '${((_completedBookings / _totalBookings) * 100).toStringAsFixed(0)}%'
                              : '0%',
                          sub: 'of all bookings',
                          icon: Icons.done_all,
                          color: AppTheme.successGreen,
                        ),
                        _AnalyticsCard(
                          label: 'Cancellation Rate',
                          value: _totalBookings > 0
                              ? '${((_cancelledBookings / _totalBookings) * 100).toStringAsFixed(0)}%'
                              : '0%',
                          sub: '$_cancelledBookings cancelled',
                          icon: Icons.cancel_outlined,
                          color: AppTheme.errorRed,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Monthly Bookings Chart ─────────────────
                    Text('Monthly Bookings Trend',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 16, 20),
                        child: SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 35,
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 10,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                                drawVerticalLine: false,
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (v, _) {
                                      const months = [
                                        'J', 'F', 'M', 'A', 'M', 'J',
                                        'J', 'A', 'S', 'O', 'N', 'D'
                                      ];
                                      final idx = v.toInt();
                                      return Text(
                                        idx < months.length ? months[idx] : '',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.greyText),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Text(
                                      '${v.toInt()}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.greyText),
                                    ),
                                    reservedSize: 28,
                                    interval: 10,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    12,
                                    (i) => FlSpot(
                                        i.toDouble(), _monthlyBookings[i]),
                                  ),
                                  isCurved: true,
                                  color: AppTheme.primaryGreen,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Booking Status Pie Chart ────────────────
                    Text('Booking Status Breakdown',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 160,
                              width: 160,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    _pieSection(
                                      'Completed',
                                      _completedBookings.toDouble(),
                                      AppTheme.primaryGreen,
                                    ),
                                    _pieSection(
                                      'Active',
                                      (_totalBookings -
                                              _completedBookings -
                                              _cancelledBookings)
                                          .toDouble()
                                          .clamp(0, double.infinity),
                                      AppTheme.skyBlue,
                                    ),
                                    _pieSection(
                                      'Cancelled',
                                      _cancelledBookings.toDouble(),
                                      AppTheme.errorRed,
                                    ),
                                  ],
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legend(AppTheme.primaryGreen,
                                      'Completed', '$_completedBookings'),
                                  const SizedBox(height: 10),
                                  _legend(
                                      AppTheme.skyBlue,
                                      'Others',
                                      '${_totalBookings - _completedBookings - _cancelledBookings}'),
                                  const SizedBox(height: 10),
                                  _legend(AppTheme.errorRed,
                                      'Cancelled', '$_cancelledBookings'),
                                  const SizedBox(height: 10),
                                  _legend(AppTheme.greyText,
                                      'Total', '$_totalBookings'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Vehicle Types Stats ────────────────────
                    Text('Platform Highlights',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _highlightRow('Avg Booking Value',
                        _totalBookings > 0
                            ? '₹${(_totalRevenue / _totalBookings).toStringAsFixed(0)}'
                            : '₹0'),
                    _highlightRow('Approval Rate',
                        _totalVehicles > 0
                            ? '${((_approvedVehicles / _totalVehicles) * 100).toStringAsFixed(0)}%'
                            : '0%'),
                    _highlightRow('Platform Commission (5%)',
                        '₹${(_totalRevenue * 0.05).toStringAsFixed(0)}'),
                    _highlightRow('Registered Vehicles', '$_totalVehicles'),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  PieChartSectionData _pieSection(String label, double value, Color color) {
    return PieChartSectionData(
      value: value <= 0 ? 0.001 : value,
      color: color,
      title: value > 0 ? '${value.toInt()}' : '',
      radius: 48,
      titleStyle: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  Widget _legend(Color color, String label, String value) => Row(
        children: [
          Container(
              width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: AppTheme.greyText, fontSize: 13))),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      );

  Widget _highlightRow(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.greyText, fontSize: 14)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 15)),
          ],
        ),
      );
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.greyText, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(sub,
                    style: const TextStyle(
                        color: AppTheme.greyText, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
