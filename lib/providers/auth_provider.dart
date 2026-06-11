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
      if (res.user == null) { _setError('Registration failed'); return false; }
      await _svc.createUserProfile(
        authId: res.user!.id, fullName: fullName, email: email,
        phone: phone, role: role, city: city, state: state,
      );
      _user   = await _svc.getCurrentUserProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
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
    if (e.contains('already registered') || e.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (e.contains('network')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}
