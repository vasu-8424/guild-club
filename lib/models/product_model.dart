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
