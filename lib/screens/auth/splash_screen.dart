// lib/screens/auth/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.loadCurrentUser();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      switch (auth.userRole) {
        case 'owner': context.go('/owner/home'); break;
        case 'admin': context.go('/admin/home'); break;
        default:      context.go('/farmer/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen, AppTheme.primaryGreenLight],
        ),
      ),
      child: Center(
        child: FadeTransition(opacity: _fade,
          child: ScaleTransition(scale: _scale,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.agriculture, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text('AgriRent',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Smart Agriculture Vehicle Rental',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 64),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ]),
          )),
      ),
    ),
  );
}
