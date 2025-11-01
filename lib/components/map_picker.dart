import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPicker extends StatelessWidget {
  final LatLng initialLocation;
  final Set<Marker> markers;
  final Function(LatLng) onLocationSelected;

  const MapPicker({
    super.key,
    required this.initialLocation,
    required this.markers,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 15,
      ),
      markers: markers,
      onTap: onLocationSelected,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }
}