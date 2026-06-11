// lib/models/user_model.dart
class UserModel {
  final String id;
  final String authId;
  final String fullName;
  final String email;
  final String? phone;
  final String role; // farmer | owner | admin
  final String? profileImageUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id, required this.authId, required this.fullName,
    required this.email, this.phone, required this.role,
    this.profileImageUrl, this.address, this.city, this.state,
    this.pincode, this.isVerified = false, this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '', authId: j['auth_id'] ?? '',
    fullName: j['full_name'] ?? '', email: j['email'] ?? '',
    phone: j['phone'], role: j['role'] ?? 'farmer',
    profileImageUrl: j['profile_image_url'],
    address: j['address'], city: j['city'], state: j['state'],
    pincode: j['pincode'],
    isVerified: j['is_verified'] ?? false, isActive: j['is_active'] ?? true,
    createdAt: DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toJson() => {
    'auth_id': authId, 'full_name': fullName, 'email': email,
    'phone': phone, 'role': role, 'profile_image_url': profileImageUrl,
    'address': address, 'city': city, 'state': state, 'pincode': pincode,
    'is_verified': isVerified, 'is_active': isActive,
  };

  String get firstName => fullName.split(' ').first;
  String get initials  => fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
}
