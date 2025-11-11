import 'package:flutter/material.dart';

import '../services/map_style.dart';

class MapAttributionBadge extends StatelessWidget {
  const MapAttributionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: Colors.black.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          MapStyleConfig.attribution,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
