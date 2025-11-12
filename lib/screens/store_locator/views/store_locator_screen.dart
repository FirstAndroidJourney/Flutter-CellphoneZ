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
  final PageController _storeSliderController =
      PageController(viewportFraction: 0.88);

  Timer? _searchDebounce;
  bool _isAnimatingSlider = false;
  int _currentSliderIndex = 0;

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
    _storeSliderController.dispose();
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
                _syncSliderWithHighlight(state);
              },
              builder: (context, state) {
                if (state.isLoading && state.stores.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    Positioned.fill(child: _buildMap(state, cubit)),
                    _buildTopControls(context, state, cubit),
                    _buildStoreSlider(context, state, cubit),
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

  void _syncSliderWithHighlight(StoreLocatorState state) {
    final highlighted = state.highlightedStore;
    if (highlighted == null) {
      return;
    }
    if (!_storeSliderController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncSliderWithHighlight(state);
        }
      });
      return;
    }
    final index = state.filteredStores
        .indexWhere((store) => store.id == highlighted.id);
    if (index == -1 || index == _currentSliderIndex) {
      return;
    }

    _isAnimatingSlider = true;
    _currentSliderIndex = index;
    _storeSliderController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        )
        .whenComplete(() => _isAnimatingSlider = false);
  }

  Widget _buildStoreSlider(
    BuildContext context,
    StoreLocatorState state,
    StoreLocatorCubit cubit,
  ) {
    final bottomInset =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;
    final sliderHeight = widget.enableSelection ? 280.0 : 250.0;

    if (state.filteredStores.isEmpty) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: bottomInset,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Không tìm thấy cửa hàng phù hợp.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: sliderHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _storeSliderController,
                  physics: const BouncingScrollPhysics(),
                  padEnds: false,
                  onPageChanged: (index) {
                    _currentSliderIndex = index;
                    if (_isAnimatingSlider ||
                        index >= state.filteredStores.length) {
                      return;
                    }
                    cubit.highlightStore(state.filteredStores[index]);
                  },
                  itemCount: state.filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = state.filteredStores[index];
                    final isHighlighted =
                        state.highlightedStore?.id == store.id;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == state.filteredStores.length - 1 ? 16 : 8,
                      ),
                      child: _buildStoreCard(
                        context: context,
                        store: store,
                        state: state,
                        cubit: cubit,
                        isHighlighted: isHighlighted,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard({
    required BuildContext context,
    required Store store,
    required StoreLocatorState state,
    required StoreLocatorCubit cubit,
    required bool isHighlighted,
  }) {
    final borderRadius = BorderRadius.circular(20);
    final services = store.services.take(4).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: isHighlighted ? cellphoneZRed : Colors.grey.shade200,
          width: 1.2,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isHighlighted ? 0.15 : 0.05),
            blurRadius: isHighlighted ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  store.addressFull,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
                if (store.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    store.phone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
                if (services.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final service in services)
                        Chip(
                          label: Text(service),
                          backgroundColor: Colors.blueGrey.shade50,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (store.services.length > services.length)
                        Chip(
                          label: Text('+${store.services.length - services.length}'),
                          backgroundColor: Colors.blueGrey.shade50,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (store.distanceKm != null) ...[
                      Flexible(
                        flex: 3,
                        child: _DistanceBadge(distanceKm: store.distanceKm!),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                    ),
                    if (widget.enableSelection) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              cubit.selectStore(store);
                              Navigator.of(context).pop(store);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              backgroundColor: cellphoneZRed,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Chọn làm điểm lấy'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.distanceKm});

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final bool isFar = distanceKm >= 50;
    final Color accent = isFar ? Colors.orange : cellphoneZRed;
    final String formatted =
        distanceKm >= 100 ? distanceKm.toStringAsFixed(0) : distanceKm.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.12),
            accent.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$formatted km',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'cách bạn',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
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
