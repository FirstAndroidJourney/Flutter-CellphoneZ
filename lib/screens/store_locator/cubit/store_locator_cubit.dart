import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../models/store.dart';
import '../../../services/location_service.dart';
import '../../../services/store_service.dart';
import 'store_locator_state.dart';

class StoreLocatorCubit extends Cubit<StoreLocatorState> {
  StoreLocatorCubit({
    StoreService? storeService,
    LocationService? locationService,
  })  : _storeService = storeService ?? StoreService(),
        _locationService = locationService ?? LocationService(),
        super(const StoreLocatorState());

  final StoreService _storeService;
  final LocationService _locationService;

  Future<void> initialize({bool loadLocation = true}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final stores = await _storeService.fetchStores();
      latlng.LatLng? position;

      if (loadLocation) {
        try {
          position = await _locationService.getCurrentLocationLatLng2();
        } catch (_) {
          position = null;
        }
      }

      final storesWithDistance =
          _storeService.attachDistance(stores: stores, origin: position);
      final filtered = _storeService.filterStores(
        stores: storesWithDistance,
        origin: position,
        requiredServices: state.selectedServices,
        query: state.searchQuery,
      );

      emit(
        state.copyWith(
          isLoading: false,
          stores: storesWithDistance,
          filteredStores: filtered,
          userLocation: position ?? state.userLocation,
          availableServices:
              _storeService.availableServices(storesWithDistance).toList(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void refresh() {
    _storeService.clearCache();
    initialize();
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  void toggleService(String service) {
    final updated = Set<String>.from(state.selectedServices);
    if (updated.contains(service)) {
      updated.remove(service);
    } else {
      updated.add(service);
    }

    emit(state.copyWith(selectedServices: updated));
    _applyFilters();
  }

  void highlightStore(Store store) {
    emit(state.copyWith(highlightedStore: store));
  }

  void selectStore(Store store) {
    emit(
      state.copyWith(
        selectedStore: store,
        highlightedStore: store,
      ),
    );
  }

  void clearSelection() {
    emit(state.copyWith(clearSelection: true, clearHighlight: true));
  }

  void setUserLocation(latlng.LatLng position) {
    emit(state.copyWith(userLocation: position));
    final storesWithDistance =
        _storeService.attachDistance(stores: state.stores, origin: position);
    emit(state.copyWith(stores: storesWithDistance));
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _storeService.filterStores(
      stores: state.stores,
      query: state.searchQuery,
      origin: state.userLocation,
      requiredServices: state.selectedServices,
    );

    emit(state.copyWith(filteredStores: filtered));
  }
}
