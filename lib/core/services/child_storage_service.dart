import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class ChildStorageService {
  static const String _storageKey = 'guildclub_saved_children_cache_v1';

  /// Load cached child profiles from device persistent local storage
  static Future<List<ChildProfileModel>> loadLocalChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => ChildProfileModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Save children profiles to device persistent local storage
  static Future<void> saveLocalChildren(List<ChildProfileModel> children) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = children.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Add or update a child profile in local storage
  static Future<List<ChildProfileModel>> addOrUpdateLocalChild(ChildProfileModel child) async {
    try {
      final currentList = await loadLocalChildren();
      final index = currentList.indexWhere((c) => c.id == child.id || (c.name.toLowerCase() == child.name.toLowerCase() && c.name.isNotEmpty));
      if (index != -1) {
        currentList[index] = child;
      } else {
        currentList.add(child);
      }
      await saveLocalChildren(currentList);
      return currentList;
    } catch (_) {
      return [child];
    }
  }

  /// Delete a child profile from local storage
  static Future<List<ChildProfileModel>> deleteLocalChild(String childId) async {
    try {
      final currentList = await loadLocalChildren();
      final updatedList = currentList.where((c) => c.id != childId).toList();
      await saveLocalChildren(updatedList);
      return updatedList;
    } catch (_) {
      return [];
    }
  }
}
