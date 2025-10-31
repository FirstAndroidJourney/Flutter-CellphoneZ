import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/category.dart';
import '../../../../models/product.dart';
import '../../../../services/category_service.dart';
import '../../../../services/product_service.dart' show ProductImagePayload;
import '../../bloc/product_admin_bloc.dart';

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
  final ImagePicker _picker = ImagePicker();

  bool _isAvailable = true;
  List<Category> _categories = const [];
  bool _loadingCategories = true;
  String? _selectedCategoryId;
  Uint8List? _pickedImageBytes;
  String? _pickedImageExtension;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    debugPrint(
      '[ProductForm] initState | productId=${product?.id ?? 'new'} | hasImage=${product?.imageUrl != null}',
    );
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
    debugPrint(
      '[ProductForm] dispose | productId=${widget.product?.id ?? 'new'}',
    );
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    debugPrint('[ProductForm] _loadCategories start');
    setState(() {
      _loadingCategories = true;
    });

    try {
      final categories = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
          if (_selectedCategoryId != null &&
              !_categories
                  .any((category) => category.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }
      debugPrint(
        '[ProductForm] _loadCategories success | count=${categories.length}',
      );
    } catch (error) {
      debugPrint('[ProductForm] _loadCategories error: $error');
      if (mounted) {
        setState(() {
          _categories = const [];
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    debugPrint('[ProductForm] _pickImage start');
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      debugPrint('[ProductForm] _pickImage cancelled');
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageExtension =
          file.path.split('.').last.toLowerCase();
      _existingImageUrl = null;
    });
    debugPrint(
      '[ProductForm] _pickImage success | extension=$_pickedImageExtension | bytes=${bytes.length}',
    );
  }

  void _clearSelectedImage() {
    debugPrint('[ProductForm] _clearSelectedImage');
    setState(() {
      _pickedImageBytes = null;
      _pickedImageExtension = null;
      _existingImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[ProductForm] build | productId=${widget.product?.id ?? 'new'} | categoriesLoaded=${_categories.isNotEmpty}',
    );
    return BlocBuilder<ProductAdminBloc, ProductAdminState>(
      builder: (context, state) {
        final isSubmitting =
            state.formStatus == ProductAdminFormStatus.submitting;

        return AbsorbPointer(
          absorbing: isSubmitting,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildFormContents(isSubmitting),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFormContents(bool isSubmitting) {
    return [
      if (isSubmitting) const LinearProgressIndicator(),
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
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: const InputDecoration(
          labelText: 'Giá bán',
          suffixText: 'đ',
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
      _buildCategoryDropdown(),
      const SizedBox(height: 16),
      SwitchListTile(
        value: _isAvailable,
        title: const Text('Trạng thái bán'),
        subtitle: Text(
          _isAvailable ? 'Đang bán' : 'Ngừng bán',
        ),
        onChanged: (value) {
          setState(() {
            _isAvailable = value;
          });
          debugPrint(
            '[ProductForm] availabilityChanged | isAvailable=$value',
          );
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
        onPressed: isSubmitting ? null : _handleSubmit,
        child: Text(
          widget.product == null ? 'Tạo sản phẩm' : 'Cập nhật',
        ),
      ),
    ];
  }

  Widget _buildCategoryDropdown() {
    if (_loadingCategories) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasSelectedCategory = _selectedCategoryId != null &&
        _categories.any((category) => category.id == _selectedCategoryId);

    final initialCategoryId =
        hasSelectedCategory ? _selectedCategoryId : null;

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

    return DropdownButtonFormField<String?>(
      key: ValueKey(initialCategoryId ?? 'null'),
      initialValue: initialCategoryId,
      items: options,
      decoration: const InputDecoration(
        labelText: 'Danh mục',
      ),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
        debugPrint(
          '[ProductForm] categoryChanged | selected=${value ?? 'none'}',
        );
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
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            final expected = loadingProgress.expectedTotalBytes;
            final progress = expected != null && expected > 0
                ? loadingProgress.cumulativeBytesLoaded / expected
                : null;
            return Center(
              child: CircularProgressIndicator(value: progress),
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
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh'),
            ),
            const SizedBox(width: 12),
            if (_pickedImageBytes != null || _existingImageUrl != null)
              TextButton(
                onPressed: _clearSelectedImage,
                child: const Text('Xoá ảnh'),
              ),
          ],
        ),
      ],
    );
  }

  void _handleSubmit() {
    debugPrint('[ProductForm] _handleSubmit start');
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      debugPrint('[ProductForm] _handleSubmit validation failed');
      return;
    }

    final parsedPrice =
        double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (parsedPrice == null || parsedPrice <= 0) {
      debugPrint(
        '[ProductForm] _handleSubmit invalid price="${_priceController.text}"',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá bán không hợp lệ')),
      );
      return;
    }

    ProductImagePayload? imagePayload;
    if (_pickedImageBytes != null && _pickedImageExtension != null) {
      imagePayload = ProductImagePayload(
        bytes: _pickedImageBytes!,
        extension: _pickedImageExtension!,
      );
    }

    final description = _descriptionController.text.trim();
    context.read<ProductAdminBloc>().add(
          ProductAdminSubmitted(
            existing: widget.product,
            input: ProductFormInput(
              name: _nameController.text.trim(),
              price: parsedPrice,
              isAvailable: _isAvailable,
              description: description.isEmpty ? null : description,
              categoryId: _selectedCategoryId,
              image: imagePayload,
            ),
          ),
        );
    debugPrint(
      '[ProductForm] _handleSubmit dispatched | productId=${widget.product?.id ?? 'new'}',
    );
  }
}
