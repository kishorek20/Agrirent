// lib/services/smart_pricing_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

/// Result returned by the Smart Pricing engine.
class PriceSuggestion {
  final double suggestedDayPrice;
  final double suggestedHourPrice;
  final double minDayPrice;
  final double maxDayPrice;
  final String confidence; // 'High', 'Medium', 'Low'
  final List<String> factors; // Human-readable list of factors applied

  const PriceSuggestion({
    required this.suggestedDayPrice,
    required this.suggestedHourPrice,
    required this.minDayPrice,
    required this.maxDayPrice,
    required this.confidence,
    required this.factors,
  });
}

class SmartPricingService {
  final _svc = SupabaseService();
  SupabaseClient get _db => _svc.client;

  // ── Base prices by vehicle type (₹/day) ─────────────────────
  static const Map<String, double> _basePrice = {
    'Tractor': 1400,
    'Harvester': 3500,
    'Plough': 600,
    'Cultivator': 700,
    'Sprayer': 800,
    'Seeder': 900,
    'Thresher': 1200,
    'Rotavator': 1100,
    'Power Tiller': 850,
    'Mini Tractor': 1000,
  };

  // ── Location demand multipliers (by state) ───────────────────
  static const Map<String, double> _locationMultiplier = {
    'Punjab': 1.25,
    'Haryana': 1.20,
    'Uttar Pradesh': 1.15,
    'Maharashtra': 1.18,
    'Karnataka': 1.12,
    'Gujarat': 1.10,
    'Madhya Pradesh': 1.08,
    'Andhra Pradesh': 1.10,
    'Telangana': 1.10,
    'Rajasthan': 1.05,
    'Tamil Nadu': 1.08,
    'Bihar': 0.95,
    'Odisha': 0.92,
    'Jharkhand': 0.90,
    'Chhattisgarh': 0.90,
  };

  // ── Monthly season multipliers (Indian agricultural calendar) ─
  static const Map<int, double> _seasonMultiplier = {
    1: 0.90, // Jan – post-harvest slack
    2: 0.90, // Feb
    3: 1.05, // Mar – Rabi harvest starts
    4: 1.20, // Apr – peak Rabi harvest
    5: 1.15, // May – land prep for Kharif
    6: 1.25, // Jun – Kharif sowing (peak)
    7: 1.20, // Jul – Kharif active
    8: 1.10, // Aug
    9: 1.05, // Sep
    10: 1.20, // Oct – Kharif harvest
    11: 1.15, // Nov – Rabi sowing
    12: 0.95, // Dec – low season
  };

