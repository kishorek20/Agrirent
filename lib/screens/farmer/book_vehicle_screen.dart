// lib/screens/farmer/book_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../../services/notification_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/razorpay_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_button.dart';

class BookVehicleScreen extends StatefulWidget {
  final String vehicleId;
  const BookVehicleScreen({super.key, required this.vehicleId});

  @override
  State<BookVehicleScreen> createState() => _BookVehicleScreenState();
}

class _BookVehicleScreenState extends State<BookVehicleScreen> {
  final _vehicleService = VehicleService();
  final _bookingService = BookingService();
  final _paymentService = PaymentService();
  final _notificationService = NotificationService();
  final _notesController = TextEditingController();

  VehicleModel? _vehicle;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String _paymentMethod = 'UPI';
  bool _isLoading = true;
  bool _isBooking = false;
  int _currentStep = 0;

  final _paymentMethods = [
    {'name': 'UPI', 'icon': Icons.account_balance, 'desc': 'Google Pay, PhonePe, Paytm'},
    {'name': 'Cash', 'icon': Icons.money, 'desc': 'Pay on delivery'},
    {'name': 'Card', 'icon': Icons.credit_card, 'desc': 'Debit / Credit Card'},
    {'name': 'Net Banking', 'icon': Icons.language, 'desc': 'Online bank transfer'},
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    _vehicle = await _vehicleService.getVehicleById(widget.vehicleId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date first')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  double get _subtotal => _totalDays * (_vehicle?.pricePerDay ?? 0);
  double get _tax => _subtotal * AppConstants.taxRate;
  double get _total => _subtotal + _tax;

  DateTime get _fullStartDate {
    if (_startDate == null) return DateTime.now();
    return DateTime(_startDate!.year, _startDate!.month, _startDate!.day,
        _startTime.hour, _startTime.minute);
  }

  DateTime get _fullEndDate {
    if (_endDate == null) return DateTime.now();
    return DateTime(_endDate!.year, _endDate!.month, _endDate!.day,
        _endTime.hour, _endTime.minute);
  }

  Future<void> _processBooking({String? transactionId}) async {
    try {
      final user = context.read<AuthProvider>().currentUser!;
      // Create booking
      final bookingId = await _bookingService.createBooking({
        'vehicle_id': widget.vehicleId,
        'farmer_id': user.id,
        'owner_id': _vehicle!.ownerId,
        'start_date': _fullStartDate.toIso8601String(),
        'end_date': _fullEndDate.toIso8601String(),
        'total_days': _totalDays.toDouble(),
        'price_per_day': _vehicle!.pricePerDay,
        'subtotal': _subtotal,
        'tax_amount': _tax,
        'total_amount': _total,
        'status': 'pending',
        'payment_status': _paymentMethod == 'Cash' ? 'unpaid' : 'paid',
        'booking_notes': _notesController.text.trim(),
      });

      // Create payment record
      await _paymentService.createPayment(
        bookingId: bookingId,
        farmerId: user.id,
        ownerId: _vehicle!.ownerId,
        amount: _total,
        paymentMethod: _paymentMethod,
        transactionId: transactionId,
      );

      // If online payment, update booking payment status
      if (_paymentMethod != 'Cash') {
        await _bookingService.updatePaymentStatus(bookingId, 'paid');
      }

      // Notify owner about new booking
      await _notificationService.notifyOwnerNewBooking(
        ownerId: _vehicle!.ownerId,
        farmerName: user.fullName,
        vehicleTitle: _vehicle!.title,
        bookingId: bookingId,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 72),
                const SizedBox(height: 16),
                Text('Booking Confirmed!', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  _paymentMethod == 'Cash'
                      ? 'Your booking is confirmed. Pay ₹${_total.toStringAsFixed(0)} in cash at pickup.'
                      : 'Payment of ₹${_total.toStringAsFixed(0)} successful!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The owner has been notified and will confirm shortly.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/farmer/bookings');
                    },
                    child: const Text('View My Bookings'),
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
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select booking dates')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;

      final isAvailable = await _bookingService.isVehicleAvailable(
        widget.vehicleId, _fullStartDate, _fullEndDate,
      );
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle is not available for selected dates'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        setState(() => _isBooking = false);
        return;
      }

      if (_paymentMethod == 'Cash') {
        await _processBooking();
        if (mounted) setState(() => _isBooking = false);
        return;
      }

      // Online Payment via Razorpay
      final response = await SupabaseService().client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': _total,
          'currency': 'INR',
          'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final data = response.data;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'Failed to create order');
      }

      final orderId = data['order_id'];
      final keyId = data['key'];

      await RazorpayServiceWrapper.openCheckout(
        amount: _total,
        currency: 'INR',
        orderId: orderId,
        keyId: keyId,
        name: AppConstants.appName,
        description: 'Booking: ${_vehicle!.title}',
        prefillName: user.fullName,
        prefillEmail: user.email,
        prefillContact: user.phone ?? '',
        paymentMethod: _paymentMethod,
        onSuccess: (paymentId, orderId, signature) async {
          await _processBooking(transactionId: paymentId);
          if (mounted) setState(() => _isBooking = false);
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Failed: $error'), backgroundColor: AppTheme.errorRed),
            );
            setState(() => _isBooking = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }
    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Vehicle')),
        body: const Center(child: Text('Vehicle not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Vehicle')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && (_startDate == null || _endDate == null)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select start and end dates')),
            );
            return;
          }
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _confirmBooking();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep < 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Continue'),
                    ),
                  )
                else
                  Expanded(
                    child: LoadingButton(
                      label: 'Confirm & Pay',
                      isLoading: _isBooking,
                      onPressed: _confirmBooking,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Date & Time
          Step(
            title: const Text('Select Date & Time'),
            subtitle: _startDate != null && _endDate != null
                ? Text('$_totalDays day${_totalDays > 1 ? 's' : ''}')
                : null,
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildDateTimeStep(),
          ),
          // Step 2: Payment
          Step(
            title: const Text('Payment Method'),
            subtitle: Text(_paymentMethod),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildPaymentStep(),
          ),
          // Step 3: Review
          Step(
            title: const Text('Review & Confirm'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildReviewStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    final fmt = DateFormat('dd MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vehicle summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.agriculture, size: 32, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_vehicle!.title, style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('₹${_vehicle!.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Date pickers
        Text('Select Dates', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dateTile('Start Date', _startDate, Icons.calendar_today, _pickStartDate, fmt)),
            const SizedBox(width: 12),
            Expanded(child: _dateTile('End Date', _endDate, Icons.event, _pickEndDate, fmt)),
          ],
        ),
        const SizedBox(height: 16),
        // Time pickers
        Text('Select Time', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _timeTile('Start Time', _startTime, _pickStartTime)),
            const SizedBox(width: 12),
            Expanded(child: _timeTile('End Time', _endTime, _pickEndTime)),
          ],
        ),
        if (_totalDays > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text('Duration: $_totalDays day${_totalDays > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Notes
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Special requirements (optional)...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_totalDays > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text('₹${_total.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Choose Payment Method', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...(_paymentMethods.map((m) {
          final name = m['name'] as String;
          final isSelected = _paymentMethod == name;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected ? AppTheme.lightGreen : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                      : AppTheme.greyLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m['icon'] as IconData,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.greyText),
              ),
              title: Text(name, style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
              subtitle: Text(m['desc'] as String, style: const TextStyle(fontSize: 12)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                  : const Icon(Icons.radio_button_off, color: Colors.grey),
              onTap: () => setState(() => _paymentMethod = name),
            ),
          );
        })),
      ],
    );
  }

  Widget _buildReviewStep() {
    final fmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _reviewRow('Vehicle', _vehicle!.title),
                _reviewRow('Type', _vehicle!.vehicleType),
                const Divider(height: 20),
                _reviewRow('Start Date', _startDate != null ? fmt.format(_startDate!) : '-'),
                _reviewRow('Start Time', timeFmt.format(DateTime(0, 0, 0, _startTime.hour, _startTime.minute))),
                _reviewRow('End Date', _endDate != null ? fmt.format(_endDate!) : '-'),
                _reviewRow('End Time', timeFmt.format(DateTime(0, 0, 0, _endTime.hour, _endTime.minute))),
                _reviewRow('Duration', '$_totalDays day${_totalDays > 1 ? 's' : ''}'),
                const Divider(height: 20),
                _reviewRow('Rate', '₹${_vehicle!.pricePerDay.toStringAsFixed(0)}/day'),
                _reviewRow('Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
                _reviewRow('GST (5%)', '₹${_tax.toStringAsFixed(0)}'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleLarge),
                    Text('₹${_total.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                _reviewRow('Payment', _paymentMethod),
                if (_notesController.text.trim().isNotEmpty)
                  _reviewRow('Notes', _notesController.text.trim()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '* Owner will be notified immediately upon booking.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _dateTile(String label, DateTime? date, IconData icon, VoidCallback onTap, DateFormat fmt) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: date != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: date != null ? AppTheme.primaryGreen : AppTheme.greyText),
                const SizedBox(width: 6),
                Text(date != null ? fmt.format(date) : 'Select',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: date != null ? AppTheme.black : AppTheme.greyText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay time, VoidCallback onTap) {
    final formatted = DateFormat('hh:mm a').format(DateTime(0, 0, 0, time.hour, time.minute));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(formatted, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.black)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 14)),
          Flexible(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
