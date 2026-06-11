// lib/screens/farmer/vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _vehicleService = VehicleService();
  VehicleModel? _vehicle;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      _vehicle = await _vehicleService.getVehicleById(widget.vehicleId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicle: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle Details')),
        body: const Center(child: Text('Vehicle not found')),
      );
    }

    final vehicle = _vehicle!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Image Gallery AppBar ──────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (vehicle.imageUrls.isNotEmpty)
                    PageView.builder(
                      itemCount: vehicle.imageUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: vehicle.imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.lightGreen,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.lightGreen,
                          child: const Icon(Icons.agriculture,
                              size: 80, color: AppTheme.primaryGreenLight),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.lightGreen,
                      child: const Center(
                        child: Icon(Icons.agriculture,
                            size: 100, color: AppTheme.primaryGreenLight),
                      ),
                    ),
                  // Image indicators
                  if (vehicle.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          vehicle.imageUrls.length,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentImageIndex
                                  ? AppTheme.primaryGreen
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.title,
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGreen,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.primaryGreenLight),
                              ),
                              child: Text(
                                vehicle.vehicleType,
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 18, color: AppTheme.accentAmber),
                              const SizedBox(width: 4),
                              Text(
                                vehicle.averageRating.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${vehicle.totalBookings} bookings',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.city ?? ''}, ${vehicle.state ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppTheme.greyText),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Pricing
                  Row(
                    children: [
                      Expanded(
                        child: _priceBadge(
                          '₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                          'Per Day',
                          AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _priceBadge(
                          '₹${vehicle.pricePerHour.toStringAsFixed(0)}',
                          'Per Hour',
                          AppTheme.skyBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Vehicle Specs
                  Text('Specifications',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (vehicle.brand != null)
                        _specChip(Icons.branding_watermark,
                            'Brand: ${vehicle.brand}'),
                      if (vehicle.model != null)
                        _specChip(Icons.model_training, 'Model: ${vehicle.model}'),
                      if (vehicle.year != null)
                        _specChip(Icons.calendar_today, 'Year: ${vehicle.year}'),
                      if (vehicle.fuelType != null)
                        _specChip(Icons.local_gas_station,
                            'Fuel: ${vehicle.fuelType}'),
                      if (vehicle.horsepower != null)
                        _specChip(Icons.speed, '${vehicle.horsepower} HP'),
                      if (vehicle.capacity != null)
                        _specChip(Icons.agriculture,
                            'Capacity: ${vehicle.capacity}'),
                    ],
                  ),

                  // Description
                  if (vehicle.description != null) ...[
                    const SizedBox(height: 20),
                    Text('Description',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      vehicle.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: AppTheme.greyText,
                          ),
                    ),
                  ],

                  // Features
                  if (vehicle.features.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Features',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ...vehicle.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppTheme.primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(f, style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Owner Info
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Vehicle Owner',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.lightGreen,
                        child: Text(
                          (vehicle.ownerName ?? 'O')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.ownerName ?? 'Vehicle Owner',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (vehicle.ownerPhone != null)
                            Text(
                              vehicle.ownerPhone!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.greyText),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 100), // space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Book Button ───────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text('Onwards', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: vehicle.isAvailable
                        ? () => context.push('/book/${vehicle.id}')
                        : null,
                    child: Text(
                      vehicle.isAvailable ? 'Book Now' : 'Not Available',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceBadge(String price, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            price,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _specChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.greyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.greyText)),
        ],
      ),
    );
  }
}
