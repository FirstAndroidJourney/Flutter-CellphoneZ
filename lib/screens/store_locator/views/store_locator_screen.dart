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
            extendBodyBehindAppBar: true,
            appBar: widget.showAppBar
                ? AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(widget.title ?? 'Tìm cửa hàng'),
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

                return Stack(
                  children: [
                    Positioned.fill(child: _buildMap(state, cubit)),
                    _buildTopControls(context, state, cubit),
                    _buildBottomSheet(context, state, cubit),
                    if (state.isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
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

  Widget _buildTopControls(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
  ) {
    final double topPadding = widget.showAppBar ? 0.0 : 12.0;
    return Positioned(
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchCard(
                controller: _searchController,
                state: state,
                onChanged: (value) => _onSearchChanged(value, cubit),
                onClear: () {
                  _searchController.clear();
                  cubit.updateSearch('');
                },
                onLocate: () => cubit.initialize(loadLocation: true),
                onRefresh: cubit.refresh,
              ),
              const SizedBox(height: 12),
              if (state.availableServices.isNotEmpty)
                _FilterCard(
                  state: state,
                  onToggleService: cubit.toggleService,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
  ) {
    return DraggableScrollableSheet(
      minChildSize: 0.2,
      initialChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: _buildStoreList(
                  context,
                  state,
                  cubit,
                  scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(StoreLocatorState state, StoreLocatorCubit cubit) {
    if (!MapStyleConfig.hasValidKey) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Text(
            'Chưa cấu hình MAPTILER_API_KEY.\nVui lòng cập nhật .env để hiển thị bản đồ.',
            textAlign: TextAlign.center,
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

    final center = state.userLocation ??
        (state.filteredStores.isNotEmpty
            ? latlng.LatLng(
                state.filteredStores.first.latitude,
                state.filteredStores.first.longitude,
              )
            : latlng.LatLng(10.762622, 106.660172));

    return Stack(
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
            MarkerLayer(markers: markers),
          ],
        ),
        const Positioned(
          bottom: 16,
          right: 16,
          child: MapAttributionBadge(),
        ),
      ],
    );
  }

  Widget _buildStoreList(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
    ScrollController scrollController,
  ) {
    if (state.filteredStores.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy cửa hàng phù hợp.'),
      );
    }

    return ListView.separated(
      controller: scrollController,
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
                  if (store.services.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: store.services
                          .map(
                            (service) => Chip(
                              label: Text(service),
                              backgroundColor: Colors.blueGrey.shade50,
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusBadge(isActive: store.isActive),
                      ),
                      const SizedBox(width: 12),
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

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.state,
    required this.onChanged,
    required this.onClear,
    required this.onLocate,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final StoreLocatorState state;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onLocate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, thành phố, địa chỉ...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClear,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _FloatingRoundButton(
              icon: Icons.my_location,
              tooltip: 'Định vị hiện tại',
              onTap: onLocate,
            ),
            const SizedBox(width: 8),
            _FloatingRoundButton(
              icon: Icons.refresh,
              tooltip: 'Làm mới',
              onTap: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.state,
    required this.onToggleService,
  });

  final StoreLocatorState state;
  final void Function(String service) onToggleService;

  @override
  Widget build(BuildContext context) {
    if (state.availableServices.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final service in state.availableServices) ...[
                FilterChip(
                  label: Text(service),
                  selected: state.selectedServices.contains(service),
                  onSelected: (_) => onToggleService(service),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color accent = isActive ? Colors.green : Colors.grey;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle_outline,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Đang hoạt động' : 'Tạm đóng',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRoundButton extends StatelessWidget {
  const _FloatingRoundButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: cellphoneZRed),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
