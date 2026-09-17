import 'product_model.dart';
import 'address_model.dart';
import '../core/services/location_service.dart';

enum OrderStatus {
  placed,
  preparing,
  dispatched,
  outForDelivery,
  delivered,
  cancelled;

  String get dbValue {
    switch (this) {
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.dispatched:
        return 'dispatched';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'Preparing & Packed';
      case OrderStatus.dispatched:
        return 'Dispatched from Hub';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.dispatched:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.placed;
    final clean = val.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (clean) {
      case 'preparing':
      case 'packed':
      case 'processing':
        return OrderStatus.preparing;
      case 'dispatched':
      case 'shipped':
        return OrderStatus.dispatched;
      case 'out_for_delivery':
      case 'outfordelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
      case 'completed':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'placed':
      default:
        return OrderStatus.placed;
    }
  }
}

class OrderItemModel {
  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;
  final ProductModel? product;

  OrderItemModel({
    String? productId,
    String? title,
    required this.quantity,
    double? unitPrice,
    this.imageUrl,
    this.product,
  })  : productId = productId ?? product?.id ?? 'p_1',
        title = title ?? product?.title ?? 'Product Item',
        unitPrice = unitPrice ?? product?.price ?? 0.0;

  double get totalPrice => quantity * unitPrice;

