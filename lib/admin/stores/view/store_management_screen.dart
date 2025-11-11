import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../components/map_attribution_badge.dart';
import '../../../constants.dart';
import '../../../models/store.dart';
import '../../../services/map_style.dart';
import '../../../services/store_service.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final StoreService _storeService = StoreService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Store> _stores = [];
  Store? _selectedStore;
  latlng.LatLng? _pendingCoordinate;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    try {
      final stores = await _storeService.fetchStores(forceRefresh: true);
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách cửa hàng: $error')),
      );
    }
  }

  List<Store> get _filteredStores {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _stores;
    }
    return _stores.where((store) {
      return store.name.toLowerCase().contains(query) ||
          (store.city ?? '').toLowerCase().contains(query) ||
          store.addressFull.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _toggleStore(Store store, bool isActive) async {
    try {
      await _storeService.setStoreActive(store.id, isActive);
      await _loadStores();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trạng thái: $error')),
      );
    }
  }

  Future<void> _deleteStore(Store store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá cửa hàng'),
        content: Text('Bạn có chắc muốn xoá "${store.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: cellphoneZRed),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _storeService.deleteStore(store.id);
      await _loadStores();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xoá cửa hàng: $error')),
      );
    }
  }

  Future<void> _openStoreForm({Store? store}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StoreFormSheet(
        store: store,
        pendingCoordinate: _pendingCoordinate,
        onSubmit: (payload) async {
          if (store == null) {
            await _storeService.createStore(
              name: payload.name,
              addressFull: payload.address,
              latitude: payload.latitude,
              longitude: payload.longitude,
              city: payload.city,
              phone: payload.phone,
              services: payload.services,
              openingHours: payload.openingHours,
              isActive: payload.isActive,
            );
          } else {
            await _storeService.updateStore(
              store,
              name: payload.name,
              addressFull: payload.address,
              latitude: payload.latitude,
              longitude: payload.longitude,
              city: payload.city,
              phone: payload.phone,
              services: payload.services,
              openingHours: payload.openingHours,
              isActive: payload.isActive,
            );
          }
        },
      ),
    );

    if (result == true) {
      await _loadStores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Quản lý cửa hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStores,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(context)),
          _buildTopControls(context),
          _buildBottomSheet(context),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;
    final double topPadding = mediaTop;
    return Positioned(
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          child: _AdminSearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
            onAdd: () => _openStoreForm(),
            onRefresh: _loadStores,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.25,
      initialChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final stores = _filteredStores;
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
                child: stores.isEmpty
                    ? const Center(child: Text('Không có cửa hàng nào'))
                    : RefreshIndicator(
                        onRefresh: _loadStores,
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: stores.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final store = stores[index];
                            return _StoreCard(
                              store: store,
                              isSelected: _selectedStore?.id == store.id,
                              onSelect: () => _onSelectStore(store),
                              onEdit: () => _openStoreForm(store: store),
                              onDelete: () => _deleteStore(store),
                              onToggleActive: (value) =>
                                  _toggleStore(store, value),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context) {
    if (!MapStyleConfig.hasValidKey) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Text('Chưa cấu hình MAPTILER_API_KEY'),
        ),
      );
    }

    final markers = <Marker>[
      for (final store in _stores)
        Marker(
          width: 42,
          height: 42,
          point: latlng.LatLng(store.latitude, store.longitude),
          child: GestureDetector(
            onTap: () => _onSelectStore(store),
            child: Icon(
              Icons.location_on,
              color:
                  _selectedStore?.id == store.id ? cellphoneZRed : Colors.blue,
              size: _selectedStore?.id == store.id ? 40 : 30,
            ),
          ),
        ),
      if (_pendingCoordinate != null)
        Marker(
          width: 32,
          height: 32,
          point: _pendingCoordinate!,
          child: const Icon(
            Icons.push_pin,
            color: Colors.indigo,
            size: 28,
          ),
        ),
    ];

    final latlng.LatLng center;
    if (_selectedStore != null) {
      center =
          latlng.LatLng(_selectedStore!.latitude, _selectedStore!.longitude);
    } else if (_stores.isNotEmpty) {
      center = latlng.LatLng(_stores.first.latitude, _stores.first.longitude);
    } else {
      center = latlng.LatLng(10.762622, 106.660172);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: center,
            zoom: 12,
            interactiveFlags: InteractiveFlag.all,
            onTap: (tapPosition, point) => _handleMapTap(context, point),
          ),
          children: [
            TileLayer(
              urlTemplate: MapStyleConfig.rasterTileUrl(),
              userAgentPackageName: 'com.cellphonez.admin',
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

  void _handleMapTap(BuildContext context, latlng.LatLng point) {
    setState(() {
      _pendingCoordinate = point;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã chọn tọa độ (${point.latitude.toStringAsFixed(5)}, '
          '${point.longitude.toStringAsFixed(5)}) cho cửa hàng mới',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSelectStore(Store store) {
    setState(() {
      _selectedStore = store;
    });
    _mapController.move(
      latlng.LatLng(store.latitude, store.longitude),
      15,
    );
  }
}

class _AdminSearchBar extends StatelessWidget {
  const _AdminSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onAdd,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onAdd;
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
                  hintText: 'Tìm kiếm cửa hàng...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.text.isNotEmpty
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
            _RoundIconButton(
              icon: Icons.add_business,
              tooltip: 'Thêm cửa hàng',
              onTap: onAdd,
            ),
            const SizedBox(width: 8),
            _RoundIconButton(
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Store store;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? cellphoneZRed : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
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
                  Switch(
                    value: store.isActive,
                    onChanged: onToggleActive,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(store.addressFull),
              if (store.city != null) Text('Thành phố: ${store.city}'),
              if (store.phone != null) Text('Điện thoại: ${store.phone}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: store.services
                    .map(
                      (service) => Chip(
                        label: Text(service),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xoá'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreFormPayload {
  _StoreFormPayload({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.phone,
    this.services = const [],
    this.openingHours,
    this.isActive = true,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? phone;
  final List<String> services;
  final Map<String, dynamic>? openingHours;
  final bool isActive;
}

class _StoreFormSheet extends StatefulWidget {
  const _StoreFormSheet({
    required this.onSubmit,
    this.store,
    this.pendingCoordinate,
  });

  final Store? store;
  final latlng.LatLng? pendingCoordinate;
  final Future<void> Function(_StoreFormPayload payload) onSubmit;

  @override
  State<_StoreFormSheet> createState() => _StoreFormSheetState();
}

class _StoreFormSheetState extends State<_StoreFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _servicesController;
  late final TextEditingController _openingHoursController;
  bool _isActive = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    _nameController = TextEditingController(text: store?.name ?? '');
    _addressController =
        TextEditingController(text: store?.addressFull ?? '');
    _cityController = TextEditingController(text: store?.city ?? '');
    _phoneController = TextEditingController(text: store?.phone ?? '');
    _latitudeController = TextEditingController(
      text: (store?.latitude ??
              widget.pendingCoordinate?.latitude ??
              10.762622)
          .toString(),
    );
    _longitudeController = TextEditingController(
      text: (store?.longitude ??
              widget.pendingCoordinate?.longitude ??
              106.660172)
          .toString(),
    );
    _servicesController = TextEditingController(
      text: store?.services.join(', ') ?? '',
    );
    _openingHoursController = TextEditingController(
      text: store?.openingHours != null
          ? const JsonEncoder.withIndent('  ').convert(store!.openingHours)
          : '',
    );
    _isActive = store?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _servicesController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final services = _servicesController.text
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();

      Map<String, dynamic>? openingHours;
      if (_openingHoursController.text.trim().isNotEmpty) {
        openingHours = jsonDecode(_openingHoursController.text.trim())
            as Map<String, dynamic>;
      }

      await widget.onSubmit(
        _StoreFormPayload(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          services: services,
          openingHours: openingHours,
          isActive: _isActive,
        ),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu cửa hàng: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.store == null ? 'Thêm cửa hàng' : 'Chỉnh sửa cửa hàng',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Thành phố'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Vĩ độ'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          double.tryParse(value ?? '') == null
                              ? 'Sai định dạng'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Kinh độ'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          double.tryParse(value ?? '') == null
                              ? 'Sai định dạng'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servicesController,
                decoration: const InputDecoration(
                  labelText: 'Dịch vụ (phân cách bằng dấu phẩy)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _openingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Opening hours (JSON)',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Đang hoạt động'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cellphoneZRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.store == null ? 'Thêm mới' : 'Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
