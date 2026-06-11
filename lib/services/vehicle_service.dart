// lib/services/vehicle_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class VehicleService {
  final _svc = SupabaseService();
  SupabaseClient get _db => _svc.client;

  /// Fetch approved+available vehicles with optional filters.
  Future<List<VehicleModel>> getApprovedVehicles({
    String? vehicleType,
    String? city,
    String? state,
    double? maxPrice,
    String? searchQuery,
  }) async {
    var q = _db
        .from(AppConstants.vehiclesTable)
        .select('*, users(full_name, phone)')
        .eq('is_approved', true)
        .eq('is_available', true);

    if (vehicleType != null && vehicleType.isNotEmpty) {
      q = q.eq('vehicle_type', vehicleType);
    }
    if (city != null && city.isNotEmpty) q = q.ilike('city', '%\$city%');
    if (state != null && state.isNotEmpty) q = q.eq('state', state);
    if (maxPrice != null) q = q.lte('price_per_day', maxPrice);

    final response = await q.order('created_at', ascending: false);
    var list = (response as List).map((v) => VehicleModel.fromJson(v)).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sq = searchQuery.toLowerCase();
      list = list
          .where((v) =>
              v.title.toLowerCase().contains(sq) ||
              (v.description?.toLowerCase().contains(sq) ?? false) ||
              v.vehicleType.toLowerCase().contains(sq) ||
              (v.city?.toLowerCase().contains(sq) ?? false))
          .toList();
    }
    return list;
  }

  Future<VehicleModel?> getVehicleById(String id) async {
    final row = await _db
        .from(AppConstants.vehiclesTable)
        .select('*, users(full_name, phone)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : VehicleModel.fromJson(row);
  }

  Future<List<VehicleModel>> getOwnerVehicles(String ownerId) async {
    final rows = await _db
        .from(AppConstants.vehiclesTable)
        .select('*, users(full_name, phone)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (rows as List).map((v) => VehicleModel.fromJson(v)).toList();
  }

  Future<List<VehicleModel>> getAllVehicles() async {
    final rows = await _db
        .from(AppConstants.vehiclesTable)
        .select('*, users(full_name, phone)')
        .order('created_at', ascending: false);
    return (rows as List).map((v) => VehicleModel.fromJson(v)).toList();
  }

  Future<String> addVehicle(Map<String, dynamic> data) async {
    final row = await _db
        .from(AppConstants.vehiclesTable)
        .insert(data)
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> data) =>
      _db.from(AppConstants.vehiclesTable).update(data).eq('id', id);

  Future<void> deleteVehicle(String id) =>
      _db.from(AppConstants.vehiclesTable).delete().eq('id', id);

  Future<void> toggleAvailability(String id, bool available) => _db
      .from(AppConstants.vehiclesTable)
      .update({'is_available': available}).eq('id', id);

  Future<void> approveVehicle(String vehicleId, bool approved) async {
    await _db.from(AppConstants.vehiclesTable).update({
      'is_approved': approved,
    }).eq('id', vehicleId);
  }
}
