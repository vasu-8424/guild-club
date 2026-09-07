import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/admin_stats_model.dart';
import '../models/listing_model.dart';

class MockToyData {
  // Master Categories (Top-level + Subcategories with Heraldic Crest Palette Rotation)
  static const List<CategoryModel> categories = [
    // Top-Level Categories
    CategoryModel(
      id: 'c1000000-0000-0000-0000-000000000001',
      name: 'Play Schools',
      slug: 'play-schools',
      iconKey: 'play_schools',
      sortOrder: 1,
      colorHex: '#1E3A8A', // Royal Navy Blue
      bannerUrl: 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop',
      itemCount: 24,
      hasSubcategories: false,
    ),
    CategoryModel(
      id: 'c1000000-0000-0000-0000-000000000002',
      name: 'Child Development Centers',
      slug: 'child-development-centers',
      iconKey: 'child_development',
      sortOrder: 2,
      colorHex: '#B91C1C', // Crest Red
      bannerUrl: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop',
      itemCount: 4,
      hasSubcategories: true,
    ),
    CategoryModel(
      id: 'c1000000-0000-0000-0000-000000000003',
      name: 'Schools',
      slug: 'schools',
      iconKey: 'schools',
      sortOrder: 3,
      colorHex: '#0F172A', // Midnight Navy Obsidian
      bannerUrl: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=800&auto=format&fit=crop',
      itemCount: 18,
      hasSubcategories: false,
    ),
    CategoryModel(
      id: 'c1000000-0000-0000-0000-000000000004',
      name: 'Interior Designing',
      slug: 'interior-designing',
      iconKey: 'interior_designing',
      sortOrder: 4,
      colorHex: '#FFFFFF', // Pure White with Red Hairline Border
      bannerUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop',
      itemCount: 12,
      hasSubcategories: false,
    ),

    // Subcategories under Child Development Centers
    CategoryModel(
      id: 'c2000000-0000-0000-0000-000000000001',
      parentId: 'c1000000-0000-0000-0000-000000000002',
      name: 'Speech Therapy',
      slug: 'speech-therapy',
      iconKey: 'speech_therapy',
      sortOrder: 1,
      colorHex: '#1E3A8A', // Royal Navy Blue
      bannerUrl: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop',
      itemCount: 8,
    ),
    CategoryModel(
      id: 'c2000000-0000-0000-0000-000000000002',
      parentId: 'c1000000-0000-0000-0000-000000000002',
      name: 'Occupational Therapy',
      slug: 'occupational-therapy',
      iconKey: 'occupational_therapy',
      sortOrder: 2,
      colorHex: '#B91C1C', // Crest Red
      bannerUrl: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=800&auto=format&fit=crop',
      itemCount: 10,
    ),
    CategoryModel(
      id: 'c2000000-0000-0000-0000-000000000003',
      parentId: 'c1000000-0000-0000-0000-000000000002',
      name: 'Behavioural Therapy',
      slug: 'behavioural-therapy',
      iconKey: 'behavioural_therapy',
      sortOrder: 3,
      colorHex: '#0F172A', // Midnight Navy Obsidian
      bannerUrl: 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=800&auto=format&fit=crop',
      itemCount: 6,
    ),
    CategoryModel(
      id: 'c2000000-0000-0000-0000-000000000004',
      parentId: 'c1000000-0000-0000-0000-000000000002',
      name: 'Special Education',
      slug: 'special-education',
      iconKey: 'special_education',
      sortOrder: 4,
      colorHex: '#FFFFFF', // Pure White with Red Hairline Border
      bannerUrl: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=800&auto=format&fit=crop',
      itemCount: 9,
    ),
  ];

