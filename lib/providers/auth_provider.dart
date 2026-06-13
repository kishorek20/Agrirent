// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _svc = SupabaseService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String?    _error;

  AuthStatus get status        => _status;
  UserModel? get currentUser   => _user;
  String?    get errorMessage  => _error;
  bool       get isAuthenticated => _status == AuthStatus.authenticated;
  bool       get isLoading       => _status == AuthStatus.loading;
  String?    get userRole        => _user?.role;
  bool       get isFarmer        => _user?.role == 'farmer';
  bool       get isOwner         => _user?.role == 'owner';
  bool       get isAdmin         => _user?.role == 'admin';

  // Called from SplashScreen on every app start.
  Future<void> loadCurrentUser() async {
    _setLoading();
    try {
      if (_svc.isAuthenticated) {
        _user = await _svc.getCurrentUserProfile();
        _status = _user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email, required String password,
    required String fullName, required String phone,
    required String role, String? city, String? state,
  }) async {
    _setLoading();
    try {
      final res = await _svc.signUp(email: email, password: password);

      // signUp on a rate-limited or duplicate call still returns an
      // identityData-less user — treat null user as hard failure.
      if (res.user == null) { _setError('Registration failed'); return false; }

      // Try to insert the profile row. If it already exists (duplicate signup
      // attempt) we catch and ignore the unique-violation — the account was
      // already created on a previous attempt.
      try {
        await _svc.createUserProfile(
          authId: res.user!.id, fullName: fullName, email: email,
          phone: phone, role: role, city: city, state: state,
        );
      } catch (profileErr) {
        final msg = profileErr.toString();
        // Ignore unique-constraint violations (profile row already exists).
        if (!msg.contains('duplicate') && !msg.contains('unique') && !msg.contains('23505')) {
          rethrow;
        }
      }

      // Always sign out so the user MUST sign in manually — this avoids
      // landing on a home screen with a half-initialised session.
      await _svc.signOut();
      _user   = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true; // tells the UI to navigate to /login
    } catch (e) {
      _setError(_friendly(e.toString()));
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading();
    try {
      await _svc.signIn(email: email, password: password);
      _user = await _svc.getCurrentUserProfile();
      if (_user == null) { _setError('Profile not found'); return false; }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_friendly(e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await _svc.signOut();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;
    try {
      await _svc.updateUserProfile(_user!.id, data);
      _user = await _svc.getCurrentUserProfile();
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading() { _status = AuthStatus.loading; _error = null; notifyListeners(); }
  void _setError(String e) { _status = AuthStatus.error; _error = e; notifyListeners(); }

  String _friendly(String e) {
    if (e.contains('invalid_credentials')) return 'Invalid email or password.';
    if (e.contains('email_not_confirmed') || e.contains('Email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (e.contains('over_email_send_rate_limit') || e.contains('rate_limit') || e.contains('429')) {
      return 'Too many requests. Please wait a minute and try again.';
    }
    if (e.contains('already registered') || e.contains('already exists') || e.contains('23505')) {
      return 'An account with this email already exists.';
    }
    if (e.contains('network') || e.contains('SocketException')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}
