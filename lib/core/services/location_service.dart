import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_typography.dart';
import '../theme/toyverse_theme.dart';

class LocationService {
  /// Request GPS permission and handle denied / permanently denied states with friendly in-app dialog.
  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        await _showEnableLocationDialog(context);
      }
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            title: 'Location Permission Needed 📍',
            message: 'Guild Club needs your location to detect your delivery address for accurate delivery.',
            isPermanent: false,
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          title: 'Location Access Disabled 🔒',
          message: 'Location access is permanently denied in settings. Please enable it in your device settings to auto-detect your delivery address.',
          isPermanent: true,
        );
      }
      return false;
    }

    return true;
  }

  /// Get exact high accuracy GPS position configured via .env
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return await Geolocator.getLastKnownPosition();

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      final timeoutSecs = int.tryParse(dotenv.env['GEOLOCATOR_TIMEOUT_SECONDS'] ?? '') ?? 8;
      final accuracySetting = (dotenv.env['GEOLOCATOR_ACCURACY'] ?? 'high').toLowerCase();

      LocationAccuracy accuracy = LocationAccuracy.high;
      if (accuracySetting == 'best') accuracy = LocationAccuracy.best;
      if (accuracySetting == 'medium') accuracy = LocationAccuracy.medium;

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(seconds: timeoutSecs),
        ),
      );
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Reverse geocode coordinates using Geoapify API if key is set in .env
  static Future<Map<String, String>?> reverseGeocodeGeoapify(double lat, double lng) async {
    final apiKey = dotenv.env['GEOAPIFY_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey.contains('your_geoapify_key')) return null;

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lng&apiKey=$apiKey');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final json = jsonDecode(stringData) as Map<String, dynamic>;
        final features = json['features'] as List<dynamic>?;

        if (features != null && features.isNotEmpty) {
          final props = features.first['properties'] as Map<String, dynamic>;
          final formatted = props['formatted']?.toString() ?? '';
          final city = props['city']?.toString() ?? props['county']?.toString() ?? props['state_district']?.toString() ?? '';
          final state = props['state']?.toString() ?? '';
          final postcode = props['postcode']?.toString() ?? '';

          if (formatted.isNotEmpty || city.isNotEmpty) {
            return {
              'formatted': formatted,
              'city': city,
              'state': state,
              'postalCode': postcode,
            };
          }
        }
      }
    } catch (e) {
      // Fallback to local placemarks
    }
    return null;
  }

  static Future<void> _showEnableLocationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: ToyVerseTheme.primaryOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enable GPS Location 🛰️',
                style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Location services are turned off. Please turn on GPS location on your phone to pinpoint your delivery pin.',
          style: AppTypography.bodyMedium.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyLarge.copyWith(color: ToyVerseTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryNavy),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text('Open Settings ⚙️', style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isPermanent,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(message, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppTypography.bodyLarge.copyWith(color: ToyVerseTheme.primaryNavy, fontWeight: FontWeight.bold)),
          ),
          if (isPermanent)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryNavy),
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: Text('App Settings ⚙️', style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  /// Geocoding resolver for Andhra Pradesh and Indian cities/districts when GPS coordinate is missing
  static ({double lat, double lng, String regionName}) resolveCityCoordinates(String addressText) {
    final text = addressText.toLowerCase();

    // Andhra Pradesh Major Cities & Districts
    if (text.contains('visakhapatnam') || text.contains('vizag')) {
      return (lat: 17.6868, lng: 83.2185, regionName: 'Visakhapatnam, Andhra Pradesh');
    }
    if (text.contains('vijayawada') || text.contains('amaravati')) {
      return (lat: 16.5062, lng: 80.6480, regionName: 'Vijayawada, Andhra Pradesh');
    }
    if (text.contains('guntur')) {
      return (lat: 16.3067, lng: 80.4365, regionName: 'Guntur, Andhra Pradesh');
    }
    if (text.contains('tirupati')) {
      return (lat: 13.6288, lng: 79.4192, regionName: 'Tirupati, Andhra Pradesh');
    }
    if (text.contains('nellore')) {
      return (lat: 14.4426, lng: 79.9865, regionName: 'Nellore, Andhra Pradesh');
    }
    if (text.contains('kurnool')) {
      return (lat: 15.8281, lng: 78.0373, regionName: 'Kurnool, Andhra Pradesh');
    }
    if (text.contains('kakinada')) {
      return (lat: 16.9891, lng: 82.2475, regionName: 'Kakinada, Andhra Pradesh');
    }
    if (text.contains('rajahmundry') || text.contains('rajamahendravaram')) {
      return (lat: 17.0005, lng: 81.8040, regionName: 'Rajahmundry, Andhra Pradesh');
    }
    if (text.contains('kadapa') || text.contains('cuddapah')) {
      return (lat: 14.4673, lng: 78.8241, regionName: 'Kadapa, Andhra Pradesh');
    }
    if (text.contains('anantapur')) {
      return (lat: 14.6819, lng: 77.6006, regionName: 'Anantapur, Andhra Pradesh');
    }
    if (text.contains('eluru')) {
      return (lat: 16.7107, lng: 81.0952, regionName: 'Eluru, Andhra Pradesh');
    }
    if (text.contains('ongole')) {
      return (lat: 15.5057, lng: 80.0499, regionName: 'Ongole, Andhra Pradesh');
    }
    if (text.contains('chittoor')) {
      return (lat: 13.2172, lng: 79.1003, regionName: 'Chittoor, Andhra Pradesh');
    }
    if (text.contains('srikakulam')) {
      return (lat: 18.2949, lng: 83.8938, regionName: 'Srikakulam, Andhra Pradesh');
    }
    if (text.contains('vizianagaram')) {
      return (lat: 18.1067, lng: 83.3956, regionName: 'Vizianagaram, Andhra Pradesh');
    }
    if (text.contains('machilipatnam')) {
      return (lat: 16.1875, lng: 81.1389, regionName: 'Machilipatnam, Andhra Pradesh');
    }
    if (text.contains('andhra') || text.contains(' a.p') || text.contains(' ap ')) {
      return (lat: 16.5062, lng: 80.6480, regionName: 'Andhra Pradesh');
    }

    // Other Indian Major Hubs
    if (text.contains('bengaluru') || text.contains('bangalore') || text.contains('karnataka')) {
      return (lat: 12.9716, lng: 77.5946, regionName: 'Bengaluru, Karnataka');
    }
    if (text.contains('chennai') || text.contains('tamil nadu')) {
      return (lat: 13.0827, lng: 80.2707, regionName: 'Chennai, Tamil Nadu');
    }
    if (text.contains('mumbai') || text.contains('maharashtra')) {
      return (lat: 19.0760, lng: 72.8777, regionName: 'Mumbai, Maharashtra');
    }
    if (text.contains('delhi') || text.contains('noida') || text.contains('gurgaon')) {
      return (lat: 28.7041, lng: 77.1025, regionName: 'Delhi NCR');
    }
    if (text.contains('pune')) {
      return (lat: 18.5204, lng: 73.8567, regionName: 'Pune, Maharashtra');
    }
    if (text.contains('kolkata') || text.contains('west bengal')) {
      return (lat: 22.5726, lng: 88.3639, regionName: 'Kolkata, West Bengal');
    }

    // Default to Hyderabad Store Hub if local / unknown
    return (lat: 17.5168, lng: 78.4735, regionName: 'Hyderabad, Telangana');
  }
}
