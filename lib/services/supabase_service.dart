// lib/services/supabase_service.dart
// Singleton wrapper around the Supabase client and Auth API.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentAuthUser => client.auth.currentUser;
  bool get isAuthenticated => currentAuthUser != null;

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  Future<AuthResponse> signUp(
          {required String email, required String password}) =>
      client.auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn(
          {required String email, required String password}) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => client.auth.signOut();

  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);

  /// Insert a new profile row linked to the just-created auth user.
  Future<void> createUserProfile({
    required String authId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String? city,
    String? state,
  }) async {
    await client.from(AppConstants.usersTable).insert({
      'auth_id': authId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'city': city,
      'state': state,
      'is_verified': true,
      'is_active': true,
    });
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentAuthUser?.id;
    if (uid == null) return null;
    final row = await client
        .from(AppConstants.usersTable)
        .select()
        .eq('auth_id', uid)
        .maybeSingle();
    return row == null ? null : UserModel.fromJson(row);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) =>
      client.from(AppConstants.usersTable).update(data).eq('id', userId);

  Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;
}
