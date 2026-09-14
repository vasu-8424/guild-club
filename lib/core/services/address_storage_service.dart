import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/address_model.dart';

class AddressStorageService {
  static const String _storageKey = 'guildclub_saved_addresses_cache_v2';

  /// Load single address cached locally in device persistent storage
  static Future<List<AddressModel>> loadLocalAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final list = decoded
            .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return [list.first];
        }
      }
    } catch (_) {}
    return [];
  }

  /// Save single address to device persistent storage
  static Future<void> saveLocalAddresses(List<AddressModel> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToSave = addresses.isNotEmpty ? [addresses.first] : <AddressModel>[];
      final jsonList = listToSave.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Add or update single address in device persistent storage
  static Future<List<AddressModel>> addOrUpdateLocalAddress(AddressModel address) async {
    try {
      final updatedList = [address];
      await saveLocalAddresses(updatedList);
      return updatedList;
    } catch (_) {
      return [address];
    }
  }

  /// Delete address by id from device persistent storage
  static Future<List<AddressModel>> deleteLocalAddress(String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      return [];
    } catch (_) {
      return [];
    }
  }
}
