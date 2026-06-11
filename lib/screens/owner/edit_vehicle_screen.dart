// lib/screens/owner/edit_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class EditVehicleScreen extends StatefulWidget {
  final String vehicleId;
  const EditVehicleScreen({super.key, required this.vehicleId});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _capacityController = TextEditingController();
  final _hpController = TextEditingController();

  String? _selectedType;
  String? _selectedState;
  String? _selectedFuelType;
  List<String> _selectedFeatures = [];
  bool _isAvailable = true;
  bool _isLoading = true;
  bool _isSubmitting = false;


  final List<String> _availableFeatures = [
    'GPS Enabled',
    'Driver Available',
    'Fuel Included',
    'Insurance Covered',
    'Night Operation',
    'AC Cabin',
    'Advanced Technology',
    'Well Maintained',
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final v = await _vehicleService.getVehicleById(widget.vehicleId);
      if (v != null && mounted) {
        _titleController.text = v.title;
        _descController.text = v.description ?? '';
        _brandController.text = v.brand ?? '';
        _modelController.text = v.model ?? '';
        _yearController.text = v.year?.toString() ?? '';
        _pricePerHourController.text = v.pricePerHour.toStringAsFixed(0);
        _pricePerDayController.text = v.pricePerDay.toStringAsFixed(0);
        _locationController.text = v.location ?? '';
        _cityController.text = v.city ?? '';
        _capacityController.text = v.capacity ?? '';
        _hpController.text = v.horsepower?.toString() ?? '';
        _selectedType = v.vehicleType;
        _selectedState = v.state;
        _selectedFuelType = v.fuelType;
        _selectedFeatures = List.from(v.features);
        _isAvailable = v.isAvailable;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _pricePerHourController.dispose();
    _pricePerDayController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _capacityController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _vehicleService.updateVehicle(widget.vehicleId, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'vehicle_type': _selectedType,
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()),
        'price_per_hour':
            double.tryParse(_pricePerHourController.text.trim()) ?? 0,
        'price_per_day':
            double.tryParse(_pricePerDayController.text.trim()) ?? 0,
        'location': _locationController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'fuel_type': _selectedFuelType,
        'horsepower': int.tryParse(_hpController.text.trim()),
        'capacity': _capacityController.text.trim(),
        'features': _selectedFeatures,
        'is_available': _isAvailable,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        context.go('/owner/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability Toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAvailable
                      ? AppTheme.lightGreen
                      : AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAvailable
                        ? AppTheme.primaryGreenLight
                        : AppTheme.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isAvailable
                          ? '✅ Vehicle is Available'
                          : '🚫 Not Available',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isAvailable
                            ? AppTheme.primaryGreenDark
                            : AppTheme.errorRed,
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: (v) => setState(() => _isAvailable = v),
                      activeThumbColor: AppTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Basic Information'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _titleController,
                label: 'Vehicle Title *',
                prefixIcon: Icons.agriculture,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Title too short'
                    : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type *',
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppTheme.greyText),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: AppConstants.vehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) => v == null ? 'Please select type' : null,
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _descController,
                label: 'Description',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              _sectionTitle('Pricing (₹)'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _pricePerHourController,
                      label: 'Price / Hour *',
                      prefixIcon: Icons.access_time,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _pricePerDayController,
                      label: 'Price / Day *',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _sectionTitle('Location'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _cityController,
                label: 'City *',
                prefixIcon: Icons.location_city,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'City required' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: InputDecoration(
                  labelText: 'State',
                  prefixIcon:
                      const Icon(Icons.map_outlined, color: AppTheme.greyText),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: AppConstants.indianStates
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedState = v),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Features'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFeatures.map((f) {
                  final selected = _selectedFeatures.contains(f);
                  return FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _selectedFeatures.add(f);
                      } else {
                        _selectedFeatures.remove(f);
                      }
                    }),
                    selectedColor: AppTheme.primaryGreen,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.greyText),
                    backgroundColor: AppTheme.lightGreen,
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              LoadingButton(
                label: 'Update Vehicle',
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.save_outlined,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      );
}
