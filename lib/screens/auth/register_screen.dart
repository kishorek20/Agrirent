// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  String  _role    = AppConstants.roleFarmer;
  String? _state;
  bool _obscureP = true, _obscureC = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose(); super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
      role: _role, state: _state,
    );
    if (!mounted) return;
    if (ok) {
      // Registration complete — always redirect to login
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Account created! Please sign in.'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 3),
      ));
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Registration failed'),
        backgroundColor: AppTheme.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Role selector
            Text('I am a...', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(children: [
              _roleCard('Farmer', Icons.grass, AppConstants.roleFarmer, 'Rent vehicles'),
              const SizedBox(width: 12),
              _roleCard('Owner', Icons.agriculture, AppConstants.roleOwner, 'List vehicles'),
            ]),
            const SizedBox(height: 24),

            // Fields
            Text('Personal Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryGreen)),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nameCtrl, label: 'Full Name', prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 3) ? 'Enter full name' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailCtrl, label: 'Email', prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _phoneCtrl, label: 'Phone Number', prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _state,
              decoration: InputDecoration(
                labelText: 'State', prefixIcon: const Icon(Icons.map_outlined, color: AppTheme.greyText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: AppConstants.indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _state = v),
            ),
            const SizedBox(height: 24),
            Text('Security', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryGreen)),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _passCtrl, label: 'Password', prefixIcon: Icons.lock_outline,
              obscureText: _obscureP,
              suffixIcon: IconButton(icon: Icon(_obscureP ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureP = !_obscureP)),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confCtrl, label: 'Confirm Password', prefixIcon: Icons.lock_outline,
              obscureText: _obscureC,
              suffixIcon: IconButton(icon: Icon(_obscureC ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureC = !_obscureC)),
              validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => LoadingButton(
                label: 'Create Account', isLoading: auth.isLoading, onPressed: _register),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account? '),
              TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In')),
            ]),
          ]),
        ),
      ),
    ),
  );

  Widget _roleCard(String label, IconData icon, String role, String sub) {
    final sel = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primaryGreen : AppTheme.lightGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? AppTheme.primaryGreenDark : AppTheme.primaryGreenLight, width: sel ? 2 : 1),
          ),
          child: Column(children: [
            Icon(icon, size: 36, color: sel ? Colors.white : AppTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: sel ? Colors.white : AppTheme.primaryGreen)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 12, color: sel ? Colors.white70 : AppTheme.greyText)),
          ]),
        ),
      ),
    );
  }
}
