import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';
import '../../components/map_picker.dart';
import '../../components/address_form.dart';

class AddressPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialLocation;

  const AddressPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLocation,
  });

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _useManualInput = true;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // If an initial address or location was provided, populate fields
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _addressController.text = widget.initialAddress!;
      // try to split into components (street, ward, district, city)
      final parts =
          widget.initialAddress!.split(',').map((s) => s.trim()).toList();
      if (parts.isNotEmpty) _streetController.text = parts[0];
      if (parts.length > 1) _wardController.text = parts[1];
      if (parts.length > 2) _districtController.text = parts[2];
      if (parts.length > 3) _cityController.text = parts[3];
      _useManualInput = true;
    }

    if (widget.initialLocation != null) {
      _updateSelectedLocation(widget.initialLocation!);
      _useManualInput = false;
    }

    if (widget.initialAddress == null && widget.initialLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    _updateSelectedLocation(location);
  }

  void _updateSelectedLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Địa điểm giao hàng'),
        ),
      };
    });
    _updateAddress(location);
  }

  Future<void> _updateAddress(LatLng location) async {
    final address = await _locationService.getAddressFromLatLng(location);
    _addressController.text = address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
        actions: [
          TextButton(
            onPressed: () {
              if (_useManualInput) {
                if (_formKey.currentState!.validate()) {
                  final address = '${_streetController.text}, '
                      '${_wardController.text}, '
                      '${_districtController.text}, '
                      '${_cityController.text}';
                  Navigator.pop(
                      context, {'address': address, 'type': 'manual'});
                }
              } else if (_selectedLocation != null) {
                Navigator.pop(context, {
                  'address': _addressController.text,
                  'location': _selectedLocation!,
                  'type': 'map'
                });
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Toggle buttons for input method
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _useManualInput ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => setState(() => _useManualInput = true),
                      child: const Text('Nhập địa chỉ'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !_useManualInput ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => setState(() => _useManualInput = false),
                      child: const Text('Chọn trên bản đồ'),
                    ),
                  ),
                ],
              ),
            ),
            // Manual address input form
            if (_useManualInput)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AddressForm(
                  formKey: _formKey,
                  streetController: _streetController,
                  wardController: _wardController,
                  districtController: _districtController,
                  cityController: _cityController,
                ),
              ),
            // Map picker
            if (!_useManualInput)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _selectedLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : MapPicker(
                        initialLocation: _selectedLocation!,
                        markers: _markers,
                        onLocationSelected: _updateSelectedLocation,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
