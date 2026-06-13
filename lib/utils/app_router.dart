// lib/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/farmer/farmer_home_screen.dart';
import '../screens/farmer/search_vehicles_screen.dart';
import '../screens/farmer/vehicle_detail_screen.dart';
import '../screens/farmer/book_vehicle_screen.dart';
import '../screens/farmer/booking_history_screen.dart';
import '../screens/farmer/farmer_profile_screen.dart';
import '../screens/owner/owner_home_screen.dart';
import '../screens/owner/add_vehicle_screen.dart';
import '../screens/owner/edit_vehicle_screen.dart';
import '../screens/owner/manage_bookings_screen.dart';
import '../screens/owner/earnings_screen.dart';
import '../screens/owner/owner_profile_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_vehicles_screen.dart';
import '../screens/admin/view_bookings_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/shared/notifications_screen.dart';
import 'app_theme.dart';

class AppRouter {
  static const _publicPaths = ['/splash', '/login', '/register'];

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: _redirect,
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Farmer shell
      ShellRoute(
        builder: (_, __, child) => _FarmerShell(child: child),
        routes: [
          GoRoute(path: '/farmer/home',          builder: (_, __) => const FarmerHomeScreen()),
          GoRoute(path: '/farmer/search',        builder: (_, __) => const SearchVehiclesScreen()),
          GoRoute(path: '/farmer/bookings',      builder: (_, __) => const BookingHistoryScreen()),
          GoRoute(path: '/farmer/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/farmer/profile',       builder: (_, __) => const FarmerProfileScreen()),
        ],
      ),
      GoRoute(path: '/vehicle/:id', builder: (_, s) => VehicleDetailScreen(vehicleId: s.pathParameters['id']!)),
      GoRoute(path: '/book/:vid',   builder: (_, s) => BookVehicleScreen(vehicleId: s.pathParameters['vid']!)),

      // Owner shell
      ShellRoute(
        builder: (_, __, child) => _OwnerShell(child: child),
        routes: [
          GoRoute(path: '/owner/home',          builder: (_, __) => const OwnerHomeScreen()),
          GoRoute(path: '/owner/bookings',      builder: (_, __) => const ManageBookingsScreen()),
          GoRoute(path: '/owner/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/owner/earnings',      builder: (_, __) => const EarningsScreen()),
          GoRoute(path: '/owner/profile',       builder: (_, __) => const OwnerProfileScreen()),
        ],
      ),
      GoRoute(path: '/owner/add-vehicle',       builder: (_, __) => const AddVehicleScreen()),
      GoRoute(path: '/owner/edit-vehicle/:id',  builder: (_, s)  => EditVehicleScreen(vehicleId: s.pathParameters['id']!)),

      // Admin shell
      ShellRoute(
        builder: (_, __, child) => _AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/home',          builder: (_, __) => const AdminHomeScreen()),
          GoRoute(path: '/admin/users',         builder: (_, __) => const ManageUsersScreen()),
          GoRoute(path: '/admin/vehicles',      builder: (_, __) => const ManageVehiclesScreen()),
          GoRoute(path: '/admin/bookings',      builder: (_, __) => const ViewBookingsScreen()),
          GoRoute(path: '/admin/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/admin/analytics',     builder: (_, __) => const AnalyticsScreen()),
        ],
      ),
    ],
  );

  static String? _redirect(BuildContext ctx, GoRouterState state) {
    final auth = ctx.read<AuthProvider>();
    final loc  = state.matchedLocation;
    final pub  = _publicPaths.contains(loc);

    // Still initialising — hold on splash
    if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
      return pub ? null : '/splash';
    }

    // Not logged in — send to login
    if (!auth.isAuthenticated) return pub ? null : '/login';

    // Logged in on a public page — redirect to role home
    if (pub) return _home(auth.userRole);

    // Prevent cross-role navigation
    final role = auth.userRole;
    if (role == 'farmer' && (loc.startsWith('/owner') || loc.startsWith('/admin'))) {
      return '/farmer/home';
    }
    if (role == 'owner' && loc.startsWith('/admin')) {
      return '/owner/home';
    }

    return null;
  }

  static String _home(String? role) {
    switch (role) {
      case 'owner': return '/owner/home';
      case 'admin': return '/admin/home';
      default:      return '/farmer/home';
    }
  }
}

