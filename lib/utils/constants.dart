// lib/utils/constants.dart
// Replace the two placeholder strings with your Supabase credentials.

class AppConstants {
  // ── Supabase (REQUIRED) ──────────────────────────────────────────────────
  static const String supabaseUrl = 'https://atafeyidjdzedbktzivx.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_z5j2Bq8qKez-9zs2VbJJOg_eE8Q1RjJ';

  // ── App meta ─────────────────────────────────────────────────────────────
  static const String appName = 'AgriRent';
  static const String appTagline = 'Smart Agriculture Vehicle Rental';

  // ── Table names ──────────────────────────────────────────────────────────
  static const String usersTable = 'users';
  static const String vehiclesTable = 'vehicles';
  static const String bookingsTable = 'bookings';
  static const String reviewsTable = 'reviews';
  static const String paymentsTable = 'payments';
  static const String notificationsTable = 'notifications';

  // ── Storage buckets ──────────────────────────────────────────────────────
  static const String vehicleImagesBucket = 'vehicle-images';
  static const String profileImagesBucket = 'profile-images';

  // ── Roles ────────────────────────────────────────────────────────────────
  static const String roleFarmer = 'farmer';
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';

  // ── Booking statuses ─────────────────────────────────────────────────────
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingActive = 'active';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';
  static const String bookingRejected = 'rejected';

  // ── Vehicle types ────────────────────────────────────────────────────────
  static const List<String> vehicleTypes = [
    'Tractor',
    'Harvester',
    'Plough',
    'Cultivator',
    'Sprayer',
    'Seeder',
    'Thresher',
    'Rotavator',
    'Power Tiller',
    'Mini Tractor',
  ];

  // ── Indian states ────────────────────────────────────────────────────────
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static const double taxRate = 0.05; // 5% GST
}
