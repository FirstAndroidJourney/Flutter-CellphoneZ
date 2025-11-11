import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapStyleConfig {
  static String get apiKey => dotenv.env['MAPTILER_API_KEY'] ?? '';

  static bool get hasValidKey => apiKey.isNotEmpty;

  static String rasterTileUrl({String style = 'streets-v2'}) {
    final key = apiKey;
    return 'https://api.maptiler.com/maps/$style/{z}/{x}/{y}.png?key=$key';
  }

  static String styleJsonUrl({String style = 'streets-v2'}) {
    final key = apiKey;
    return 'https://api.maptiler.com/maps/$style/style.json?key=$key';
  }

  static const String attribution =
      '© MapTiler © OpenStreetMap contributors';
}
