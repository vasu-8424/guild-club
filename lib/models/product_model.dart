class ProductModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final double price;
  final double originalPrice;
  final int discountPercentage;
  final double rating;
  final int reviewCount;
  final int stockQuantity;
  final String categorySlug;
  final String brandName;
  final int minAge;
  final int maxAge;
  final String material;
  final String educationalType;
  final List<String> imageUrls;
  final bool isTrending;
  final bool isBestSeller;
  final bool isFeatured;
  final bool isLimitedEdition;
  final List<String> availableColors;

  const ProductModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.discountPercentage,
    required this.rating,
    required this.reviewCount,
    required this.stockQuantity,
    required this.categorySlug,
    required this.brandName,
    required this.minAge,
    required this.maxAge,
    required this.material,
    required this.educationalType,
    required this.imageUrls,
    this.isTrending = false,
    this.isBestSeller = false,
    this.isFeatured = false,
    this.isLimitedEdition = false,
    this.availableColors = const ['#FF4B4B', '#3B82F6', '#10B981', '#FFD000'],
  });

  String get ageBadgeText => '$minAge-$maxAge Yrs';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['image_urls'] != null && json['image_urls'] is List && (json['image_urls'] as List).isNotEmpty) {
      images = List<String>.from((json['image_urls'] as List).map((e) => e.toString()));
    } else if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      images = List<String>.from((json['images'] as List).map((e) => e.toString()));
    } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      images = [json['image_url'].toString()];
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      images = [json['image'].toString()];
    }
    if (images.isEmpty) {
      images = ['https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop'];
    }

    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final origPrice = (json['original_price'] as num?)?.toDouble() ?? price;
    final discount = (json['discount_percentage'] as num?)?.toInt() ??
        (origPrice > price && origPrice > 0 ? (((origPrice - price) / origPrice) * 100).round() : 0);

    return ProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: price,
      originalPrice: origPrice,
      discountPercentage: discount,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 50,
      categorySlug: json['category_slug']?.toString() ?? json['category_id']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? 'Guild Club',
      minAge: (json['min_age'] as num?)?.toInt() ?? 3,
      maxAge: (json['max_age'] as num?)?.toInt() ?? 12,
      material: json['material']?.toString() ?? 'Eco Wood',
      educationalType: json['educational_type']?.toString() ?? 'STEM',
      imageUrls: images,
      isTrending: json['is_trending'] as bool? ?? false,
      isBestSeller: json['is_best_seller'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isLimitedEdition: json['is_limited_edition'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'reviewCount': reviewCount,
      'stockQuantity': stockQuantity,
      'categorySlug': categorySlug,
      'brandName': brandName,
      'minAge': minAge,
      'maxAge': maxAge,
      'material': material,
      'educationalType': educationalType,
      'imageUrls': imageUrls,
      'isTrending': isTrending,
      'isBestSeller': isBestSeller,
      'isFeatured': isFeatured,
      'isLimitedEdition': isLimitedEdition,
      'availableColors': availableColors,
    };
  }
}