  static List<CategoryModel> get topLevelCategories =>
      categories.where((c) => c.parentId == null && c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  static List<CategoryModel> subcategoriesFor(String parentId) =>
      categories.where((c) => (c.parentId == parentId || parentId.contains(c.parentId ?? 'never')) && c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  static CategoryModel? findCategory(String identifier) {
    return categories.where((c) => c.id == identifier || c.slug == identifier).firstOrNull;
  }

  // Master Sample Listings
  static final List<ListingModel> sampleListings = [
    // 1. Play Schools
    ListingModel(
      id: 'l1000000-0000-0000-0000-000000000001',
      categoryId: 'c1000000-0000-0000-0000-000000000001',
      name: 'Little Explorers Early Learning Academy',
      description: 'Holistic Montessori play school offering experiential play, nature immersion, organic snack programs, and cognitive sensory zones tailored for young learners. Certified educators and 1:6 caregiver ratio.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 148,
      address: '14th Main Road, Indiranagar',
      city: 'Bengaluru',
      distanceKm: 1.8,
      priceRange: '₹8,000 - ₹15,000 / month',
      isVerified: true,
      phone: '+91 98450 12345',
      whatsapp: '+91 98450 12345',
      operatingHours: '8:30 AM - 1:30 PM (Mon-Fri)',
      ageGroup: '1.5 - 5.5 Years',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ListingModel(
      id: 'l1000000-0000-0000-0000-000000000002',
      categoryId: 'c1000000-0000-0000-0000-000000000001',
      name: 'Blooms Play & Discovery Haven',
      description: 'Reggio Emilia inspired preschool curriculum with open-ended play spaces, child-safe sensory gardens, and parent-toddler weekend bonding sessions.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 92,
      address: '5th Block, Koramangala',
      city: 'Bengaluru',
      distanceKm: 3.2,
      priceRange: '₹10,000 - ₹18,000 / month',
      isVerified: true,
      phone: '+91 99801 54321',
      whatsapp: '+91 99801 54321',
      operatingHours: '9:00 AM - 2:00 PM (Mon-Fri)',
      ageGroup: '2 - 6 Years',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),

    // 2. Schools
    ListingModel(
      id: 'l1000000-0000-0000-0000-000000000003',
      categoryId: 'c1000000-0000-0000-0000-000000000003',
      name: 'The Cambridge International Academy',
      description: 'Premier ICSE & IGCSE affiliated institution emphasizing holistic academic excellence, AI robotics laboratories, arts conservatory, and Olympic-sized sports facilities.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 310,
      address: 'Sarjapur Main Road',
      city: 'Bengaluru',
      distanceKm: 5.4,
      priceRange: '₹1.5L - ₹2.8L / year',
      isVerified: true,
      phone: '+91 80 4123 7890',
      whatsapp: '+91 98450 67890',
      operatingHours: '8:00 AM - 3:30 PM (Mon-Fri)',
      ageGroup: 'Grade 1 - Grade 12',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),

    // 3. Interior Designing
    ListingModel(
      id: 'l1000000-0000-0000-0000-000000000004',
      categoryId: 'c1000000-0000-0000-0000-000000000004',
      name: 'Studio Nestling Kids Interiors',
      description: 'Award-winning child-safe interior architecture studio crafting whimsical themed bedrooms, ergonomic homework study lofts, and Montessori playroom environments with zero-VOC finishes.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 78,
      address: '100ft Road, Defence Colony',
      city: 'Bengaluru',
      distanceKm: 2.1,
      priceRange: 'Custom Quote / Consultation',
      isVerified: true,
      phone: '+91 98860 99887',
      whatsapp: '+91 98860 99887',
      operatingHours: '10:00 AM - 7:00 PM (Mon-Sat)',
      ageGroup: 'All Ages (Nursery to Teen)',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),

    // 4. Speech Therapy
    ListingModel(
      id: 'l2000000-0000-0000-0000-000000000001',
      categoryId: 'c2000000-0000-0000-0000-000000000001',
      name: 'SoundSteps Pediatric Speech Therapy',
      description: 'Gold-standard speech-language therapy center specializing in early speech delay interventions, articulation therapy, stuttering fluency, and augmentative communication (AAC).',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 5.0,
      reviewCount: 116,
      address: 'HSR Layout Sector 2',
      city: 'Bengaluru',
      distanceKm: 2.9,
      priceRange: '₹1,200 - ₹2,000 / session',
      isVerified: true,
      phone: '+91 97410 44556',
      whatsapp: '+91 97410 44556',
      operatingHours: '9:00 AM - 6:00 PM (Mon-Sat)',
      ageGroup: '1.5 - 14 Years',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),

    // 5. Occupational Therapy
    ListingModel(
      id: 'l2000000-0000-0000-0000-000000000002',
      categoryId: 'c2000000-0000-0000-0000-000000000002',
      name: 'SensoryRise Occupational Therapy Hub',
      description: 'Dedicated sensory integration gym with licensed occupational therapists focusing on sensory processing modulation, fine-motor coordination, visual perception, and daily living autonomy.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 94,
      address: 'Jayanagar 4th Block',
      city: 'Bengaluru',
      distanceKm: 4.1,
      priceRange: '₹1,500 - ₹2,200 / session',
      isVerified: true,
      phone: '+91 99002 33445',
      whatsapp: '+91 99002 33445',
      operatingHours: '8:30 AM - 6:30 PM (Mon-Sat)',
      ageGroup: '2 - 16 Years',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),

    // 6. Behavioural Therapy
    ListingModel(
      id: 'l2000000-0000-0000-0000-000000000003',
      categoryId: 'c2000000-0000-0000-0000-000000000003',
      name: 'MindSpring Child Behavioural Clinic',
      description: 'Compassionate pediatric behavioral health center providing ABA therapy, emotional self-regulation training, ADHD coaching, and structured social skills peer groups.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 83,
      address: 'Kalyan Nagar',
      city: 'Bengaluru',
      distanceKm: 6.0,
      priceRange: '₹1,800 - ₹2,500 / session',
      isVerified: true,
      phone: '+91 98452 77889',
      whatsapp: '+91 98452 77889',
      operatingHours: '9:30 AM - 5:30 PM (Mon-Fri)',
      ageGroup: '3 - 15 Years',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),

    // 7. Special Education
    ListingModel(
      id: 'l2000000-0000-0000-0000-000000000004',
      categoryId: 'c2000000-0000-0000-0000-000000000004',
      name: 'BrightBridge Inclusive Learning Center',
      description: 'Specialized remedial education center offering customized Individualized Education Plans (IEP), dyslexia remediation, dyscalculia intervention, and shadow teaching support.',
      primaryPhotoUrl: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=800&auto=format&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 105,
      address: 'BTM Layout 2nd Stage',
      city: 'Bengaluru',
      distanceKm: 3.7,
      priceRange: '₹1,000 - ₹1,800 / session',
      isVerified: true,
      phone: '+91 97312 88990',
      whatsapp: '+91 97312 88990',
      operatingHours: '9:00 AM - 5:00 PM (Mon-Sat)',
      ageGroup: '4 - 18 Years',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
    ),
  ];

  static List<ListingModel> listingsForCategory(String categoryIdOrSlug) {
    final matchedCat = findCategory(categoryIdOrSlug);
    final targetId = matchedCat?.id ?? categoryIdOrSlug;
    return sampleListings.where((l) => l.categoryId == targetId && l.isActive).toList();
  }

  static ListingModel? listingById(String id) {
    return sampleListings.where((l) => l.id == id).firstOrNull;
  }

  static const List<ProductModel> products = [
    ProductModel(
      id: 'p_1',
      title: 'Galactic Explorer 3D Mech Robot',
      subtitle: 'Programmable STEM Robot with Light-Up Core',
      description: 'Step into the future with the Galactic Explorer Mech! Features gesture controls, voice response, 24 customizable LED lights, and modular armor pieces engineered for young space cadets.',
      price: 2499.00,
      originalPrice: 3499.00,
      discountPercentage: 28,
      rating: 4.9,
      reviewCount: 342,
      stockQuantity: 24,
      categorySlug: 'stem',
      brandName: 'CosmoTech Kids',
      minAge: 6,
      maxAge: 12,
      material: 'BPA-Free ABS Polymer & Stainless Accents',
      educationalType: 'STEM Coding & Mechanical Logic',
      imageUrls: [
        'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1535378917042-10a22c95931a?q=80&w=800&auto=format&fit=crop',
      ],
      isTrending: true,
      isBestSeller: true,
      isFeatured: true,
    ),
    ProductModel(
      id: 'p_2',
      title: 'WonderCastle Magical Block Fortress',
      subtitle: '850+ Premium Eco-Wood Building Blocks',
      description: 'Build majestic kingdoms and enchanted towers! Crafting with non-toxic organic dyes and soft rounded corners designed for maximum creative joy.',
      price: 3299.00,
      originalPrice: 4299.00,
      discountPercentage: 23,
      rating: 4.8,
      reviewCount: 215,
      stockQuantity: 40,
      categorySlug: 'building',
      brandName: 'LEGO Crafts',
      minAge: 4,
      maxAge: 10,
      material: 'Sustainably Harvested Beech Wood',
      educationalType: 'Spatial Creativity & Fine Motor',
      imageUrls: [
        'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?q=80&w=800&auto=format&fit=crop',
      ],
      isBestSeller: true,
      isFeatured: true,
    ),
    ProductModel(
      id: 'p_3',
      title: 'HyperDrifter 4WD All-Terrain Buggy',
      subtitle: 'High Speed Dual-Motor Remote Control Car',
      description: 'Conquer backyard trails and indoor race tracks! Features shock-absorbing monster tires, 2.4GHz remote controller, and rechargeable fast-charge battery.',
      price: 1899.00,
      originalPrice: 2499.00,
      discountPercentage: 24,
      rating: 4.7,
      reviewCount: 189,
      stockQuantity: 15,
      categorySlug: 'rc',
      brandName: 'TurboRider',
      minAge: 8,
      maxAge: 14,
      material: 'Reinforced Shatterproof Chassis',
      educationalType: 'Hand-Eye Coordination',
      imageUrls: [
        'https://images.unsplash.com/photo-1594787318286-3d835c1d207f?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1563720223185-11003d516935?q=80&w=800&auto=format&fit=crop',
      ],
      isTrending: true,
    ),
    ProductModel(
      id: 'p_4',
      title: 'FluffyCloud Giant Huggable Teddy',
      subtitle: 'Ultra-Soft Organic Cotton Plush Companion',
      description: 'The softest hug in the universe! Hypoallergenic plush fur, reinforced velvet stitching, and anti-flattening inner fill.',
      price: 1299.00,
      originalPrice: 1799.00,
      discountPercentage: 27,
      rating: 5.0,
      reviewCount: 520,
      stockQuantity: 60,
      categorySlug: 'soft',
      brandName: 'Disney Cuddle',
      minAge: 1,
      maxAge: 8,
      material: '100% Organic Plush Velvet & Recycled Fill',
      educationalType: 'Emotional Comfort & Sensory Touch',
      imageUrls: [
        'https://images.unsplash.com/photo-1559454403-b8fb88521f11?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1533227268428-f9ed0900fb3b?q=80&w=800&auto=format&fit=crop',
      ],
      isBestSeller: true,
      isLimitedEdition: true,
    ),
    ProductModel(
      id: 'p_5',
      title: 'Solar System 3D Planetarium Projector',
      subtitle: 'Interactive Rotating Cosmic Globe with Audio Guide',
      description: 'Transform bedroom ceilings into breathtaking starry galaxies! Projects 8 planets with voice narration narrated by real astronomers.',
      price: 2199.00,
      originalPrice: 2999.00,
      discountPercentage: 26,
      rating: 4.9,
      reviewCount: 142,
      stockQuantity: 18,
      categorySlug: 'stem',
      brandName: 'CosmoTech Kids',
      minAge: 5,
      maxAge: 12,
      material: 'Optic Glass Lenses & Matte ABS',
      educationalType: 'Astronomy & Physics Discovery',
      imageUrls: [
        'https://images.unsplash.com/photo-1618842676088-c4d48a6a7c9d?q=80&w=800&auto=format&fit=crop',
      ],
      isTrending: true,
      isFeatured: true,
    ),
    ProductModel(
      id: 'p_6',
      title: 'CyberKnight Armor Action Figure',
      subtitle: 'Articulated Superhero with LED Sword & Sound FX',
      description: 'Fully poseable 12-inch superhero figure equipped with battle shield, glowing laser blade, and 15 movie action sound effects.',
      price: 1499.00,
      originalPrice: 1999.00,
      discountPercentage: 25,
      rating: 4.6,
      reviewCount: 98,
      stockQuantity: 30,
      categorySlug: 'action',
      brandName: 'Hasbro Hero',
      minAge: 5,
      maxAge: 11,
      material: 'Impact Resistant PVC',
      educationalType: 'Storytelling & Imaginative Play',
      imageUrls: [
        'https://images.unsplash.com/photo-1608889825205-eebdb9fc5806?q=80&w=800&auto=format&fit=crop',
      ],
      isFeatured: false,
    ),
  ];

  static const UserModel currentUser = UserModel(
    id: '',
    fullName: '',
    email: '',
    phone: '',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400&auto=format&fit=crop',
    rewardCoins: 0,
    children: [],
  );

  static final List<OrderModel> sampleOrders = [];

  static const AdminStatsModel adminStats = AdminStatsModel(
    totalRevenue: 428900.00,
    totalOrders: 1420,
    activeProducts: 185,
    registeredUsers: 3450,
    weeklySales: [12000, 18500, 24000, 31000, 28000, 42000, 54000],
    monthlyRevenue: [240000, 290000, 310000, 380000, 428900],
  );
}
