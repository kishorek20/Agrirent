// lib/screens/farmer/farmer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController    = TextEditingController();
  bool _isEditing = false;
  bool _isSaving  = false;

  // Dynamic stats
  int  _totalBookings = 0;
  bool _statsLoading  = true;

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
      final bookingsRes = await client
          .from(AppConstants.bookingsTable)
          .select('id')
          .eq('farmer_id', user.id);
      if (mounted) {
        setState(() {
          _totalBookings = (bookingsRes as List).length;
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
      setState(() { _isSaving = false; _isEditing = !success; });
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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

  /// Shows year if >1 year old, months if <1 year, days if <1 month.
  String _memberSince(DateTime createdAt) {
    final now  = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays >= 365) return '${createdAt.year}';
    if (diff.inDays >= 30)  return '${(diff.inDays / 30).floor()} mo';
    return '${diff.inDays} days';
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          (user?.fullName ?? 'F')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentAmber, shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🌾 Farmer', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
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
                        _statItem('Member Since',
                            user != null ? _memberSince(user.createdAt) : '—'),
                        _divider(),
                        _statItem('Total Bookings', '$_totalBookings'),
                        _divider(),
                        _statItem('State', user?.state ?? 'N/A'),
                      ],
                    ),
            ),

            // ── Edit Form ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personal Information', style: Theme.of(context).textTheme.titleLarge),
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
                  _menuItem(Icons.help_outline, 'Help & Support', () {}),
                  _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                  _menuItem(Icons.info_outline, 'About AgriRent', () {}),
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