  factory OrderItemModel.fromJson(Map<String, dynamic> json, {ProductModel? resolvedProduct}) {
    return OrderItemModel(
      productId: json['product_id']?.toString() ?? json['productId']?.toString() ?? resolvedProduct?.id ?? 'p_1',
      title: json['title']?.toString() ?? resolvedProduct?.title ?? 'Product Item',
      quantity: (json['qty'] as num?)?.toInt() ?? (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['price'] as num?)?.toDouble() ?? (json['unitPrice'] as num?)?.toDouble() ?? resolvedProduct?.price ?? 0.0,
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? (resolvedProduct?.imageUrls.isNotEmpty == true ? resolvedProduct!.imageUrls.first : null),
      product: resolvedProduct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'title': title,
      'qty': quantity,
      'price': unitPrice,
      'image_url': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String? addressId;
  final AddressModel? address;
  final List<OrderItemModel> items;
  final double subtotal;
  final double total;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final OrderStatus status;
  final DateTime statusUpdatedAt;
  final Map<String, String> statusHistory;
  final String originLocation;
  final double originLat;
  final double originLng;
  final String? deliveryAddressText;
  final double? destinationLat;
  final double? destinationLng;
  final int etaMinutes;
  final String deliveryPartnerName;
  final String deliveryPartnerPhone;
  final DateTime createdAt;

  // Pricing breakdown fields (persisted to Supabase)
  final double gstAmount;
  final double deliveryFee;

  // Custom / Extended Fields
  final String? customOrderNumber;
  final double? customDiscountAmount;
  final String? customPaymentMethod;
  final bool giftWrapped;
  final String? giftNote;

  String get orderNumber => customOrderNumber ?? 'GC-${id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}';
  DateTime get orderDate => createdAt;
  double get totalAmount => total;
  double get discountAmount => customDiscountAmount ?? 0.0;
  double get shippingFee => deliveryFee;
  String get deliveryAddress => deliveryAddressText ?? address?.fullAddress ?? 'Default Delivery Address';
  String get paymentMethod => customPaymentMethod ?? (razorpayPaymentId != null ? 'Razorpay UPI / Card' : 'Online Payment');
  int get statusStepIndex => status.stepIndex;

  OrderModel({
    required this.id,
    String? userId,
    this.addressId,
    this.address,
    required this.items,
    double? subtotal,
    double? total,
    double? totalAmount,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.status = OrderStatus.placed,
    DateTime? statusUpdatedAt,
    Map<String, String>? statusHistory,
    String? originLocation,
    double? originLat,
    double? originLng,
    String? deliveryAddressText,
    double? destinationLat,
    double? destinationLng,
    int? etaMinutes,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    DateTime? createdAt,
    String? orderNumber,
    double? discountAmount,
    double? gstAmount,
    double? deliveryFee,
    String? paymentMethod,
    this.giftWrapped = false,
    this.giftNote,
  })  : userId = userId ?? 'user_guildclub_1',
        subtotal = subtotal ?? totalAmount ?? total ?? 0.0,
        total = total ?? totalAmount ?? subtotal ?? 0.0,
        createdAt = createdAt ?? DateTime.now(),
        statusUpdatedAt = statusUpdatedAt ?? createdAt ?? DateTime.now(),
        statusHistory = statusHistory ?? {
          'placed': (createdAt ?? DateTime.now()).toIso8601String(),
        },
        originLocation = originLocation ?? 'Essen Marvella apartments, A block, 410, Suchitra Rd, Sriram Nagar, Jeedimetla, Hyderabad, Telangana 500055 (Landmark: Post Office)',
        originLat = originLat ?? 17.5168,
        originLng = originLng ?? 78.4735,
        deliveryAddressText = deliveryAddressText ?? address?.fullAddress,
        destinationLat = destinationLat ?? address?.latitude,
        destinationLng = destinationLng ?? address?.longitude,
        etaMinutes = etaMinutes ?? (address?.city.toLowerCase().contains('hyderabad') == true ? 2880 : 10080),
        deliveryPartnerName = deliveryPartnerName ?? 'Alex (Guild Club Logistics)',
        deliveryPartnerPhone = deliveryPartnerPhone ?? '+91 98765 43210',
        customOrderNumber = orderNumber,
        gstAmount = gstAmount ?? 0.0,
        deliveryFee = deliveryFee ?? 0.0,
        customDiscountAmount = discountAmount,
        customPaymentMethod = paymentMethod;

  /// Returns true if destination is local to Hyderabad / Telangana
  bool get isLocalToHyderabad {
    final addrLower = (deliveryAddressText ?? address?.fullAddress ?? address?.city ?? '').toLowerCase();
    // Explicit check: if it mentions Andhra Pradesh or Andhra cities or outstation, it is not local to Hyderabad
    if (addrLower.contains('andhra') ||
        addrLower.contains(' a.p') ||
        addrLower.contains(' ap ') ||
        addrLower.contains('visakhapatnam') ||
        addrLower.contains('vizag') ||
        addrLower.contains('vijayawada') ||
        addrLower.contains('guntur') ||
        addrLower.contains('tirupati') ||
        addrLower.contains('nellore') ||
        addrLower.contains('kurnool') ||
        addrLower.contains('kakinada') ||
        addrLower.contains('rajahmundry') ||
        addrLower.contains('kadapa') ||
        addrLower.contains('anantapur') ||
        addrLower.contains('eluru') ||
        addrLower.contains('ongole') ||
        addrLower.contains('chittoor') ||
        addrLower.contains('srikakulam') ||
        addrLower.contains('vizianagaram') ||
        addrLower.contains('machilipatnam') ||
        addrLower.contains('bengaluru') ||
        addrLower.contains('bangalore') ||
        addrLower.contains('chennai') ||
        addrLower.contains('mumbai') ||
        addrLower.contains('delhi')) {
      return false;
    }
    return addrLower.contains('hyderabad') ||
        addrLower.contains('secunderabad') ||
        addrLower.contains('telangana') ||
        addrLower.contains('5000');
  }

  /// Accurate destination coordinate resolution for live tracking map & distance
  double get resolvedDestinationLat {
    if (destinationLat != null && destinationLat != 0.0 && !(destinationLat == 17.3850 && !isLocalToHyderabad)) {
      return destinationLat!;
    }
    if (address?.latitude != null && address!.latitude != 0.0 && !(address!.latitude == 17.3850 && !isLocalToHyderabad)) {
      return address!.latitude;
    }
    return LocationService.resolveCityCoordinates(deliveryAddress).lat;
  }

  double get resolvedDestinationLng {
    if (destinationLng != null && destinationLng != 0.0 && !(destinationLng == 78.4867 && !isLocalToHyderabad)) {
      return destinationLng!;
    }
    if (address?.longitude != null && address!.longitude != 0.0 && !(address!.longitude == 78.4867 && !isLocalToHyderabad)) {
      return address!.longitude;
    }
    return LocationService.resolveCityCoordinates(deliveryAddress).lng;
  }

  /// Human-readable delivery timeline description based on destination
  String get deliveryTimelineText => isLocalToHyderabad ? '2â€“3 Working Days' : '7â€“8 Working Days';

  /// Helper to get formatted timestamp for a given status step
  String? getStatusTimestamp(OrderStatus stage) {
    final rawIso = statusHistory[stage.dbValue];
    if (rawIso == null) return null;
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return null;
    }
  }

  /// Estimated arrival string based on Hyderabad local vs national delivery
  String get estimatedDeliveryFormatted {
    if (status == OrderStatus.delivered) {
      final deliveredTime = getStatusTimestamp(OrderStatus.delivered);
      return deliveredTime != null ? 'Delivered at $deliveredTime' : 'Delivered';
    }
    if (status == OrderStatus.cancelled) {
      return 'Order Cancelled';
    }
    final daysToAdd = isLocalToHyderabad ? 3 : 8;
    final targetDate = createdAt.add(Duration(days: daysToAdd)).toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${targetDate.day} ${months[targetDate.month - 1]}';
    return '$deliveryTimelineText (by $dateStr)';
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? addressId,
    AddressModel? address,
    List<OrderItemModel>? items,
    double? subtotal,
    double? total,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    OrderStatus? status,
    DateTime? statusUpdatedAt,
    Map<String, String>? statusHistory,
    String? originLocation,
    double? originLat,
    double? originLng,
    String? deliveryAddressText,
    double? destinationLat,
    double? destinationLng,
    int? etaMinutes,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    DateTime? createdAt,
    String? orderNumber,
    double? discountAmount,
    double? gstAmount,
    double? deliveryFee,
    String? paymentMethod,
    bool? giftWrapped,
    String? giftNote,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressId: addressId ?? this.addressId,
      address: address ?? this.address,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      status: status ?? this.status,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      originLocation: originLocation ?? this.originLocation,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      deliveryAddressText: deliveryAddressText ?? this.deliveryAddressText,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      createdAt: createdAt ?? this.createdAt,
      orderNumber: orderNumber ?? customOrderNumber,
      discountAmount: discountAmount ?? customDiscountAmount,
      gstAmount: gstAmount ?? this.gstAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      paymentMethod: paymentMethod ?? customPaymentMethod,
      giftWrapped: giftWrapped ?? this.giftWrapped,
      giftNote: giftNote ?? this.giftNote,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<ProductModel>? allProducts, AddressModel? resolvedAddress}) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems.map((itemMap) {
      final map = itemMap as Map<String, dynamic>;
      final pId = map['product_id']?.toString() ?? map['productId']?.toString();
      final pMatch = allProducts?.where((p) => p.id == pId).firstOrNull;
      return OrderItemModel.fromJson(map, resolvedProduct: pMatch);
    }).toList();

