// lib/screens/admin/manage_users_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  late TabController _tabController;

  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _activeTab = 'All';

  final _tabs = ['All', 'Farmers', 'Owners'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      _activeTab = _tabs[_tabController.index];
      _applyFilter();
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.client
          .from(AppConstants.usersTable)
          .select()
          .order('created_at', ascending: false);
      _users = (response as List).map((u) => UserModel.fromJson(u)).toList();
      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final matchesRole = _activeTab == 'All' ||
            (_activeTab == 'Farmers' && u.role == 'farmer') ||
            (_activeTab == 'Owners' && u.role == 'owner');
        final matchesQuery = query.isEmpty ||
            u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.phone?.contains(query) ?? false);
        return matchesRole && matchesQuery;
      }).toList();
    });
  }

  Future<void> _toggleUserActive(UserModel user) async {
    try {
      await _supabase.client
          .from(AppConstants.usersTable)
          .update({'is_active': !user.isActive}).eq('id', user.id);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${user.fullName} ${!user.isActive ? 'activated' : 'deactivated'}'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentAmber,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Count banner
          Container(
            color: AppTheme.greyLight,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} user${_filtered.length != 1 ? 's' : ''} found',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people,
                                size: 80,
                                color: AppTheme.primaryGreenLight),
                            const SizedBox(height: 16),
                            Text('No Users Found',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: AppTheme.primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) =>
                              _UserCard(
                            user: _filtered[index],
                            onToggle: () =>
                                _toggleUserActive(_filtered[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggle;

  const _UserCard({required this.user, required this.onToggle});

  Color get _roleColor {
    switch (user.role) {
      case 'farmer': return AppTheme.primaryGreen;
      case 'owner': return AppTheme.skyBlue;
      case 'admin': return const Color(0xFF7B1FA2);
      default: return AppTheme.greyText;
    }
  }

  IconData get _roleIcon {
    switch (user.role) {
      case 'farmer': return Icons.grass;
      case 'owner': return Icons.agriculture;
      case 'admin': return Icons.admin_panel_settings;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: _roleColor.withValues(alpha: 0.15),
              child: Text(
                user.fullName[0].toUpperCase(),
                style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _roleColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_roleIcon, size: 12, color: _roleColor),
                            const SizedBox(width: 4),
                            Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                  color: _roleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppTheme.greyText, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (user.phone != null)
                    Text(user.phone!,
                        style: const TextStyle(
                            color: AppTheme.greyText, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (user.city != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: AppTheme.greyText),
                            Text(user.city!,
                                style: const TextStyle(
                                    color: AppTheme.greyText,
                                    fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Active toggle
            Column(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: user.isActive,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  user.isActive ? 'Active' : 'Blocked',
                  style: TextStyle(
                    color: user.isActive
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
