class ListingModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String primaryPhotoUrl;
  final List<String> galleryUrls;
  final double rating;
  final int reviewCount;
  final String address;
  final String city;
  final double? distanceKm;
  final String priceRange;
  final bool isVerified;
  final bool isActive;
  final String phone;
  final String whatsapp;
  final String operatingHours;
  final String ageGroup;
  final DateTime createdAt;

  const ListingModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    required this.primaryPhotoUrl,
    this.galleryUrls = const [],
    this.rating = 5.0,
    this.reviewCount = 0,
    this.address = '',
    this.city = '',
    this.distanceKm,
    this.priceRange = '',
    this.isVerified = true,
    this.isActive = true,
    this.phone = '',
    this.whatsapp = '',
    this.operatingHours = '',
    this.ageGroup = '',
    required this.createdAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    List<String> parseGallery(dynamic list) {
      if (list == null) return [];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ListingModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      primaryPhotoUrl: json['primary_photo_url']?.toString() ??
          'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop',
      galleryUrls: parseGallery(json['gallery_urls']),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      priceRange: json['price_range']?.toString() ?? '',
      isVerified: json['is_verified'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      phone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      operatingHours: json['operating_hours']?.toString() ?? '',
      ageGroup: json['age_group']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'primary_photo_url': primaryPhotoUrl,
      'gallery_urls': galleryUrls,
      'rating': rating,
      'review_count': reviewCount,
      'address': address,
      'city': city,
      'distance_km': distanceKm,
      'price_range': priceRange,
      'is_verified': isVerified,
      'is_active': isActive,
      'phone': phone,
      'whatsapp': whatsapp,
      'operating_hours': operatingHours,
      'age_group': ageGroup,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ListingModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    String? primaryPhotoUrl,
    List<String>? galleryUrls,
    double? rating,
    int? reviewCount,
    String? address,
    String? city,
    double? distanceKm,
    String? priceRange,
    bool? isVerified,
    bool? isActive,
    String? phone,
    String? whatsapp,
    String? operatingHours,
    String? ageGroup,
    DateTime? createdAt,
  }) {
    return ListingModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryPhotoUrl: primaryPhotoUrl ?? this.primaryPhotoUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      address: address ?? this.address,
      city: city ?? this.city,
      distanceKm: distanceKm ?? this.distanceKm,
      priceRange: priceRange ?? this.priceRange,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      operatingHours: operatingHours ?? this.operatingHours,
      ageGroup: ageGroup ?? this.ageGroup,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
