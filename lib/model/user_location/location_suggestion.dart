import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSuggestion {
  final LatLng? latLng;
  final String address;
  final String displayName;
  final String? placeId;

  LocationSuggestion({
    this.latLng,
    required this.address,
    required this.displayName,
    this.placeId,
  });
}
