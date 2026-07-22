// lib/widgets/similar_vehicles_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/vehicle_model.dart';
import '../utils/app_theme.dart';

class SimilarVehiclesWidget extends StatelessWidget {
  final List<VehicleModel> similarVehicles;

  const SimilarVehiclesWidget({
    super.key,
    required this.similarVehicles,
  });

  @override
  Widget build(BuildContext context) {
    if (similarVehicles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.recommend, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                'Similar Vehicles Recommended',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: similarVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = similarVehicles[index];
              return _similarVehicleCard(context, vehicle);
            },
          ),
        ),
      ],
    );
  }

  Widget _similarVehicleCard(BuildContext context, VehicleModel vehicle) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/vehicle/${vehicle.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: vehicle.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: vehicle.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTheme.lightGreen),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.lightGreen,
                              child: const Icon(Icons.agriculture, color: AppTheme.primaryGreenLight),
                            ),
                          )
                        : Container(
                            color: AppTheme.lightGreen,
                            child: const Icon(Icons.agriculture, color: AppTheme.primaryGreenLight),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: AppTheme.accentAmber),
                          const SizedBox(width: 2),
                          Text(
                            vehicle.averageRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.locationLabel.isNotEmpty ? vehicle.locationLabel : vehicle.vehicleType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
