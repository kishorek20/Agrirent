// lib/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/vehicle_model.dart';
import '../utils/app_theme.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/vehicle/${vehicle.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: vehicle.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vehicle.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(vehicle.vehicleType,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (!vehicle.isAvailable)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.errorRed, borderRadius: BorderRadius.circular(20)),
                        child: const Text('UNAVAILABLE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on, size: 11, color: AppTheme.greyText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(vehicle.locationLabel,
                            style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          const Text('/day', style: TextStyle(fontSize: 10, color: AppTheme.greyText)),
                        ]),
                        Row(children: [
                          const Icon(Icons.star, size: 13, color: AppTheme.accentAmber),
                          const SizedBox(width: 2),
                          Text(vehicle.averageRating > 0
                              ? vehicle.averageRating.toStringAsFixed(1) : 'New',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.greyText)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.lightGreen,
    child: const Center(child: Icon(Icons.agriculture, size: 48, color: AppTheme.primaryGreenLight)),
  );
}