    final statusStr = json['status']?.toString();
    final parsedStatus = OrderStatus.fromString(statusStr);

    Map<String, String> parsedHistory = {};
    if (json['status_history'] is Map) {
      final hMap = json['status_history'] as Map;
      parsedHistory = hMap.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    final createdAtDt = json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now();
    final statusUpdatedAtDt = json['status_updated_at'] != null ? DateTime.parse(json['status_updated_at']) : createdAtDt;

    if (!parsedHistory.containsKey('placed')) {
      parsedHistory['placed'] = createdAtDt.toIso8601String();
    }
    if (!parsedHistory.containsKey(parsedStatus.dbValue)) {
      parsedHistory[parsedStatus.dbValue] = statusUpdatedAtDt.toIso8601String();
    }

    final embeddedAddressMap = json['address'] as Map<String, dynamic>?;
    final parsedEmbeddedAddress = embeddedAddressMap != null ? AddressModel.fromJson(embeddedAddressMap) : null;
    final effectiveAddress = resolvedAddress ?? parsedEmbeddedAddress;

    final deliveryAddressStr = json['delivery_address_text']?.toString() ??
        json['delivery_address']?.toString() ??
        effectiveAddress?.fullAddress ??
        '';

    final fallbackCoords = LocationService.resolveCityCoordinates(deliveryAddressStr);

    final destLat = (json['destination_lat'] as num?)?.toDouble() ??
        effectiveAddress?.latitude ??
        (deliveryAddressStr.isNotEmpty ? fallbackCoords.lat : 17.5168);

    final destLng = (json['destination_lng'] as num?)?.toDouble() ??
        effectiveAddress?.longitude ??
        (deliveryAddressStr.isNotEmpty ? fallbackCoords.lng : 78.4735);

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? 'user_guildclub_1',
      addressId: json['address_id']?.toString() ?? effectiveAddress?.id,
      address: effectiveAddress,
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      razorpayPaymentId: json['razorpay_payment_id']?.toString(),
      razorpayOrderId: json['razorpay_order_id']?.toString(),
      status: parsedStatus,
      statusUpdatedAt: statusUpdatedAtDt,
      statusHistory: parsedHistory,
      originLocation: json['origin_location']?.toString() ?? 'Essen Marvella apartments, A block, 410, Suchitra Rd, Sriram Nagar, Jeedimetla, Hyderabad, Telangana 500055 (Landmark: Post Office)',
      originLat: (json['origin_lat'] as num?)?.toDouble() ?? 17.5168,
      originLng: (json['origin_lng'] as num?)?.toDouble() ?? 78.4735,
      deliveryAddressText: deliveryAddressStr.isNotEmpty ? deliveryAddressStr : null,
      destinationLat: destLat,
      destinationLng: destLng,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 35,
      deliveryPartnerName: json['delivery_partner_name']?.toString() ?? 'Alex (Guild Club Logistics)',
      deliveryPartnerPhone: json['delivery_partner_phone']?.toString() ?? '+91 98765 43210',
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString(),
      createdAt: createdAtDt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      if (addressId != null) 'address_id': addressId,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'total': total,
      if (razorpayPaymentId != null && razorpayPaymentId!.isNotEmpty) 'razorpay_payment_id': razorpayPaymentId,
      if (razorpayOrderId != null && razorpayOrderId!.isNotEmpty) 'razorpay_order_id': razorpayOrderId,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
      'origin_location': originLocation,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'delivery_address_text': deliveryAddress,
      'destination_lat': destinationLat ?? resolvedDestinationLat,
      'destination_lng': destinationLng ?? resolvedDestinationLng,
      'gst_amount': gstAmount,
      'delivery_fee': deliveryFee,
      'discount_amount': customDiscountAmount ?? 0.0,
      'payment_method': customPaymentMethod ?? (razorpayPaymentId != null ? 'Razorpay UPI / Card' : 'Cash on Delivery'),
      'status_history': statusHistory,
      'status_updated_at': statusUpdatedAt.toIso8601String(),
      if (address != null) 'address': address!.toJson(),
    };
  }
}
