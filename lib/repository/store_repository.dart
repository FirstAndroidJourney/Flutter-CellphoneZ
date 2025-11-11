import '../common/app_logger.dart';
import '../models/store.dart';
import '../services/database_schema.dart';
import 'base_repository.dart';

class StoreRepository extends BaseRepository {
  StoreRepository({AppLogger? logger})
      : _logger = logger ?? AppLogger.instance;

  final AppLogger _logger;

  @override
  String get tableName => storesSchema.table;

  Future<List<Store>> getStores({bool? isActive}) async {
    try {
      var builder = queryBuilder.select();
      if (isActive != null) {
        builder = builder.eq(storesSchema.isActive, isActive);
      }
      final response = await builder.order(storesSchema.name, ascending: true);
      return _parseStores(response);
    } catch (error, stackTrace) {
      _logger.e('Failed to fetch stores', error, stackTrace);
      throw Exception('Failed to fetch stores: $error');
    }
  }

  Future<Store> createStore(StoreDraft draft) async {
    try {
      final payload = draft.toPayload();
      final response = await create(payload);
      return Store.fromJson(response);
    } catch (error, stackTrace) {
      _logger.e('Failed to create store', error, stackTrace);
      throw Exception('Failed to create store: $error');
    }
  }

  Future<Store> updateStore(String id, StoreDraft draft) async {
    try {
      final payload = draft.toPayload();
      final response = await update(id, payload);
      return Store.fromJson(response);
    } catch (error, stackTrace) {
      _logger.e('Failed to update store $id', error, stackTrace);
      throw Exception('Failed to update store: $error');
    }
  }

  Future<Store> updateStoreStatus(String id, bool isActive) async {
    try {
      final response = await update(id, {
        storesSchema.isActive: isActive,
      });
      return Store.fromJson(response);
    } catch (error, stackTrace) {
      _logger.e('Failed to update store status for $id', error, stackTrace);
      throw Exception('Failed to update store status: $error');
    }
  }

  Future<void> deleteStore(String id) async {
    try {
      await delete(id);
    } catch (error, stackTrace) {
      _logger.e('Failed to delete store $id', error, stackTrace);
      throw Exception('Failed to delete store: $error');
    }
  }

  List<Store> _parseStores(dynamic response) {
    final data = List<Map<String, dynamic>>.from(response as List);
    return data.map(Store.fromJson).toList();
  }
}

class StoreDraft {
  StoreDraft({
    this.name,
    this.addressFull,
    this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.services,
    this.openingHours,
    this.isActive,
  });

  final String? name;
  final String? addressFull;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final List<String>? services;
  final Map<String, dynamic>? openingHours;
  final bool? isActive;

  static const _schema = StoresTable();

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{};

    void setField(String key, dynamic value) {
      if (value != null) {
        payload[key] = value;
      }
    }

    setField(_schema.name, name);
    setField(_schema.addressFull, addressFull);
    setField(_schema.city, city);
    setField(_schema.latitude, latitude);
    setField(_schema.longitude, longitude);
    setField(_schema.phone, phone);
    setField(_schema.services, services);
    setField(_schema.openingHours, openingHours);
    setField(_schema.isActive, isActive);

    return payload;
  }
}
