import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String iconKey;
  final String? parentId;
  final int sortOrder;
  final String colorHex;
  final String bannerUrl;
  final int itemCount;
  final bool isActive;
  final bool hasSubcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
    this.parentId,
    this.sortOrder = 0,
    this.colorHex = '#1E3A8A',
    this.bannerUrl = '',
    this.itemCount = 0,
    this.isActive = true,
    this.hasSubcategories = false,
  });

  // Legacy compatibility getters
  String get iconName => iconKey;
  int get productCount => itemCount;

  /// Pure vector line/duotone icons chosen per category — zero stock emojis used.
  static IconData resolveIcon(String key) {
    final cleanKey = key.toLowerCase().replaceAll('-', '_').trim();
    switch (cleanKey) {
      case 'play_schools':
      case 'play_school':
        return Icons.toys_rounded;
      case 'child_development':
      case 'child_development_centers':
      case 'child_development_center':
        return Icons.psychology_rounded;
      case 'schools':
      case 'school':
        return Icons.school_rounded;
      case 'interior_designing':
      case 'interior_design':
        return Icons.architecture_rounded;
      case 'speech_therapy':
        return Icons.record_voice_over_rounded;
      case 'occupational_therapy':
        return Icons.accessibility_new_rounded;
      case 'behavioural_therapy':
      case 'behavioral_therapy':
        return Icons.self_improvement_rounded;
      case 'special_education':
        return Icons.auto_stories_rounded;
      case 'stem':
      case 'stem_robotics':
        return Icons.smart_toy_rounded;
      case 'building':
      case 'building_blocks':
        return Icons.extension_rounded;
      case 'rc':
      case 'remote_control':
        return Icons.sports_motorsports_rounded;
      case 'action':
      case 'action_figures':
        return Icons.shield_rounded;
      case 'soft':
      case 'plush':
      case 'plush_soft_toys':
        return Icons.pets_rounded;
      case 'puzzles':
      case 'puzzles_brain':
        return Icons.extension_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  /// 3D isometric illustration assets for categories
  static String? resolveIllustrationAsset(String key) {
    final cleanKey = key.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
    switch (cleanKey) {
      case 'play_schools':
      case 'play_school':
      case 'toys_rounded':
      case 'toys':
      case 'c1000000_0000_0000_0000_000000000001':
        return 'assets/images/categories/play_schools.png';
      case 'child_development':
      case 'child_development_centers':
      case 'child_development_center':
      case 'psychology_rounded':
      case 'psychology':
      case 'c1000000_0000_0000_0000_000000000002':
        return 'assets/images/categories/child_development.png';
      case 'schools':
      case 'school':
      case 'school_rounded':
      case 'c1000000_0000_0000_0000_000000000003':
        return 'assets/images/categories/schools.png';
      case 'interior_designing':
      case 'interior_design':
      case 'architecture_rounded':
      case 'architecture':
      case 'c1000000_0000_0000_0000_000000000004':
        return 'assets/images/categories/interior_designing.png';
      case 'speech_therapy':
      case 'speech':
      case 'record_voice_over_rounded':
      case 'record_voice_over':
      case 'c2000000_0000_0000_0000_000000000001':
        return 'assets/images/categories/speech_therapy.png';
      case 'occupational_therapy':
      case 'occupational':
      case 'accessibility_new_rounded':
      case 'accessibility_new':
      case 'accessibility':
      case 'c2000000_0000_0000_0000_000000000002':
        return 'assets/images/categories/occupational_therapy.png';
      case 'behavioural_therapy':
      case 'behavioural':
      case 'behavioral_therapy':
      case 'behavioral':
      case 'psychology_alt_rounded':
      case 'psychology_alt':
      case 'self_improvement_rounded':
      case 'self_improvement':
      case 'c2000000_0000_0000_0000_000000000003':
        return 'assets/images/categories/behavioural_therapy.png';
      case 'special_education':
      case 'special':
      case 'auto_stories_rounded':
      case 'auto_stories':
      case 'c2000000_0000_0000_0000_000000000004':
        return 'assets/images/categories/special_education.png';
      default:
        return null;
    }
  }

  String? get illustrationAsset {
    if (slug.isNotEmpty) {
      final res = resolveIllustrationAsset(slug);
      if (res != null) return res;
    }
    if (iconKey.isNotEmpty) {
      final res = resolveIllustrationAsset(iconKey);
      if (res != null) return res;
    }
    if (name.isNotEmpty) {
      final res = resolveIllustrationAsset(name);
      if (res != null) return res;
    }
    if (id.isNotEmpty) {
      final res = resolveIllustrationAsset(id);
      if (res != null) return res;
    }
    return null;
  }

  IconData get icon => resolveIcon(iconKey.isNotEmpty ? iconKey : slug);

  factory CategoryModel.fromJson(Map<String, dynamic> json, {bool hasSubcategories = false}) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? json['icon_name']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      colorHex: json['color_hex']?.toString() ?? '#1E3A8A',
      bannerUrl: json['banner_url']?.toString() ?? '',
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      hasSubcategories: hasSubcategories || (json['has_subcategories'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon_key': iconKey,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'color_hex': colorHex,
      'banner_url': bannerUrl,
      'is_active': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? iconKey,
    String? parentId,
    int? sortOrder,
    String? colorHex,
    String? bannerUrl,
    int? itemCount,
    bool? isActive,
    bool? hasSubcategories,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      iconKey: iconKey ?? this.iconKey,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      colorHex: colorHex ?? this.colorHex,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      itemCount: itemCount ?? this.itemCount,
      isActive: isActive ?? this.isActive,
      hasSubcategories: hasSubcategories ?? this.hasSubcategories,
    );
  }
}
