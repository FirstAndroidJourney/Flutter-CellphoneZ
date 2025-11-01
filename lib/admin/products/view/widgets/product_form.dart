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
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();

  Product? _currentProduct;
  String _name = '';
  double? _price;
  String? _description;
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
    _currentProduct = product;
    _name = product?.name ?? '';
    _price = product?.price;
    _description = product?.description;
    _isAvailable = product?.isAvailable ?? true;
    _selectedCategoryId = product?.categoryId;
    _existingImageUrl = product?.imageUrl;
    _loadCategories();
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
    final sections = <Widget>[
      if (_isSubmitting) const LinearProgressIndicator(),
      _buildEditableField(
        title: 'Tên sản phẩm',
        value: _name.isEmpty ? 'Chưa nhập' : _name,
        onEdit: _isSubmitting ? null : _editName,
      ),
      const SizedBox(height: 12),
      _buildEditableField(
        title: 'Giá bán',
        value: _price != null ? _formatPrice(_price!) : 'Chưa nhập',
        onEdit: _isSubmitting ? null : _editPrice,
      ),
      const SizedBox(height: 12),
      _buildEditableField(
        title: 'Mô tả',
        value: (_description?.trim().isEmpty ?? true)
            ? 'Chưa nhập'
            : _description!.trim(),
        onEdit: _isSubmitting ? null : _editDescription,
      ),
      const SizedBox(height: 12),
      _buildCategorySection(),
      const SizedBox(height: 12),
      _buildAvailabilityTile(),
      const SizedBox(height: 16),
      _buildImageSection(),
      const SizedBox(height: 24),
      if (_currentProduct == null)
        FilledButton(
          onPressed: _isSubmitting ? null : _createProduct,
          child: const Text('Tạo sản phẩm'),
        ),
    ];

    return AbsorbPointer(
      absorbing: _isSubmitting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );
  }

  Widget _buildEditableField({
    required String title,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          value.isEmpty ? 'Chưa nhập' : value,
          style: const TextStyle(height: 1.3),
        ),
        trailing: IconButton(
          tooltip: 'Chỉnh sửa',
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_loadingCategories) {
      return const Card(
        child: ListTile(
          title: Text('Danh mục'),
          subtitle: Text('Đang tải...'),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final categoryName = _selectedCategoryId == null
        ? 'Không chọn'
        : _categories
                .firstWhere(
                  (category) => category.id == _selectedCategoryId,
                  orElse: () => const Category(
                    id: '',
                    name: 'Danh mục đã bị xoá',
                  ),
                )
                .name;

    return Card(
      child: ListTile(
        title: const Text('Danh mục'),
        subtitle: Text(categoryName),
        trailing: IconButton(
          tooltip: 'Chọn danh mục',
          icon: const Icon(Icons.edit),
          onPressed: _isSubmitting ? null : _selectCategory,
        ),
      ),
    );
  }

  Widget _buildAvailabilityTile() {
    return Card(
      child: SwitchListTile(
        title: const Text('Trạng thái bán'),
        subtitle: Text(_isAvailable ? 'Đang bán' : 'Ngừng bán'),
        value: _isAvailable,
        onChanged: _isSubmitting
            ? null
            : (value) async {
                setState(() {
                  _isAvailable = value;
                });
                await _persistExistingProduct();
              },
      ),
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

    final isNewProduct = _currentProduct == null;

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
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(isNewProduct ? 'Chọn ảnh' : 'Đổi ảnh'),
            ),
            const SizedBox(width: 12),
            if (isNewProduct &&
                (_pickedImageBytes != null || _existingImageUrl != null))
              TextButton(
                onPressed: _isSubmitting ? null : _clearSelectedImage,
                child: const Text('Xoá ảnh'),
              ),
          ],
        ),
        if (!isNewProduct)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Ảnh sẽ được cập nhật ngay khi bạn chọn ảnh mới.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tên sản phẩm'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên sản phẩm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      _showSnack('Tên sản phẩm không được để trống', isError: true);
      return;
    }

    setState(() {
      _name = trimmed;
    });
    await _persistExistingProduct();
  }

  Future<void> _editPrice() async {
    final controller =
        TextEditingController(text: _price?.toStringAsFixed(0) ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giá bán'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Nhập giá bán',
            suffixText: 'đ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final parsed = double.tryParse(result.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      _showSnack('Giá bán phải lớn hơn 0', isError: true);
      return;
    }

    setState(() {
      _price = parsed;
    });
    await _persistExistingProduct();
  }

  Future<void> _editDescription() async {
    final controller = TextEditingController(text: _description ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mô tả sản phẩm'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Nhập mô tả (có thể bỏ trống)',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final trimmed = result.trim();
    setState(() {
      _description = trimmed.isEmpty ? null : trimmed;
    });
    await _persistExistingProduct();
  }

  Future<void> _selectCategory() async {
    if (_loadingCategories) {
      await _loadCategories();
      if (!mounted) return;
      if (_loadingCategories) return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chọn danh mục'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('__none__'),
            child: const Text('Không chọn'),
          ),
          ..._categories.map(
            (category) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(category.id),
              child: Text(category.name),
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    final newCategoryId = result == '__none__' ? null : result;
    if (newCategoryId == _selectedCategoryId) {
      return;
    }

    setState(() {
      _selectedCategoryId = newCategoryId;
    });
    await _persistExistingProduct();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final extension = file.path.split('.').last.toLowerCase();

    if (_currentProduct == null) {
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageExtension = extension;
        _existingImageUrl = null;
      });
    } else {
      await _persistExistingProduct(
        imagePayload: ProductImagePayload(
          bytes: bytes,
          extension: extension,
        ),
      );
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageExtension = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _persistExistingProduct({
    ProductImagePayload? imagePayload,
  }) async {
    final current = _currentProduct;
    if (current == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updated = await _productService.updateProduct(
        current: current,
        name: _name.trim().isEmpty ? current.name : _name.trim(),
        price: _price ?? current.price,
        isAvailable: _isAvailable,
        description:
            (_description?.trim().isEmpty ?? true) ? null : _description!.trim(),
        categoryId: _selectedCategoryId,
        newImage: imagePayload,
      );

      if (!mounted) return;

      setState(() {
        _currentProduct = updated;
        _existingImageUrl = updated.imageUrl;
        if (imagePayload != null) {
          _pickedImageBytes = null;
          _pickedImageExtension = null;
        }
      });

      _showSnack('Đã cập nhật sản phẩm');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Không thể cập nhật sản phẩm: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createProduct() async {
    final trimmedName = _name.trim();
    if (trimmedName.isEmpty) {
      _showSnack('Vui lòng nhập tên sản phẩm', isError: true);
      return;
    }

    final price = _price;
    if (price == null || price <= 0) {
      _showSnack('Vui lòng nhập giá bán hợp lệ', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _productService.createProduct(
        name: trimmedName,
        price: price,
        isAvailable: _isAvailable,
        description:
            (_description?.trim().isEmpty ?? true) ? null : _description!.trim(),
        categoryId: _selectedCategoryId,
        image: _pickedImageBytes != null && _pickedImageExtension != null
            ? ProductImagePayload(
                bytes: _pickedImageBytes!,
                extension: _pickedImageExtension!,
              )
            : null,
      );

      if (!mounted) return;

      Navigator.of(context).pop('Đã tạo sản phẩm mới');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Không thể tạo sản phẩm: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatPrice(double value) {
    return '${value.toStringAsFixed(0)} đ';
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
