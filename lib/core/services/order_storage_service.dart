import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/order_model.dart';

class OrderStorageService {
  static const String _storageKey = 'guildclub_saved_orders_cache_v2';

  /// Load cached orders locally from device persistent storage
  static Future<List<OrderModel>> loadLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Save orders list to device persistent storage
  static Future<void> saveLocalOrders(List<OrderModel> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = orders.map((o) => o.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Add or update single order in local persistent cache
  static Future<List<OrderModel>> addOrUpdateLocalOrder(OrderModel order) async {
    try {
      final current = await loadLocalOrders();
      final idx = current.indexWhere((o) => o.id == order.id);
      List<OrderModel> updated;
      if (idx >= 0) {
        updated = [
          for (final o in current)
            if (o.id == order.id) order else o
        ];
      } else {
        updated = [order, ...current];
      }
      await saveLocalOrders(updated);
      return updated;
    } catch (_) {
      return [order];
    }
  }

  /// Update order status in local persistent cache
  static Future<void> updateLocalOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final current = await loadLocalOrders();
      final idx = current.indexWhere((o) => o.id == orderId);
      if (idx >= 0) {
        final existing = current[idx];
        final nowIso = DateTime.now().toIso8601String();
        final updatedHistory = Map<String, String>.from(existing.statusHistory);
        updatedHistory[newStatus.dbValue] = nowIso;
        final updated = existing.copyWith(
          status: newStatus,
          statusUpdatedAt: DateTime.now(),
          statusHistory: updatedHistory,
        );
        current[idx] = updated;
        await saveLocalOrders(current);
      }
    } catch (_) {}
  }
}