  /// Main entry point.  Fetches live platform data and returns a [PriceSuggestion].
  Future<PriceSuggestion> getSuggestion({
    required String vehicleType,
    String? state,
    int? year,
    List<String> features = const [],
    int existingBookings = 0,
    double existingRating = 0,
  }) async {
    final factors = <String>[];

    // 1. Base price from vehicle type
    final base = _basePrice[vehicleType] ?? 1000;
    factors.add('Base rate for $vehicleType: ₹${base.toStringAsFixed(0)}/day');

    // 2. Market data from similar vehicles on the platform
    final marketData = await _fetchMarketData(vehicleType, state);
    double marketMultiplier = 1.0;
    if (marketData['count'] > 0) {
      final avgMarket = marketData['avg'] as double;
      // Nudge base toward market average
      marketMultiplier = (avgMarket / base).clamp(0.7, 1.5);
      factors.add(
          'Market avg from ${marketData['count']} similar vehicles: ₹${avgMarket.toStringAsFixed(0)}/day');
    }

    // 3. Demand based on booking history on platform for this type/location
    final demandMultiplier = await _fetchDemandMultiplier(vehicleType, state);
    if (demandMultiplier > 1.05) {
      factors.add('High demand in this area: +${((demandMultiplier - 1) * 100).toStringAsFixed(0)}%');
    } else if (demandMultiplier < 0.95) {
      factors.add('Lower demand in this area: ${((demandMultiplier - 1) * 100).toStringAsFixed(0)}%');
    }

    // 4. Season multiplier
    final month = DateTime.now().month;
    final season = _seasonMultiplier[month] ?? 1.0;
    final seasonName = _seasonName(month);
    if (season > 1.05) {
      factors.add('$seasonName is peak season: +${((season - 1) * 100).toStringAsFixed(0)}%');
    } else if (season < 0.95) {
      factors.add('$seasonName is off-season: ${((season - 1) * 100).toStringAsFixed(0)}%');
    }

    // 5. Location / state multiplier
    final locMul = state != null ? (_locationMultiplier[state] ?? 1.0) : 1.0;
    if (state != null && locMul != 1.0) {
      if (locMul > 1.0) {
        factors.add('High-demand state ($state): +${((locMul - 1) * 100).toStringAsFixed(0)}%');
      } else {
        factors.add('Moderate-demand state ($state): ${((locMul - 1) * 100).toStringAsFixed(0)}%');
      }
    }

    // 6. Vehicle condition (age-based)
    double conditionMultiplier = 1.0;
    if (year != null) {
      final age = DateTime.now().year - year;
      if (age <= 2) {
        conditionMultiplier = 1.15;
        factors.add('New vehicle (≤2 years): +15%');
      } else if (age <= 5) {
        conditionMultiplier = 1.05;
        factors.add('Good condition (3–5 years): +5%');
      } else if (age <= 10) {
        conditionMultiplier = 0.95;
        factors.add('Moderate age (6–10 years): -5%');
      } else {
        conditionMultiplier = 0.85;
        factors.add('Older vehicle (>10 years): -15%');
      }
    }

    // 7. Features premium
    double featureBonus = 0.0;
    if (features.contains('GPS Enabled')) featureBonus += 0.05;
    if (features.contains('Driver Available')) featureBonus += 0.10;
    if (features.contains('Fuel Included')) featureBonus += 0.08;
    if (features.contains('Insurance Covered')) featureBonus += 0.06;
    if (features.contains('AC Cabin')) featureBonus += 0.07;
    if (features.contains('Night Operation')) featureBonus += 0.05;
    if (featureBonus > 0) {
      factors.add('Premium features: +${(featureBonus * 100).toStringAsFixed(0)}%');
    }

    // 8. Rental history boost (reputation)
    double historyMultiplier = 1.0;
    if (existingBookings >= 20) {
      historyMultiplier = 1.10;
      factors.add('Experienced owner ($existingBookings bookings): +10%');
    } else if (existingBookings >= 10) {
      historyMultiplier = 1.05;
      factors.add('Good rental history ($existingBookings bookings): +5%');
    }

    // 9. Rating premium
    double ratingMultiplier = 1.0;
    if (existingRating >= 4.5) {
      ratingMultiplier = 1.08;
      factors.add('Excellent ratings (${existingRating.toStringAsFixed(1)}★): +8%');
    } else if (existingRating >= 4.0) {
      ratingMultiplier = 1.04;
      factors.add('Good ratings (${existingRating.toStringAsFixed(1)}★): +4%');
    }

    // ── Final calculation ─────────────────────────────────────
    final suggested = base *
        marketMultiplier *
        demandMultiplier *
        season *
        locMul *
        conditionMultiplier *
        (1 + featureBonus) *
        historyMultiplier *
        ratingMultiplier;

    final rounded = _roundToNearest50(suggested);
    final hourPrice = _roundToNearest10(rounded / 10);

    final confidence = _confidence(marketData['count'] as int, existingBookings);

    return PriceSuggestion(
      suggestedDayPrice: rounded,
      suggestedHourPrice: hourPrice,
      minDayPrice: _roundToNearest50(rounded * 0.85),
      maxDayPrice: _roundToNearest50(rounded * 1.15),
      confidence: confidence,
      factors: factors,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchMarketData(
      String vehicleType, String? state) async {
    try {
      var q = _db
          .from(AppConstants.vehiclesTable)
          .select('price_per_day')
          .eq('vehicle_type', vehicleType)
          .eq('is_approved', true)
          .eq('is_available', true)
          .gt('price_per_day', 0);

      if (state != null && state.isNotEmpty) {
        q = q.eq('state', state);
      }

      final rows = await q;
      final list = rows as List;
      if (list.isEmpty) return {'count': 0, 'avg': 0.0};

      final prices =
          list.map<double>((r) => (r['price_per_day'] ?? 0).toDouble()).toList();
      final avg = prices.reduce((a, b) => a + b) / prices.length;
      return {'count': list.length, 'avg': avg};
    } catch (_) {
      return {'count': 0, 'avg': 0.0};
    }
  }

  Future<double> _fetchDemandMultiplier(
      String vehicleType, String? state) async {
    try {
      // Count completed bookings for this vehicle type in last 90 days
      final since =
          DateTime.now().subtract(const Duration(days: 90)).toIso8601String();

      var q = _db
          .from(AppConstants.bookingsTable)
          .select('id, vehicles!inner(vehicle_type, state)')
          .eq('status', 'completed')
          .gte('created_at', since);

      final rows = await q;
      final list = rows as List;

      if (list.isEmpty) return 1.0;

      // Count for this type+state vs all
      int typeCount = 0;
      for (final r in list) {
        final vt = r['vehicles']?['vehicle_type'];
        final vs = r['vehicles']?['state'];
        if (vt == vehicleType) {
          if (state == null || vs == state) typeCount++;
        }
      }

      // Demand score: if this type has > 10% of all bookings = high demand
      final ratio = typeCount / list.length;
      if (ratio >= 0.15) return 1.15;
      if (ratio >= 0.10) return 1.08;
      if (ratio >= 0.05) return 1.02;
      if (ratio <= 0.01) return 0.92;
      return 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  String _seasonName(int month) {
    switch (month) {
      case 3:
      case 4:
      case 5:
        return 'Rabi harvest / Kharif prep';
      case 6:
      case 7:
      case 8:
        return 'Kharif sowing season';
      case 10:
      case 11:
        return 'Kharif harvest / Rabi sowing';
      default:
        return 'Off-season';
    }
  }

  String _confidence(int marketCount, int bookings) {
    if (marketCount >= 5 || bookings >= 5) return 'High';
    if (marketCount >= 2 || bookings >= 2) return 'Medium';
    return 'Low';
  }

  double _roundToNearest50(double v) => (v / 50).round() * 50.0;
  double _roundToNearest10(double v) => (v / 10).round() * 10.0;

  /// Convenience: fetch suggestion from an existing vehicle's data.
  Future<PriceSuggestion> getSuggestionFromVehicle(VehicleModel v) =>
      getSuggestion(
        vehicleType: v.vehicleType,
        state: v.state,
        year: v.year,
        features: v.features,
        existingBookings: v.totalBookings,
        existingRating: v.averageRating,
      );
}
