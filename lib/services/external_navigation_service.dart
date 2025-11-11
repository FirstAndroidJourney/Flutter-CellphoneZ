import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

enum ExternalMapProvider { googleMaps, mapTiler }

class ExternalNavigationService {
  ExternalNavigationService({
    ExternalMapProvider? provider,
  }) : _provider = provider ?? _resolveDefaultProvider();

  final ExternalMapProvider _provider;

  Future<void> openDirections({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String? label,
    ExternalMapProvider? overrideProvider,
  }) async {
    final provider = overrideProvider ?? _provider;
    final uri = switch (provider) {
      ExternalMapProvider.mapTiler => _mapTilerUri(
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          originLat: originLat,
          originLng: originLng,
        ),
      ExternalMapProvider.googleMaps => _googleMapsUri(
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          originLat: originLat,
          originLng: originLng,
          label: label,
        ),
    };

    if (!await canLaunchUrl(uri)) {
      throw Exception('Không thể mở ứng dụng bản đồ');
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static ExternalMapProvider _resolveDefaultProvider() {
    final raw = dotenv.env['MAP_DIRECTIONS_PROVIDER'] ?? 'google';
    switch (raw.toLowerCase()) {
      case 'maptiler':
      case 'map_tiler':
        return ExternalMapProvider.mapTiler;
      default:
        return ExternalMapProvider.googleMaps;
    }
  }

  Uri _googleMapsUri({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String? label,
  }) {
    final queryParameters = <String, String>{
      'api': '1',
      'destination':
          '$destinationLat,$destinationLng${label != null ? '($label)' : ''}',
      'travelmode': 'driving',
    };

    if (originLat != null && originLng != null) {
      queryParameters['origin'] = '$originLat,$originLng';
    }

    return Uri.https('www.google.com', '/maps/dir/', queryParameters);
  }

  Uri _mapTilerUri({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
  }) {
    final buffer = StringBuffer('https://www.maptiler.com/directions/?');
    if (originLat != null && originLng != null) {
      buffer.write(
          'start=${originLng.toStringAsFixed(6)},${originLat.toStringAsFixed(6)}&');
    }
    buffer.write(
        'end=${destinationLng.toStringAsFixed(6)},${destinationLat.toStringAsFixed(6)}');
    buffer.write('&travelMode=car');
    return Uri.parse(buffer.toString());
  }
}
