// lib/screens/owner/add_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();

  // Controllers
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
  bool _isSubmitting = false;

  final List<String> _selectedFeatures = [];
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

  final List<String> _fuelTypes = ['Diesel', 'Petrol', 'Electric', 'CNG'];

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
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = context.read<AuthProvider>().currentUser!;
      await _vehicleService.addVehicle({
        'owner_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'vehicle_type': _selectedType,
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()),
        'price_per_hour': double.tryParse(_pricePerHourController.text.trim()) ?? 0,
        'price_per_day': double.tryParse(_pricePerDayController.text.trim()) ?? 0,
        'location': _locationController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'fuel_type': _selectedFuelType,
        'horsepower': int.tryParse(_hpController.text.trim()),
        'capacity': _capacityController.text.trim(),
        'features': _selectedFeatures,
        'is_available': true,
        'is_approved': false,
        'image_urls': <String>[],
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.successGreen, size: 72),
                const SizedBox(height: 16),
                Text('Vehicle Submitted!',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Your vehicle has been submitted for admin approval. It will be listed once approved.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/owner/home');
                    },
                    child: const Text('Go to My Vehicles'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorRed),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Basic Info ──────────────────────────────────
              _sectionTitle('Basic Information'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _titleController,
                label: 'Vehicle Title *',
                hint: 'e.g. Mahindra 575 DI Tractor',
                prefixIcon: Icons.agriculture,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 5) return 'Title too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Vehicle Type
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type *',
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppTheme.greyText),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: AppConstants.vehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                hint: const Text('Select vehicle type'),
                validator: (v) => v == null ? 'Please select type' : null,
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe your vehicle, condition, usage...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // ── Vehicle Details ─────────────────────────────
              _sectionTitle('Vehicle Details'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _brandController,
                      label: 'Brand',
                      hint: 'e.g. Mahindra',
                      prefixIcon: Icons.branding_watermark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      label: 'Model',
                      hint: 'e.g. 575 DI',
                      prefixIcon: Icons.model_training,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _yearController,
                      label: 'Year',
                      hint: '2020',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _hpController,
                      label: 'Horsepower',
                      hint: '50',
                      prefixIcon: Icons.speed,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFuelType,
                      decoration: InputDecoration(
                        labelText: 'Fuel Type',
                        prefixIcon: const Icon(Icons.local_gas_station,
                            color: AppTheme.greyText),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: _fuelTypes
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedFuelType = v),
                      hint: const Text('Fuel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _capacityController,
                      label: 'Capacity',
                      hint: 'e.g. 5 acres/hr',
                      prefixIcon: Icons.agriculture,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Pricing ─────────────────────────────────────
              _sectionTitle('Pricing (₹)'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _pricePerHourController,
                      label: 'Price / Hour *',
                      hint: '200',
                      prefixIcon: Icons.access_time,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _pricePerDayController,
                      label: 'Price / Day *',
                      hint: '1500',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Location ─────────────────────────────────────
              _sectionTitle('Location'),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _cityController,
                label: 'City *',
                hint: 'e.g. Pune',
                prefixIcon: Icons.location_city,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: InputDecoration(
                  labelText: 'State *',
                  prefixIcon: const Icon(Icons.map_outlined,
                      color: AppTheme.greyText),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: AppConstants.indianStates
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedState = v),
                hint: const Text('Select state'),
                validator: (v) => v == null ? 'State is required' : null,
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _locationController,
                label: 'Full Address',
                hint: 'Village / Town, District',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // ── Features ─────────────────────────────────────
              _sectionTitle('Features & Amenities'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFeatures.map((f) {
                  final selected = _selectedFeatures.contains(f);
                  return FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedFeatures.add(f);
                        } else {
                          _selectedFeatures.remove(f);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryGreen,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.greyText,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    backgroundColor: AppTheme.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // ── Info Box ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreenLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your vehicle listing will be reviewed by admin before going live. This usually takes 24–48 hours.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryGreenDark,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              LoadingButton(
                label: 'Submit Vehicle',
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.send_outlined,
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
