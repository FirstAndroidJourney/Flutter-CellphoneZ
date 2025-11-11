import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../components/map_attribution_badge.dart';
import '../../../constants.dart';
import '../../../models/store.dart';
import '../../../services/external_navigation_service.dart';
import '../../../services/map_style.dart';
import '../cubit/store_locator_cubit.dart';
import '../cubit/store_locator_state.dart';

class StoreLocatorScreen extends StatefulWidget {
  const StoreLocatorScreen({
    super.key,
    this.enableSelection = true,
    this.initialSelection,
    this.showAppBar = true,
    this.title,
  });

  final bool enableSelection;
  final Store? initialSelection;
  final bool showAppBar;
  final String? title;

  static Future<Store?> push(BuildContext context) {
    return Navigator.of(context).push<Store>(
      MaterialPageRoute(
        builder: (_) => const StoreLocatorScreen(),
      ),
    );
  }

  @override
  State<StoreLocatorScreen> createState() => _StoreLocatorScreenState();
}

class _StoreLocatorScreenState extends State<StoreLocatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final ExternalNavigationService _navigationService =
      ExternalNavigationService();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _searchController.text = widget.initialSelection!.name;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, StoreLocatorCubit cubit) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      cubit.updateSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StoreLocatorCubit()..initialize(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<StoreLocatorCubit>();
          return Scaffold(
            appBar: widget.showAppBar
                ? AppBar(
                    title: Text(widget.title ?? 'Tìm cửa hàng'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        tooltip: 'Làm mới vị trí',
                        onPressed: () => cubit.initialize(loadLocation: true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Làm mới dữ liệu',
                        onPressed: cubit.refresh,
                      ),
                    ],
                  )
                : null,
            body: BlocConsumer<StoreLocatorCubit, StoreLocatorState>(
              listener: (context, state) {
                final target = state.highlightedStore;
                if (target != null) {
                  final targetPoint =
                      latlng.LatLng(target.latitude, target.longitude);
                  _mapController.move(targetPoint, 14);
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.stores.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    _buildSearchBar(context, state, cubit),
                    _buildFilters(context, state, cubit),
                    Expanded(
                      child: Column(
                        children: [
                          _buildMap(state, cubit),
                          Expanded(
                            child: _buildStoreList(context, state, cubit),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _onSearchChanged(value, cubit),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, thành phố, địa chỉ...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    cubit.updateSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Đang mở cửa'),
                selected: state.onlyOpenNow,
                onSelected: (_) => cubit.toggleOpenNow(),
              ),
              const SizedBox(width: 8),
              for (final service in state.availableServices) ...[
                FilterChip(
                  label: Text(service),
                  selected: state.selectedServices.contains(service),
                  onSelected: (_) => cubit.toggleService(service),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bán kính tìm kiếm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('${state.radiusKm.toStringAsFixed(0)} km'),
            ],
          ),
        ),
        Slider(
          value: state.radiusKm,
          min: 2,
          max: 50,
          divisions: 12,
          onChanged: (value) => cubit.updateRadius(value),
        ),
      ],
    );
  }

  Widget _buildMap(StoreLocatorState state, StoreLocatorCubit cubit) {
    if (!MapStyleConfig.hasValidKey) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'Chưa cấu hình MAPTILER_API_KEY.\nVui lòng cập nhật .env để hiển thị bản đồ.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final markers = <Marker>[
      for (final store in state.filteredStores)
        Marker(
          point: latlng.LatLng(store.latitude, store.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => cubit.highlightStore(store),
            child: AnimatedScale(
              scale: state.highlightedStore?.id == store.id ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.location_on,
                color: state.highlightedStore?.id == store.id
                    ? cellphoneZRed
                    : Colors.blueAccent,
                size: 32,
              ),
            ),
          ),
        ),
    ];

    if (state.userLocation != null) {
      markers.add(
        Marker(
          point: state.userLocation!,
          width: 32,
          height: 32,
          child: const Icon(
            Icons.my_location,
            color: Colors.green,
            size: 28,
          ),
        ),
      );
    }

    final circleMarkers = <CircleMarker>[
      if (state.userLocation != null)
        CircleMarker(
          point: state.userLocation!,
          radius: state.radiusKm * 1000,
          color: cellphoneZRed.withOpacity(0.08),
          borderColor: cellphoneZRed.withOpacity(0.2),
          borderStrokeWidth: 1,
        ),
    ];

    final center = state.userLocation ??
        (state.filteredStores.isNotEmpty
            ? latlng.LatLng(
                state.filteredStores.first.latitude,
                state.filteredStores.first.longitude,
              )
            : latlng.LatLng(10.762622, 106.660172));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: center,
                  zoom: 12,
                  interactiveFlags: InteractiveFlag.all,
                  onTap: (_, point) => cubit.setUserLocation(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapStyleConfig.rasterTileUrl(),
                    userAgentPackageName: 'com.cellphonez.app',
                  ),
                  if (circleMarkers.isNotEmpty)
                    CircleLayer(circles: circleMarkers),
                  MarkerLayer(markers: markers),
                ],
              ),
              const Positioned(
                bottom: 12,
                right: 12,
                child: MapAttributionBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreList(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
  ) {
    if (state.filteredStores.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy cửa hàng phù hợp.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.filteredStores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final store = state.filteredStores[index];
        final isHighlighted = state.highlightedStore?.id == store.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted ? cellphoneZRed : Colors.grey.shade200,
              width: 1.2,
            ),
            boxShadow: [
              if (isHighlighted)
                BoxShadow(
                  color: cellphoneZRed.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
            color: Colors.white,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => cubit.highlightStore(store),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (store.distanceKm != null)
                        Text(
                          '${store.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.addressFull,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (store.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      store.phone!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(
                          store.isActive ? 'Đang hoạt động' : 'Tạm đóng',
                          style: TextStyle(
                            color: store.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        backgroundColor:
                            store.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                      ),
                      if (store.services.isNotEmpty)
                        ...store.services.map(
                          (service) => Chip(
                            label: Text(service),
                            backgroundColor: Colors.blueGrey.shade50,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await _navigationService.openDirections(
                                destinationLat: store.latitude,
                                destinationLng: store.longitude,
                                originLat: state.userLocation?.latitude,
                                originLng: state.userLocation?.longitude,
                                label: store.name,
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Không thể mở ứng dụng bản đồ: $error',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Chỉ đường'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.enableSelection)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              cubit.selectStore(store);
                              Navigator.of(context).pop(store);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cellphoneZRed,
                            ),
                            child: const Text('Chọn làm điểm lấy'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
