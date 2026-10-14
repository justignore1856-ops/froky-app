import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'user_location_hive.dart';
import '../../model/user_location/user_location_model.dart';

class LocationService {
  
  // In lib/utils/location/location_service.dart
  static Future<bool> ensureServiceAndPermission() async {
    bool servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      await Geolocator.openLocationSettings();
      servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      permission = await Geolocator.checkPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Checks if a string is a Google Plus Code (e.g., "J675+HJ6" or "87G8H7P8+FH")
  static bool isPlusCode(String? s) {
    if (s == null) return false;
    final trimmed = s.trim();
    return RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}$', caseSensitive: false).hasMatch(trimmed);
  }

  static String _cleanPart(String? s) {
    if (s == null) return '';
    final trimmed = s.trim();
    if (isPlusCode(trimmed)) return '';
    return trimmed;
  }

  static String _buildCleanFullAddress(Placemark p) {
    final street = _cleanPart(p.street);
    final subLocality = _cleanPart(p.subLocality);
    final locality = _cleanPart(p.locality);
    final adminArea = _cleanPart(p.administrativeArea);

    final parts = <String>[];
    for (final part in [street, subLocality, locality, adminArea]) {
      if (part.isNotEmpty && !parts.contains(part)) {
        parts.add(part);
      }
    }
    return parts.join(', ');
  }

  static String _resolveArea(Placemark p) {
    final sub = _cleanPart(p.subLocality);
    if (sub.isNotEmpty) return sub;
    final name = _cleanPart(p.name);
    if (name.isNotEmpty) return name;
    final street = _cleanPart(p.street);
    if (street.isNotEmpty) return street;
    return '';
  }

  static Future<UserLocation?> requestAndStoreLocationWithRetry() async {
    bool ready = await ensureServiceAndPermission();
    if (!ready) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 10)
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks[0] : const Placemark();
      final fullAddress = _buildCleanFullAddress(p);

      final userLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fullAddress: fullAddress.isEmpty ? "" : fullAddress,
        area: _resolveArea(p),
        city: _cleanPart(p.locality),
        state: _cleanPart(p.administrativeArea),
        country: p.country ?? '',
        pincode: p.postalCode ?? '',
        landmark: _cleanPart(p.name),
      );

      await HiveLocationHelper.setCurrentUserLocation(userLocation);
      return userLocation;
    } catch (_) {
      // One controlled retry
      final readyAgain = await ensureServiceAndPermission();
      if (!readyAgain) return null;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            timeLimit: Duration(seconds: 15),
          ),
        );
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        final p = placemarks.isNotEmpty ? placemarks[0] : const Placemark();
        final fullAddress = _buildCleanFullAddress(p);

        final userLocation = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          fullAddress: fullAddress.isEmpty ? "" : fullAddress,
          area: _resolveArea(p),
          city: _cleanPart(p.locality),
          state: _cleanPart(p.administrativeArea),
          country: p.country ?? '',
          pincode: p.postalCode ?? '',
          landmark: _cleanPart(p.name),
        );

        await HiveLocationHelper.setCurrentUserLocation(userLocation);
        return userLocation;
      } catch (_) {
        return null;
      }
    }
  }

  static Future<UserLocation?> storeLocationFromCoordinates(
      {required String latitude, required String longitude}) async {
    try {
      final double lat = double.tryParse(latitude) ?? 0.0;
      final double lng = double.tryParse(longitude) ?? 0.0;

      // Geocoding: Get address details from coordinates
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final p = placemarks.isNotEmpty ? placemarks[0] : const Placemark();
      final fullAddress = _buildCleanFullAddress(p);

      final userLocation = UserLocation(
        latitude: lat,
        longitude: lng,
        fullAddress: fullAddress.isEmpty ? "Default Location" : fullAddress,
        area: _resolveArea(p),
        city: _cleanPart(p.locality),
        state: _cleanPart(p.administrativeArea),
        country: p.country ?? '',
        pincode: p.postalCode ?? '',
        landmark: _cleanPart(p.name),
      );

      // Store the determined location
      await HiveLocationHelper.setCurrentUserLocation(userLocation);
      return userLocation;

    } catch (e) {
      // Handle any errors during parsing or geocoding
      log("Error storing location from coordinates: $e");
      return null;
    }
  }

  /// Get stored location from Hive
  static UserLocation? getStoredLocation() {
    return HiveLocationHelper.getCurrentUserLocation();
  }

  /// Check if location is stored
  static bool hasStoredLocation() {
    return getStoredLocation() != null;
  }

  /// Store a specific location in Hive
  static Future<void> storeLocation(UserLocation location) async {
    await HiveLocationHelper.setCurrentUserLocation(location);
    await HiveLocationHelper.addToRecentLocations(location);
  }
}