// ─── Responsive Navigation Helpers ──────────────────────────────────────────

PreferredSizeWidget? _buildTopNav(
  BuildContext context,
  int currentIndex,
  List<String> paths,
  List<BottomNavigationBarItem> items,
  bool isWeb,
) {
  if (!isWeb) return null;
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 1,
    title: const Row(
      children: [
        Icon(Icons.agriculture, color: AppTheme.primaryGreen),
        SizedBox(width: 8),
        Text('AgriRent',
            style: TextStyle(
                color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
      ],
    ),
    actions: [
      for (int i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextButton.icon(
            onPressed: () => context.go(paths[i]),
            icon: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(
                  color: i == currentIndex
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              child: i == currentIndex ? items[i].activeIcon : items[i].icon,
            ),
            label: Text(
              items[i].label ?? '',
              style: TextStyle(
                color: i == currentIndex
                    ? AppTheme.primaryGreen
                    : Colors.grey.shade700,
                fontWeight: i == currentIndex ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      const SizedBox(width: 16),
    ],
  );
}

// ─── Bottom-nav shells ────────────────────────────────────────────────────────

class _FarmerShell extends StatelessWidget {
  final Widget child;
  const _FarmerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final paths = [
      '/farmer/home',
      '/farmer/search',
      '/farmer/bookings',
      '/farmer/notifications',
      '/farmer/profile'
    ];
    final idx = paths.indexWhere(loc.startsWith);
    final cur = idx < 0 ? 0 : idx;
    const items = [
      BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search),
          label: 'Search'),
      BottomNavigationBarItem(
          icon: Icon(Icons.book_online_outlined),
          activeIcon: Icon(Icons.book_online),
          label: 'Bookings'),
      BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWeb = constraints.maxWidth >= 800;
      return Scaffold(
        appBar: _buildTopNav(context, cur, paths, items, isWeb),
        body: child,
        bottomNavigationBar: isWeb
            ? null
            : BottomNavigationBar(
                currentIndex: cur,
                onTap: (i) => context.go(paths[i]),
                items: items,
              ),
      );
    });
  }
}

class _OwnerShell extends StatelessWidget {
  final Widget child;
  const _OwnerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final paths = [
      '/owner/home',
      '/owner/bookings',
      '/owner/notifications',
      '/owner/earnings',
      '/owner/profile'
    ];
    final idx = paths.indexWhere(loc.startsWith);
    final cur = idx < 0 ? 0 : idx;
    const items = [
      BottomNavigationBarItem(
          icon: Icon(Icons.agriculture_outlined),
          activeIcon: Icon(Icons.agriculture),
          label: 'Vehicles'),
      BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Bookings'),
      BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts'),
      BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_outlined),
          activeIcon: Icon(Icons.attach_money),
          label: 'Earnings'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWeb = constraints.maxWidth >= 800;
      return Scaffold(
        appBar: _buildTopNav(context, cur, paths, items, isWeb),
        body: child,
        bottomNavigationBar: isWeb
            ? null
            : BottomNavigationBar(
                currentIndex: cur,
                onTap: (i) => context.go(paths[i]),
                items: items,
              ),
      );
    });
  }
}

class _AdminShell extends StatelessWidget {
  final Widget child;
  const _AdminShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final paths = [
      '/admin/home',
      '/admin/users',
      '/admin/vehicles',
      '/admin/bookings',
      '/admin/notifications'
    ];
    final idx = paths.indexWhere(loc.startsWith);
    final cur = idx < 0 ? 0 : idx;
    const items = [
      BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard'),
      BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Users'),
      BottomNavigationBarItem(
          icon: Icon(Icons.agriculture_outlined),
          activeIcon: Icon(Icons.agriculture),
          label: 'Vehicles'),
      BottomNavigationBarItem(
          icon: Icon(Icons.book_online_outlined),
          activeIcon: Icon(Icons.book_online),
          label: 'Bookings'),
      BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWeb = constraints.maxWidth >= 800;
      return Scaffold(
        appBar: _buildTopNav(context, cur, paths, items, isWeb),
        body: child,
        bottomNavigationBar: isWeb
            ? null
            : BottomNavigationBar(
                currentIndex: cur,
                onTap: (i) => context.go(paths[i]),
                items: items,
              ),
      );
    });
  }
}
