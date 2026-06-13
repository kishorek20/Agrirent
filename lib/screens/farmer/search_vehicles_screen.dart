// lib/screens/farmer/search_vehicles_screen.dart
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/vehicle_card.dart';

class SearchVehiclesScreen extends StatefulWidget {
  const SearchVehiclesScreen({super.key});

  @override
  State<SearchVehiclesScreen> createState() => _SearchVehiclesScreenState();
}

class _SearchVehiclesScreenState extends State<SearchVehiclesScreen> {
  final _vehicleService = VehicleService();
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();

  List<VehicleModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  String? _selectedType;
  String? _selectedState;
  double _maxPrice = 10000;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      _results = await _vehicleService.getApprovedVehicles(
        vehicleType: _selectedType,
        city: _cityController.text.trim(),
        state: _selectedState,
        maxPrice: _maxPrice < 10000 ? _maxPrice : null,
        searchQuery: _searchController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Vehicles'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────
          Container(
            color: AppTheme.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search tractors, harvesters...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentAmber,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          // ── Filters ───────────────────────────────────────
          if (_showFilters)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // City
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Vehicle type
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Types')),
                      ...AppConstants.vehicleTypes.map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                  const SizedBox(height: 12),

                  // Price slider
                  Text(
                    'Max Price: ₹${_maxPrice.toStringAsFixed(0)}/day',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _maxPrice,
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    label: '₹${_maxPrice.toStringAsFixed(0)}',
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setState(() => _maxPrice = v),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = null;
                              _selectedState = null;
                              _maxPrice = 10000;
                              _cityController.clear();
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _search,
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Results ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen))
                : !_hasSearched
                    ? _searchPrompt()
                    : _results.isEmpty
                        ? _noResults()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Text(
                                  '${_results.length} vehicle${_results.length != 1 ? 's' : ''} found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.primaryGreen),
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 250,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: _results.length,
                                  itemBuilder: (context, index) =>
                                      VehicleCard(vehicle: _results[index]),
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _searchPrompt() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 80, color: AppTheme.primaryGreenLight),
            const SizedBox(height: 16),
            Text('Search for Vehicles', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter a keyword or apply filters to find vehicles',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _noResults() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No Vehicles Found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or adjust filters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _cityController.clear();
                setState(() {
                  _selectedType = null;
                  _selectedState = null;
                  _maxPrice = 10000;
                  _hasSearched = false;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
}
