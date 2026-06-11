// lib/screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _vehicleService = VehicleService();
  final _bookingService = BookingService();

  int _totalVehicles = 0;
  int _pendingApprovals = 0;
  int _totalBookings = 0;
  int _activeBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getAllVehicles();
      final bookings = await _bookingService.getAllBookings();

      _totalVehicles = vehicles.length;
      _pendingApprovals = vehicles.where((v) => !v.isApproved).length;
      _totalBookings = bookings.length;
      _activeBookings = bookings.where((b) => b.status == 'active').length;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.errorRed),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.greyLight,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.primaryGreenDark,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1A237E),
                        AppTheme.primaryGreenDark,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                              ),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.admin_panel_settings,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dashboard Cards
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen),
                      ),
                    )
                  else ...[
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _AdminStatCard(
                          label: 'Total Vehicles',
                          value: '$_totalVehicles',
                          icon: Icons.agriculture,
                          color: AppTheme.primaryGreen,
                          onTap: () => context.go('/admin/vehicles'),
                        ),
                        _AdminStatCard(
                          label: 'Pending Approvals',
                          value: '$_pendingApprovals',
                          icon: Icons.pending_actions,
                          color: AppTheme.warningOrange,
                          onTap: () => context.go('/admin/vehicles'),
                        ),
                        _AdminStatCard(
                          label: 'Total Bookings',
                          value: '$_totalBookings',
                          icon: Icons.book_online,
                          color: AppTheme.skyBlue,
                          onTap: () => context.go('/admin/bookings'),
                        ),
                        _AdminStatCard(
                          label: 'Active Rentals',
                          value: '$_activeBookings',
                          icon: Icons.directions_run,
                          color: AppTheme.accentAmber,
                          onTap: () => context.go('/admin/bookings'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Text('Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),

                    _QuickActionTile(
                      icon: Icons.people,
                      label: 'Manage Users',
                      subtitle: 'View and manage all registered users',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.go('/admin/users'),
                    ),
                    _QuickActionTile(
                      icon: Icons.agriculture,
                      label: 'Manage Vehicles',
                      subtitle: 'Approve or reject vehicle listings',
                      color: AppTheme.skyBlue,
                      onTap: () => context.go('/admin/vehicles'),
                    ),
                    _QuickActionTile(
                      icon: Icons.book_online,
                      label: 'View Bookings',
                      subtitle: 'Monitor all platform bookings',
                      color: AppTheme.accentAmber,
                      onTap: () => context.go('/admin/bookings'),
                    ),
                    _QuickActionTile(
                      icon: Icons.bar_chart,
                      label: 'Analytics',
                      subtitle: 'Platform performance & insights',
                      color: AppTheme.accentOrange,
                      onTap: () => context.go('/admin/analytics'),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout,
                              color: AppTheme.errorRed, size: 22),
                        ),
                        title: const Text('Logout',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorRed)),
                        subtitle: const Text('Sign out of Admin Dashboard',
                            style: TextStyle(
                                color: AppTheme.greyText, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppTheme.errorRed),
                        onTap: _logout,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pending approvals alert
                    if (_pendingApprovals > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.warningOrange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: AppTheme.warningOrange, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_pendingApprovals Vehicle${_pendingApprovals > 1 ? 's' : ''} Awaiting Approval',
                                    style: const TextStyle(
                                      color: AppTheme.warningOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Review and approve/reject vehicle submissions',
                                    style: TextStyle(
                                        color: AppTheme.greyText, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/admin/vehicles'),
                              child: const Text('Review'),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.greyText, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: color),
        onTap: onTap,
      ),
    );
  }
}
