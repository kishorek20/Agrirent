// lib/models/vehicle_model.dart
class VehicleModel {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String vehicleType;
  final String? brand;
  final String? model;
  final int? year;
  final double pricePerHour;
  final double pricePerDay;
  final String? location;
  final String? city;
  final String? state;
  final List<String> imageUrls;
  final List<String> features;
  final bool isAvailable;
  final bool isApproved;
  final String? fuelType;
  final int? horsepower;
  final String? capacity;
  final int totalBookings;
  final double averageRating;
  final DateTime createdAt;
  final String? ownerName;
  final String? ownerPhone;

  VehicleModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    required this.vehicleType,
    this.brand,
    this.model,
    this.year,
    required this.pricePerHour,
    required this.pricePerDay,
    this.location,
    this.city,
    this.state,
    this.imageUrls = const [],
    this.features = const [],
    this.isAvailable = true,
    this.isApproved = false,
    this.fuelType,
    this.horsepower,
    this.capacity,
    this.totalBookings = 0,
    this.averageRating = 0.0,
    required this.createdAt,
    this.ownerName,
    this.ownerPhone,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> j) {
    List<String> imgs = [];
    if (j['image_urls'] is List) imgs = List<String>.from(j['image_urls']);
    List<String> feats = [];
    if (j['features'] is List) feats = List<String>.from(j['features']);
    return VehicleModel(
      id: j['id'] ?? '',
      ownerId: j['owner_id'] ?? '',
      title: j['title'] ?? '',
      description: j['description'],
      vehicleType: j['vehicle_type'] ?? '',
      brand: j['brand'],
      model: j['model'],
      year: j['year'],
      pricePerHour: (j['price_per_hour'] ?? 0).toDouble(),
      pricePerDay: (j['price_per_day'] ?? 0).toDouble(),
      location: j['location'],
      city: j['city'],
      state: j['state'],
      imageUrls: imgs,
      features: feats,
      isAvailable: j['is_available'] ?? true,
      isApproved:
          (j['is_approved'] == true) || (j['approval_status'] == 'approved'),
      fuelType: j['fuel_type'],
      horsepower: j['horsepower'],
      capacity: j['capacity'],
      totalBookings: j['total_bookings'] ?? 0,
      averageRating: (j['average_rating'] ?? 0).toDouble(),
      createdAt:
          DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
      ownerName: j['users']?['full_name'],
      ownerPhone: j['users']?['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'price_per_hour': pricePerHour,
        'price_per_day': pricePerDay,
        'location': location,
        'city': city,
        'state': state,
        'image_urls': imageUrls,
        'features': features,
        'is_available': isAvailable,
        'fuel_type': fuelType,
        'horsepower': horsepower,
        'capacity': capacity,
      };

  String get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get locationLabel =>
      [city, state].where((e) => e != null && e.isNotEmpty).join(', ');
}
