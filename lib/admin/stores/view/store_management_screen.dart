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
      appBar: AppBar(
        title: const Text('Quản lý cửa hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStores,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStoreForm(),
        label: const Text('Thêm cửa hàng'),
        icon: const Icon(Icons.add_business),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm cửa hàng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                _buildMapSection(),
                Expanded(
                  child: _filteredStores.isEmpty
                      ? const Center(child: Text('Không có cửa hàng nào'))
                      : RefreshIndicator(
                          onRefresh: _loadStores,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _filteredStores.length,
                            itemBuilder: (context, index) {
                              final store = _filteredStores[index];
                              return _StoreCard(
                                store: store,
                                isSelected: _selectedStore?.id == store.id,
                                onSelect: () {
                                  setState(() {
                                    _selectedStore = store;
                                    _mapController.move(
                                      latlng.LatLng(
                                        store.latitude,
                                        store.longitude,
                                      ),
                                      15,
                                    );
                                  });
                                },
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
  }

  Widget _buildMapSection() {
    if (!MapStyleConfig.hasValidKey) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Chưa cấu hình MAPTILER_API_KEY'),
          ),
        ),
      );
    }

    final markers = _stores
        .map(
          (store) => Marker(
            width: 32,
            height: 32,
            point: latlng.LatLng(store.latitude, store.longitude),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedStore = store);
                _mapController.move(
                  latlng.LatLng(store.latitude, store.longitude),
                  15,
                );
              },
              child: Icon(
                Icons.location_on,
                color: store.isActive ? cellphoneZRed : Colors.grey,
                size: _selectedStore?.id == store.id ? 34 : 28,
              ),
            ),
          ),
        )
        .toList();

    final center = _selectedStore != null
        ? latlng.LatLng(_selectedStore!.latitude, _selectedStore!.longitude)
        : (markers.isNotEmpty
            ? markers.first.point
            : latlng.LatLng(10.762622, 106.660172));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
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
                      onTap: (tapPosition, point) {
                        setState(() {
                          _pendingCoordinate = point;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã chọn toạ độ (${point.latitude.toStringAsFixed(5)}, '
                              '${point.longitude.toStringAsFixed(5)}) cho cửa hàng mới',
                            ),
                          ),
                        );
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapStyleConfig.rasterTileUrl(),
                        userAgentPackageName: 'com.cellphonez.admin',
                      ),
                      MarkerLayer(markers: markers),
                      if (_pendingCoordinate != null)
                        MarkerLayer(markers: [
                          Marker(
                            width: 28,
                            height: 28,
                            point: _pendingCoordinate!,
                            child: const Icon(
                              Icons.push_pin,
                              color: Colors.indigo,
                            ),
                          )
                        ]),
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
          if (_pendingCoordinate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Toạ độ tạm: ${_pendingCoordinate!.latitude.toStringAsFixed(5)}, '
                '${_pendingCoordinate!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
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
