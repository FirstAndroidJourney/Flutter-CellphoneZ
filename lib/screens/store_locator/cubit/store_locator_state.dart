import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../models/store.dart';

class StoreLocatorState extends Equatable {
  const StoreLocatorState({
    this.isLoading = false,
    this.errorMessage,
    this.stores = const [],
    this.filteredStores = const [],
    this.availableServices = const [],
    this.highlightedStore,
    this.selectedStore,
    this.userLocation,
    this.selectedServices = const <String>{},
    this.searchQuery = '',
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Store> stores;
  final List<Store> filteredStores;
  final List<String> availableServices;
  final Store? highlightedStore;
  final Store? selectedStore;
  final latlng.LatLng? userLocation;
  final Set<String> selectedServices;
  final String searchQuery;

  bool get hasError => errorMessage != null;

  StoreLocatorState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<Store>? stores,
    List<Store>? filteredStores,
    List<String>? availableServices,
    Store? highlightedStore,
    bool clearHighlight = false,
    Store? selectedStore,
    bool clearSelection = false,
    latlng.LatLng? userLocation,
    Set<String>? selectedServices,
    String? searchQuery,
  }) {
    return StoreLocatorState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      stores: stores ?? this.stores,
      filteredStores: filteredStores ?? this.filteredStores,
      availableServices: availableServices ?? this.availableServices,
      highlightedStore: clearHighlight ? null : (highlightedStore ?? this.highlightedStore),
      selectedStore: clearSelection ? null : (selectedStore ?? this.selectedStore),
      userLocation: userLocation ?? this.userLocation,
      selectedServices: selectedServices ?? this.selectedServices,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        stores,
        filteredStores,
        availableServices,
        highlightedStore,
        selectedStore,
        userLocation,
        selectedServices,
        searchQuery,
      ];
}
