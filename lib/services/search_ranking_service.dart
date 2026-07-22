// lib/services/search_ranking_service.dart
import '../models/vehicle_model.dart';

class SuggestionItem {
  final String text;
  final String category; // 'Category', 'Vehicle', 'Brand', 'Location'
  final String subtitle;

  SuggestionItem({
    required this.text,
    required this.category,
    required this.subtitle,
  });
}

class SearchRankingService {
  /// Ranks vehicles based on search query relevance, ratings, bookings popularity, and location.
  static List<VehicleModel> rankVehicles(
    List<VehicleModel> vehicles, {
    String? query,
    String? userCity,
    String? userState,
    String sortBy = 'recommended', // 'recommended', 'rating', 'bookings', 'price_low', 'price_high'
  }) {
    if (sortBy == 'price_low') {
      final list = List<VehicleModel>.from(vehicles);
      list.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      return list;
    }
    if (sortBy == 'price_high') {
      final list = List<VehicleModel>.from(vehicles);
      list.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
      return list;
    }
    if (sortBy == 'rating') {
      final list = List<VehicleModel>.from(vehicles);
      list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      return list;
    }
    if (sortBy == 'bookings') {
      final list = List<VehicleModel>.from(vehicles);
      list.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
      return list;
    }

    // Default: 'recommended' - Intelligent Ranking Score
    final q = query?.trim().toLowerCase() ?? '';
    final uCity = userCity?.trim().toLowerCase() ?? '';
    final uState = userState?.trim().toLowerCase() ?? '';

    final scored = vehicles.map((v) {
      double score = 0.0;

      // 1. Text Relevance Score (0 - 50 points)
      if (q.isNotEmpty) {
        final title = v.title.toLowerCase();
        final brand = (v.brand ?? '').toLowerCase();
        final model = (v.model ?? '').toLowerCase();
        final type = v.vehicleType.toLowerCase();
        final city = (v.city ?? '').toLowerCase();
        final desc = (v.description ?? '').toLowerCase();

        if (title == q) {
          score += 50;
        } else if (title.startsWith(q)) {
          score += 40;
        } else if (title.contains(q)) {
          score += 30;
        }

        if (brand.contains(q)) score += 20;
        if (model.contains(q)) score += 20;
        if (type.contains(q)) score += 25;
        if (city.contains(q)) score += 15;
        if (desc.contains(q)) score += 10;
      }

      // 2. Rating & Review Score (0 - 25 points)
      score += (v.averageRating / 5.0) * 25.0;

      // 3. Popularity / Total Bookings Score (0 - 15 points)
      final bookingFactor = (v.totalBookings / 30.0).clamp(0.0, 1.0);
      score += bookingFactor * 15.0;

      // 4. Location Proximity Score (0 - 10 points)
      if (uCity.isNotEmpty && (v.city?.toLowerCase() == uCity)) {
        score += 10;
      } else if (uState.isNotEmpty && (v.state?.toLowerCase() == uState)) {
        score += 5;
      }

      // 5. Recency Boost (0 - 5 points)
      final ageInDays = DateTime.now().difference(v.createdAt).inDays;
      if (ageInDays <= 7) {
        score += 5;
      } else if (ageInDays <= 30) {
        score += 3;
      }

      return MapEntry(v, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Generates dynamic search suggestions based on input query.
  static List<SuggestionItem> getSearchSuggestions(
    List<VehicleModel> vehicles,
    String query, {
    int limit = 8,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final suggestions = <SuggestionItem>[];
    final addedTexts = <String>{};

    // 1. Vehicle Types
    for (final v in vehicles) {
      if (v.vehicleType.toLowerCase().contains(q) &&
          !addedTexts.contains(v.vehicleType.toLowerCase())) {
        addedTexts.add(v.vehicleType.toLowerCase());
        suggestions.add(SuggestionItem(
          text: v.vehicleType,
          category: 'Category',
          subtitle: 'Vehicle Category',
        ));
      }
    }

    // 2. Titles
    for (final v in vehicles) {
      if (v.title.toLowerCase().contains(q) &&
          !addedTexts.contains(v.title.toLowerCase())) {
        addedTexts.add(v.title.toLowerCase());
        suggestions.add(SuggestionItem(
          text: v.title,
          category: 'Vehicle',
          subtitle: '${v.vehicleType} • ${v.city ?? 'Local'}',
        ));
      }
    }

    // 3. Brands & Models
    for (final v in vehicles) {
      if (v.brand != null &&
          v.brand!.toLowerCase().contains(q) &&
          !addedTexts.contains(v.brand!.toLowerCase())) {
        addedTexts.add(v.brand!.toLowerCase());
        suggestions.add(SuggestionItem(
          text: v.brand!,
          category: 'Brand',
          subtitle: 'Manufacturer',
        ));
      }
    }

    // 4. Cities / Locations
    for (final v in vehicles) {
      if (v.city != null &&
          v.city!.toLowerCase().contains(q) &&
          !addedTexts.contains(v.city!.toLowerCase())) {
        addedTexts.add(v.city!.toLowerCase());
        suggestions.add(SuggestionItem(
          text: v.city!,
          category: 'Location',
          subtitle: v.state ?? 'City',
        ));
      }
    }

    return suggestions.take(limit).toList();
  }

  /// Finds vehicles similar to [target].
  static List<VehicleModel> getSimilarVehicles(
    VehicleModel target,
    List<VehicleModel> allVehicles, {
    int limit = 6,
  }) {
    final candidates = allVehicles
        .where((v) => v.id != target.id && v.isAvailable && v.isApproved)
        .toList();

    final scored = candidates.map((v) {
      double score = 0.0;

      // 1. Same Vehicle Type (+40 points)
      if (v.vehicleType.toLowerCase() == target.vehicleType.toLowerCase()) {
        score += 40;
      }

      // 2. Location proximity (+20 points)
      if (v.city != null &&
          target.city != null &&
          v.city!.toLowerCase() == target.city!.toLowerCase()) {
        score += 20;
      } else if (v.state != null &&
          target.state != null &&
          v.state!.toLowerCase() == target.state!.toLowerCase()) {
        score += 10;
      }

      // 3. Price Similarity (+20 points)
      if (target.pricePerDay > 0) {
        final diffRatio =
            (v.pricePerDay - target.pricePerDay).abs() / target.pricePerDay;
        if (diffRatio <= 0.15) {
          score += 20;
        } else if (diffRatio <= 0.30) {
          score += 12;
        } else if (diffRatio <= 0.50) {
          score += 5;
        }
      }

      // 4. Brand match (+10 points)
      if (v.brand != null &&
          target.brand != null &&
          v.brand!.toLowerCase() == target.brand!.toLowerCase()) {
        score += 10;
      }

      // 5. Rating boost (+10 points)
      score += (v.averageRating / 5.0) * 10.0;

      return MapEntry(v, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(limit).toList();
  }
}
