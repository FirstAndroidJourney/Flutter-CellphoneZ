import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/category.dart';
import '../../../../models/product.dart';
import '../../../../services/category_service.dart';
import '../../../../services/product_service.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.product});

  final Product? product;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();

  bool _isAvailable = true;
  bool _isSubmitting = false;
  bool _loadingCategories = true;
  List<Category> _categories = const [];
  String? _selectedCategoryId;
  Uint8List? _pickedImageBytes;
  String? _pickedImageExtension;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(2) : '',
    );
    _descriptionController =
        TextEditingController(text: product?.description ?? '');
    _isAvailable = product?.isAvailable ?? true;
    _selectedCategoryId = product?.categoryId;
    _existingImageUrl = product?.imageUrl;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    try {
      final categories = await _categoryService.getAllCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
        if (_selectedCategoryId != null &&
            !_categories
                .any((category) => category.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categories = const [];
        _loadingCategories = false;
      });
      _showSnack('Không thể tải danh mục: $error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isSubmitting) const LinearProgressIndicator(),
            if (_isSubmitting) const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên sản phẩm',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tên sản phẩm không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Giá bán',
                suffixText: 'đ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá bán';
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Giá bán phải lớn hơn 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trạng thái bán'),
              subtitle: Text(_isAvailable ? 'Đang bán' : 'Ngừng bán'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: Text(
                widget.product == null ? 'Tạo sản phẩm' : 'Cập nhật',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    if (_loadingCategories) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final options = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Không chọn danh mục'),
      ),
      ..._categories.map(
        (category) => DropdownMenuItem<String?>(
          value: category.id,
          child: Text(category.name),
        ),
      ),
    ];

    final hasSelected = _selectedCategoryId != null &&
        _categories.any((category) => category.id == _selectedCategoryId);

    return DropdownButtonFormField<String?>(
      key: ValueKey(hasSelected ? _selectedCategoryId : 'none'),
      initialValue: hasSelected ? _selectedCategoryId : null,
      decoration: const InputDecoration(
        labelText: 'Danh mục',
      ),
      items: options,
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);

    Widget preview;
    final placeholder = Container(
      height: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40),
      ),
    );

    if (_pickedImageBytes != null) {
      preview = SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.memory(
          _pickedImageBytes!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      preview = SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            final expected = progress.expectedTotalBytes;
            final value = expected != null && expected > 0
                ? progress.cumulativeBytesLoaded / expected
                : null;
            return Center(
              child: CircularProgressIndicator(value: value),
            );
          },
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    } else {
      preview = placeholder;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh sản phẩm',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: preview,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh'),
            ),
            if (_pickedImageBytes != null || _existingImageUrl != null)
              TextButton(
                onPressed: _isSubmitting ? null : _clearSelectedImage,
                child: const Text('Xoá ảnh'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageExtension = file.path.split('.').last.toLowerCase();
      _existingImageUrl = null;
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageExtension = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final parsedPrice =
        double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (parsedPrice == null || parsedPrice <= 0) {
      _showSnack('Giá bán không hợp lệ', isError: true);
      return;
    }

    ProductImagePayload? imagePayload;
    if (_pickedImageBytes != null && _pickedImageExtension != null) {
      imagePayload = ProductImagePayload(
        bytes: _pickedImageBytes!,
        extension: _pickedImageExtension!,
      );
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final description = _descriptionController.text.trim();

      if (widget.product == null) {
        await _productService.createProduct(
          name: _nameController.text.trim(),
          price: parsedPrice,
          isAvailable: _isAvailable,
          description: description.isEmpty ? null : description,
          categoryId: _selectedCategoryId,
          image: imagePayload,
        );

        if (!mounted) return;
        Navigator.of(context).pop('Đã tạo sản phẩm mới');
      } else {
        await _productService.updateProduct(
          current: widget.product!,
          name: _nameController.text.trim(),
          price: parsedPrice,
          isAvailable: _isAvailable,
          description: description.isEmpty ? null : description,
          categoryId: _selectedCategoryId,
          newImage: imagePayload,
        );

        if (!mounted) return;
        Navigator.of(context).pop('Đã cập nhật sản phẩm');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack('Không thể lưu sản phẩm: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}
