import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/location_service.dart';

final fetchedLocationProvider = StateNotifierProvider<FetchedLocationNotifier, String>((ref) {
  return FetchedLocationNotifier();
});

class FetchedLocationNotifier extends StateNotifier<String> {
  // Start with empty string so UI can show a prompt instead of wrong city
  FetchedLocationNotifier() : super('Tap to set location');

  bool _isFetching = false;

  /// Call this from a Widget with a valid BuildContext so we can show permission dialogs.
  Future<void> requestPermissionAndFetch(BuildContext context) async {
    if (_isFetching) return;
    state = 'Detecting location...';
    _isFetching = true;
    try {
      // 1. Request permission with in-app dialog guidance
      final granted = await LocationService.checkAndRequestPermission(context);
      if (!granted) {
        state = 'Location unavailable';
        return;
      }
      // 2. Fetch GPS
      await _doFetch();
    } finally {
      _isFetching = false;
    }
  }

  /// Silent background fetch (after permission already granted).
  Future<void> silentFetch() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Don't override state – user hasn't granted yet
      }
      await _doFetch();
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _doFetch() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        // Try Geoapify first (most accurate city name)
        final geoapifyRes = await LocationService.reverseGeocodeGeoapify(
            pos.latitude, pos.longitude);
        if (geoapifyRes != null && geoapifyRes['city'] != null) {
          final city = geoapifyRes['city']!;
          final stateName = geoapifyRes['state'] ?? '';
          state = stateName.isNotEmpty ? '$city, $stateName' : city;
          return;
        }

        // Fallback: device geocoding
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final area = p.subLocality?.isNotEmpty == true
              ? p.subLocality!
              : (p.locality ?? p.name ?? '');
          final city = p.locality ?? '';
          if (area.isNotEmpty && area != city && city.isNotEmpty) {
            state = '$area, $city';
          } else if (city.isNotEmpty) {
            state = city;
          } else if (area.isNotEmpty) {
            state = area;
          } else {
            state = 'Location found';
          }
        } else {
          state = 'Location found';
        }
      } else {
        state = 'Location unavailable';
      }
    } catch (e) {
      state = 'Location unavailable';
    }
  }

  void setCustomLocation(String newLoc) {
    state = newLoc;
  }
}
