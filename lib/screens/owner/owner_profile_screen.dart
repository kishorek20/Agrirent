// lib/screens/owner/owner_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController    = TextEditingController();
  bool _isEditing = false;
  bool _isSaving  = false;

  // Dynamic stats
  int    _totalVehicles = 0;
  int    _totalBookings = 0;
  double _avgRating     = 0.0;
  bool   _statsLoading  = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  void _loadProfile() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text    = user.fullName;
      _phoneController.text   = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _cityController.text    = user.city ?? '';
    }
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) { setState(() => _statsLoading = false); return; }
    try {
      final client = Supabase.instance.client;

      // Count owner's vehicles
      final vehiclesRes = await client
          .from(AppConstants.vehiclesTable)
          .select('id, average_rating')
          .eq('owner_id', user.id);

      // Count bookings where this user is the owner
      final bookingsRes = await client
          .from(AppConstants.bookingsTable)
          .select('id')
          .eq('owner_id', user.id);

      final vehicles = vehiclesRes as List;
      final bookings = bookingsRes as List;

      // Compute average rating across all owner's vehicles
      double avgRating = 0.0;
      if (vehicles.isNotEmpty) {
        final total = vehicles
            .map((v) => (v['average_rating'] as num?)?.toDouble() ?? 0.0)
            .fold(0.0, (a, b) => a + b);
        avgRating = total / vehicles.length;
      }

      if (mounted) {
        setState(() {
          _totalVehicles = vehicles.length;
          _totalBookings = bookings.length;
          _avgRating     = avgRating;
          _statsLoading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final auth    = context.read<AuthProvider>();
    final success = await auth.updateProfile({
      'full_name': _nameController.text.trim(),
      'phone':     _phoneController.text.trim(),
      'address':   _addressController.text.trim(),
      'city':      _cityController.text.trim(),
    });
    if (mounted) {
      setState(() { _isSaving = false; if (success) _isEditing = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Profile updated!' : 'Update failed'),
        backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
      ));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  String _ratingLabel() {
    if (_totalVehicles == 0) return 'N/A';
    return '${_avgRating.toStringAsFixed(1)}⭐';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.fullName ?? 'O')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🚜 Vehicle Owner',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  if (user?.isVerified == true) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('Verified Owner',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Dynamic Stats Row ────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                ],
              ),
              child: _statsLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('Vehicles',  '$_totalVehicles'),
                        _divider(),
                        _statItem('Bookings',  '$_totalBookings'),
                        _divider(),
                        _statItem('Rating',    _ratingLabel()),
                      ],
                    ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile Information', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _nameController, label: 'Full Name',
                    prefixIcon: Icons.person_outline, readOnly: !_isEditing,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _phoneController, label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined, readOnly: !_isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _cityController, label: 'City',
                    prefixIcon: Icons.location_city_outlined, readOnly: !_isEditing,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _addressController, label: 'Address',
                    prefixIcon: Icons.home_outlined, readOnly: !_isEditing, maxLines: 2,
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 20),
                    LoadingButton(
                      label: 'Save Changes', isLoading: _isSaving, onPressed: _saveProfile,
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  _menuItem(Icons.account_balance, 'Bank Account', () {}),
                  _menuItem(Icons.description, 'Documents', () {}),
                  _menuItem(Icons.help_outline, 'Help & Support', () {}),
                  _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _menuItem(Icons.logout, 'Logout', _logout, color: AppTheme.errorRed),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) => Column(
    children: [
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
    ],
  );

  Widget _divider() => Container(height: 36, width: 1, color: Colors.grey.shade200);

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppTheme.primaryGreen, size: 20),
      ),
      title: Text(label,
          style: TextStyle(color: color ?? AppTheme.black, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
