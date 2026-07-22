// lib/screens/farmer/farmer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/search_ranking_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/search_suggestion_overlay.dart';
import '../../widgets/vehicle_card.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final _vehicleService = VehicleService();
  final _searchController = TextEditingController();

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _filteredVehicles = [];
  List<SuggestionItem> _suggestions = [];

  bool _isLoading = true;
  bool _showSuggestions = false;
  String? _selectedType;
  String _selectedSort = 'recommended';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final rawVehicles = await _vehicleService.getApprovedVehicles();
      _vehicles = rawVehicles;
      _applyFiltersAndRanking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicles: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFiltersAndRanking() {
    final query = _searchController.text.trim();
    final user = context.read<AuthProvider>().currentUser;

    var list = _vehicles;
    if (_selectedType != null) {
      list = list.where((v) => v.vehicleType == _selectedType).toList();
    }

    _filteredVehicles = SearchRankingService.rankVehicles(
      list,
      query: query,
      userCity: user?.city,
      userState: user?.state,
      sortBy: _selectedSort,
    );
  }

  void _onSearchChanged(String query) {
    final suggestions =
        SearchRankingService.getSearchSuggestions(_vehicles, query);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
      _applyFiltersAndRanking();
    });
  }

  void _selectSuggestion(SuggestionItem item) {
    _searchController.text = item.text;
    setState(() {
      _showSuggestions = false;
      if (item.category == 'Category') {
        _selectedType = item.text;
      }
      _applyFiltersAndRanking();
    });
  }

  void _filterByType(String? type) {
    setState(() {
      _selectedType = type;
      _applyFiltersAndRanking();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = user?.fullName.split(' ').first ?? 'Farmer';

    return Scaffold(
      backgroundColor: AppTheme.greyLight,
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreenDark,
                        AppTheme.primaryGreen
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Namaste, $firstName! 🌾',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Find the right vehicle for your farm',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  firstName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Search bar inside app bar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search vehicles, locations...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppTheme.primaryGreen),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                    onTap: () {
                      if (_suggestions.isNotEmpty) {
                        setState(() => _showSuggestions = true);
                      }
                    },
                  ),
                ),
              ),
            ),

            // ── Suggestions Overlay ───────────────────────────
            if (_showSuggestions)
              SliverToBoxAdapter(
                child: SearchSuggestionOverlay(
                  suggestions: _suggestions,
                  onSelected: _selectSuggestion,
                ),
              ),

            // ── Filter Chips ─────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _filterChip('All', null),
                    ...AppConstants.vehicleTypes.map((t) => _filterChip(t, t)),
                  ],
                ),
              ),
            ),

            // ── Stats Banner ─────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentAmber, AppTheme.accentOrange],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Book Now & Save!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_vehicles.length} vehicles available near you',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/farmer/search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.accentOrange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Browse All',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section Header with Ranking Controls ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedType != null
                              ? '$_selectedType Vehicles'
                              : 'Available Vehicles',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${_filteredVehicles.length} found',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.sort,
                            size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        const Text('Sort:',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _sortChip('Recommended ✨', 'recommended'),
                                _sortChip('Top Rated ⭐', 'rating'),
                                _sortChip('Most Popular 🔥', 'bookings'),
                                _sortChip('Price: Low-High', 'price_low'),
                                _sortChip('Price: High-Low', 'price_high'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Vehicle Grid ──────────────────────────────────
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen),
                  ),
                ),
              )
            else if (_filteredVehicles.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(Icons.agriculture,
                            size: 80, color: AppTheme.primaryGreenLight),
                        const SizedBox(height: 16),
                        Text(
                          'No vehicles found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different filter or location',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        VehicleCard(vehicle: _filteredVehicles[index]),
                    childCount: _filteredVehicles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? type) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _filterByType(type),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryGreen,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.greyText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final isSelected = _selectedSort == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedSort = value;
              _applyFiltersAndRanking();
            });
          }
        },
        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
        ),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.greyText,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
