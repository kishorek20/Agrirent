// lib/screens/owner/earnings_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../utils/app_theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _bookingService = BookingService();
  Map<String, dynamic> _earnings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser!;
      _earnings = await _bookingService.getOwnerEarnings(user.id);
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
        title: const Text('Earnings Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Total Earnings Banner ──────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryGreenDark,
                            AppTheme.primaryGreen
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.white70, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Total Earnings',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${(_earnings['total_earnings'] ?? 0.0).toStringAsFixed(0)}',
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

                    // ── Stats Grid ────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'This Month',
                            value:
                                '₹${(_earnings['this_month'] ?? 0.0).toStringAsFixed(0)}',
                            icon: Icons.calendar_month,
                            color: AppTheme.skyBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Bookings',
                            value:
                                '${_earnings['total_bookings'] ?? 0}',
                            icon: Icons.book_online,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Avg per Booking',
                            value: _earnings['total_bookings'] != null &&
                                    (_earnings['total_bookings'] as int) > 0
                                ? '₹${((_earnings['total_earnings'] ?? 0) / (_earnings['total_bookings'] as int)).toStringAsFixed(0)}'
                                : '₹0',
                            icon: Icons.trending_up,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _StatCard(
                            label: 'Rating',
                            value: '4.5 ⭐',
                            icon: Icons.star,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Bar Chart ─────────────────────────────
                    Text('Monthly Overview',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10000,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const months = [
                                        'Jan', 'Feb', 'Mar', 'Apr',
                                        'May', 'Jun', 'Jul', 'Aug',
                                        'Sep', 'Oct', 'Nov', 'Dec'
                                      ];
                                      final idx = value.toInt();
                                      return Text(
                                        idx < months.length
                                            ? months[idx]
                                            : '',
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
                                      '₹${(v / 1000).toStringAsFixed(0)}k',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.greyText),
                                    ),
                                    reservedSize: 36,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 2500,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(
                                12,
                                (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _mockMonthlyData[i],
                                      color: i == DateTime.now().month - 1
                                          ? AppTheme.primaryGreen
                                          : AppTheme.primaryGreenLight
                                              .withValues(alpha: 0.5),
                                      width: 14,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Payout Info ────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreenLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppTheme.primaryGreen),
                              SizedBox(width: 8),
                              Text(
                                'Payout Information',
                                style: TextStyle(
                                  color: AppTheme.primaryGreenDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _payoutRow('Platform Commission', '5%'),
                          _payoutRow('Payout Cycle', 'Every 7 days'),
                          _payoutRow('Payment Method', 'Bank Transfer / UPI'),
                          _payoutRow('Tax (TDS)', '2%'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // Dummy monthly data for chart
  final List<double> _mockMonthlyData = [
    3200, 4500, 2800, 6200, 5100, 7800,
    4300, 8900, 6700, 5400, 9200, 7100,
  ];

  Widget _payoutRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.greyText, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.primaryGreenDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.greyText, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
