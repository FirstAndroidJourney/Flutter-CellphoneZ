import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../constants.dart';

class LocationService {
  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'vi_VN',
      );

      if (placemarks.isEmpty) {
        return '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }

      final place = placemarks.first;
      final segments = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((segment) => segment != null && segment!.isNotEmpty).toList();

      if (segments.isEmpty) {
        return '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }

      return segments.join(', ');
    } catch (_) {
      return '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}';
    }
  }

  Future<LatLng> getCurrentLocation() async {
    final position = await _resolvePosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<latlng.LatLng> getCurrentLocationLatLng2() async {
    final position = await _resolvePosition();
    return latlng.LatLng(position.latitude, position.longitude);
  }

  double calculateShippingFee(LatLng source, LatLng destination) {
    final distanceMeters = Geolocator.distanceBetween(
      source.latitude,
      source.longitude,
      destination.latitude,
      destination.longitude,
    );

    final distanceKm = distanceMeters / 1000;
    const thresholdKm = 3.0;
    const surchargePerKm = 5000.0; // 5,000đ mỗi km bổ sung

    if (distanceKm <= thresholdKm) {
      return DEFAULT_SHIPPING_FEE;
    }

    final extraDistance = distanceKm - thresholdKm;
    return DEFAULT_SHIPPING_FEE + (extraDistance.ceil() * surchargePerKm);
  }

  Future<void> saveFavoriteAddress(String address) async {
    // TODO: Persist to Supabase or local storage
  }

  Future<List<String>> getFavoriteAddresses() async {
    // TODO: Retrieve from persistence layer
    return [];
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return Future.error('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
