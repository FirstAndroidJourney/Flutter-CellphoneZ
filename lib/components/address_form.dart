import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddressForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController streetController;
  final TextEditingController wardController;
  final TextEditingController districtController;
  final TextEditingController cityController;

  const AddressForm({
    super.key,
    required this.formKey,
    required this.streetController,
    required this.wardController,
    required this.districtController,
    required this.cityController,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<String> _wards = [];
  String? _selectedProvinceName;
  int? _selectedProvinceCode;
  String? _selectedDistrictName;
  int? _selectedDistrictCode;
  String? _selectedWard;
  bool _loadingProvinces = false;
  bool _loadingDistricts = false;
  bool _loadingWards = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final resp = await http.get(Uri.parse('https://provinces.open-api.vn/api/?depth=1'));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body) as List;
        _provinces = data.map((e) => { 'code': e['code'], 'name': e['name'] }).toList();
      }
    } catch (_) {
      // ignore errors; keep list empty
    } finally {
      setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _fetchDistricts(int provinceCode) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _wards = [];
    });
    try {
      final resp = await http.get(Uri.parse('https://provinces.open-api.vn/api/p/$provinceCode?depth=2'));
      if (resp.statusCode == 200) {
        final Map data = json.decode(resp.body) as Map;
        final List districts = data['districts'] as List;
        // keep code and name for each district
        _districts = districts.map((d) => {'code': d['code'], 'name': d['name']}).toList();
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _fetchWards(int districtCode) async {
    setState(() {
      _loadingWards = true;
      _wards = [];
    });
    try {
      final resp = await http.get(Uri.parse('https://provinces.open-api.vn/api/d/$districtCode?depth=2'));
      if (resp.statusCode == 200) {
        final Map data = json.decode(resp.body) as Map;
        final List wards = data['wards'] as List;
        _wards = wards.map((w) => w['name'] as String).toList();
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingWards = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Province dropdown (first)
          _loadingProvinces
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedProvinceName,
                  decoration: const InputDecoration(
                    labelText: 'Tỉnh/Thành phố',
                    border: OutlineInputBorder(),
                  ),
                  items: _provinces.map((p) => DropdownMenuItem<String>(
                        value: p['name'] as String,
                        child: Text(p['name'] as String),
                      )).toList(),
                  onChanged: (v) {
                    final selected = _provinces.firstWhere((p) => p['name'] == v);
                    setState(() {
                      _selectedProvinceName = v;
                      _selectedProvinceCode = selected['code'] as int;
                      widget.cityController.text = v ?? '';
                      _selectedDistrictName = null;
                      _selectedDistrictCode = null;
                      widget.districtController.text = '';
                      _selectedWard = null;
                      widget.wardController.text = '';
                    });
                    if (_selectedProvinceCode != null) {
                      _fetchDistricts(_selectedProvinceCode!);
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn tỉnh/thành' : null,
                ),
          const SizedBox(height: 16),
          // District dropdown
          _loadingDistricts
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedDistrictName,
                  decoration: const InputDecoration(
                    labelText: 'Quận/Huyện',
                    border: OutlineInputBorder(),
                  ),
                  items: _districts.map((d) => DropdownMenuItem<String>(value: d['name'] as String, child: Text(d['name'] as String))).toList(),
                  onChanged: (v) {
                    final selected = _districts.firstWhere((d) => d['name'] == v);
                    setState(() {
                      _selectedDistrictName = v;
                      _selectedDistrictCode = selected['code'] as int;
                      widget.districtController.text = v ?? '';
                      _selectedWard = null;
                      widget.wardController.text = '';
                    });
                    if (_selectedDistrictCode != null) {
                      _fetchWards(_selectedDistrictCode!);
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn quận/huyện' : null,
                ),
          const SizedBox(height: 16),
          // Ward dropdown
          _loadingWards
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedWard,
                  decoration: const InputDecoration(
                    labelText: 'Phường/Xã',
                    border: OutlineInputBorder(),
                  ),
                  items: _wards.map((w) => DropdownMenuItem<String>(value: w, child: Text(w))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedWard = v;
                      widget.wardController.text = v ?? '';
                    });
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn phường/xã' : null,
                ),
          const SizedBox(height: 16),
          // Street / house input last
          TextFormField(
            controller: widget.streetController,
            decoration: const InputDecoration(
              labelText: 'Số nhà, Tên đường',
              hintText: 'Ví dụ: 123 Nguyễn Văn A',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập địa chỉ' : null,
          ),
        ],
      ),
    );
  }
}