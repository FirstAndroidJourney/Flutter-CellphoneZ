import 'dart:collection';

import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../common/app_logger.dart';
import '../models/store.dart';
import '../repository/store_repository.dart';

class StoreService {
  StoreService({
    StoreRepository? storeRepository,
    AppLogger? logger,
    latlng.Distance? distance,
  })  : _storeRepository =
            storeRepository ?? GetIt.instance<StoreRepository>(),
        _logger = logger ?? AppLogger.instance,
        _distance = distance ?? const latlng.Distance();

  final StoreRepository _storeRepository;
  final AppLogger _logger;
  final latlng.Distance _distance;

  List<Store>? _cache;
  DateTime? _lastFetch;

  Future<List<Store>> fetchStores({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }

    final stores = await _storeRepository.getStores();
    _cache = stores;
    _lastFetch = DateTime.now();
    return stores;
  }

  List<Store> attachDistance({
    required List<Store> stores,
    latlng.LatLng? origin,
  }) {
    if (origin == null) {
      return stores;
    }

    return stores
        .map(
          (store) => store.copyWith(
            distanceKm: _distance.as(
              latlng.LengthUnit.Kilometer,
              latlng.LatLng(store.latitude, store.longitude),
              origin,
            ),
          ),
        )
        .toList();
  }

  List<Store> filterStores({
    required List<Store> stores,
    String query = '',
    latlng.LatLng? origin,
    Set<String>? requiredServices,
  }) {
    Iterable<Store> results = stores;
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isNotEmpty) {
      results = results.where(
        (store) =>
            store.name.toLowerCase().contains(normalizedQuery) ||
            (store.city ?? '').toLowerCase().contains(normalizedQuery) ||
            store.addressFull.toLowerCase().contains(normalizedQuery),
      );
    }

    if (requiredServices != null && requiredServices.isNotEmpty) {
      results = results.where(
        (store) =>
            requiredServices.every((service) => store.services.contains(service)),
      );
    }

    final sorted = results.toList()
      ..sort(
        (a, b) {
          final distanceA = a.distanceKm ?? double.infinity;
          final distanceB = b.distanceKm ?? double.infinity;
          return distanceA.compareTo(distanceB);
        },
      );

    return sorted;
  }

  bool isStoreOpenNow(Store store) {
    final hours = store.openingHours;
    if (hours == null || hours.isEmpty) {
      return true;
    }

    if (hours['open_now'] is bool) {
      return hours['open_now'] as bool;
    }

    final now = DateTime.now();
    final key = _weekdayKey(now.weekday);
    final dynamic segment = hours[key] ?? hours[_weekdayName(now.weekday)];

    if (segment == null) {
      return true;
    }

    if (segment is Map<String, dynamic>) {
      final open = (segment['open'] ?? segment['from']) as String?;
      final close = (segment['close'] ?? segment['to']) as String?;

      if (open == null || close == null) {
        return true;
      }

      final openTime = _parseTime(open, now);
      final closeTime = _parseTime(close, now);
      if (openTime == null || closeTime == null) {
        return true;
      }

      if (closeTime.isBefore(openTime)) {
        // Overnight shift
        return now.isAfter(openTime) || now.isBefore(closeTime);
      }

      return now.isAfter(openTime) && now.isBefore(closeTime);
    }

    if (segment is List) {
      return segment.any((entry) {
        if (entry is Map<String, dynamic>) {
          final open = entry['open'] as String?;
          final close = entry['close'] as String?;
          if (open == null || close == null) return false;
          final openTime = _parseTime(open, now);
          final closeTime = _parseTime(close, now);
          if (openTime == null || closeTime == null) return false;
          if (closeTime.isBefore(openTime)) {
            return now.isAfter(openTime) || now.isBefore(closeTime);
          }
          return now.isAfter(openTime) && now.isBefore(closeTime);
        }
        return false;
      });
    }

    return true;
  }

  Future<Store> createStore({
    required String name,
    required String addressFull,
    required double latitude,
    required double longitude,
    String? city,
    String? phone,
    List<String>? services,
    Map<String, dynamic>? openingHours,
    bool isActive = true,
  }) async {
    final draft = StoreDraft(
      name: name.trim(),
      addressFull: addressFull.trim(),
      city: city?.trim(),
      latitude: latitude,
      longitude: longitude,
      phone: phone?.trim(),
      services: services ?? const [],
      openingHours: openingHours,
      isActive: isActive,
    );

    final store = await _storeRepository.createStore(draft);
    await refreshCache();
    return store;
  }

  Future<Store> updateStore(
    Store store, {
    String? name,
    String? addressFull,
    String? city,
    double? latitude,
    double? longitude,
    String? phone,
    List<String>? services,
    Map<String, dynamic>? openingHours,
    bool? isActive,
  }) async {
    final draft = StoreDraft(
      name: name ?? store.name,
      addressFull: addressFull ?? store.addressFull,
      city: city ?? store.city,
      latitude: latitude ?? store.latitude,
      longitude: longitude ?? store.longitude,
      phone: phone ?? store.phone,
      services: services ?? store.services,
      openingHours: openingHours ?? store.openingHours,
      isActive: isActive ?? store.isActive,
    );

    final result = await _storeRepository.updateStore(store.id, draft);
    await refreshCache();
    return result;
  }

  Future<Store> setStoreActive(String id, bool isActive) async {
    final result = await _storeRepository.updateStoreStatus(id, isActive);
    await refreshCache();
    return result;
  }

  Future<void> deleteStore(String id) async {
    await _storeRepository.deleteStore(id);
    await refreshCache();
  }

  Future<List<Store>> refreshCache() async {
    _cache = await _storeRepository.getStores();
    _lastFetch = DateTime.now();
    return _cache!;
  }

  void clearCache() {
    _cache = null;
    _lastFetch = null;
  }

  UnmodifiableListView<String> availableServices(List<Store> stores) {
    final services = <String>{};
    for (final store in stores) {
      services.addAll(store.services);
    }

    final sorted = services.toList()..sort();
    return UnmodifiableListView(sorted);
  }

  String _weekdayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  DateTime? _parseTime(String value, DateTime reference) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return DateTime(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );
  }
}
