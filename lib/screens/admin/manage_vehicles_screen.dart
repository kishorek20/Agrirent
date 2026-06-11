// lib/screens/admin/manage_vehicles_screen.dart
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';

class ManageVehiclesScreen extends StatefulWidget {
  const ManageVehiclesScreen({super.key});

  @override
  State<ManageVehiclesScreen> createState() => _ManageVehiclesScreenState();
}

class _ManageVehiclesScreenState extends State<ManageVehiclesScreen>
    with SingleTickerProviderStateMixin {
  final _vehicleService = VehicleService();
  late TabController _tabController;
  List<VehicleModel> _all = [];
  bool _isLoading = true;
  final _tabs = ['All', 'Pending', 'Approved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadVehicles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      _all = await _vehicleService.getAllVehicles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<VehicleModel> _filtered(String tab) {
    if (tab == 'All') return _all;
    if (tab == 'Pending') return _all.where((v) => !v.isApproved).toList();
    return _all.where((v) => v.isApproved).toList();
  }

  Future<void> _setApproval(VehicleModel v, bool approved) async {
    try {
      await _vehicleService.approveVehicle(v.id, approved);
      await _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${v.title} ${approved ? 'approved' : 'rejected'}!'),
          backgroundColor:
              approved ? AppTheme.successGreen : AppTheme.errorRed,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteVehicle(VehicleModel v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Delete "${v.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _vehicleService.deleteVehicle(v.id);
      await _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
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
                        const Icon(Icons.agriculture,
                            size: 80, color: AppTheme.primaryGreenLight),
                        const SizedBox(height: 16),
                        Text('No $tab Vehicles',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadVehicles,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _AdminVehicleCard(
                      vehicle: list[i],
                      onApprove: !list[i].isApproved
                          ? () => _setApproval(list[i], true)
                          : null,
                      onReject: list[i].isApproved
                          ? () => _setApproval(list[i], false)
                          : null,
                      onDelete: () => _deleteVehicle(list[i]),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _AdminVehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onDelete;

  const _AdminVehicleCard({
    required this.vehicle,
    this.onApprove,
    this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(vehicle.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vehicle.isApproved
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: vehicle.isApproved
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                    ),
                  ),
                  child: Text(
                    vehicle.isApproved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: vehicle.isApproved
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${vehicle.vehicleType} • ${vehicle.city ?? ''}, ${vehicle.state ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('Owner: ${vehicle.ownerName ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodyMedium),
            Text(
                '₹${vehicle.pricePerDay.toStringAsFixed(0)}/day • ${vehicle.totalBookings} bookings',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.primaryGreen)),

            const SizedBox(height: 12),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                if (onApprove != null) const SizedBox(width: 8),
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Revoke'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningOrange,
                        side: const BorderSide(
                            color: AppTheme.warningOrange),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (onReject != null) const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
