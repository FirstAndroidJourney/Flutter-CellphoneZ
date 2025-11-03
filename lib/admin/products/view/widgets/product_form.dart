import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../constants.dart';
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

  List<_CategoryNode> _flattenCategories() {
    final map = <String?, List<Category>>{};
    for (final category in _categories) {
      map.putIfAbsent(category.parentId, () => []).add(category);
    }
    for (final entry in map.values) {
      entry.sort((a, b) => a.name.compareTo(b.name));
    }

    final result = <_CategoryNode>[];
    final visited = <String>{};

    void visit(String? parentId, int level) {
      final children = map[parentId];
      if (children == null) return;
      for (final child in children) {
        if (!visited.add(child.id)) continue;
        final hasChildren = (map[child.id]?.isNotEmpty ?? false);
        result.add(
          _CategoryNode(
            category: child,
            level: level,
            hasChildren: hasChildren,
          ),
        );
        visit(child.id, level + 1);
      }
    }

    visit(null, 0);

    // Handle any orphan categories (parent not present in list)
    for (final category in _categories) {
      if (visited.contains(category.id)) continue;
      final hasChildren = (map[category.id]?.isNotEmpty ?? false);
      visited.add(category.id);
      result.add(
        _CategoryNode(
          category: category,
          level: category.parentId == null ? 0 : 1,
          hasChildren: hasChildren,
        ),
      );
      visit(category.id, (category.parentId == null ? 0 : 1) + 1);
    }

    return result;
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
              activeColor: cellphoneZRed,
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
              style: FilledButton.styleFrom(
                backgroundColor: cellphoneZRed,
                foregroundColor: Colors.white,
              ),
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
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(cellphoneZRed),
          ),
        ),
      );
    }

    final options = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        alignment: Alignment.centerLeft,
        child: _CategoryDropdownTile(
          label: 'Không chọn danh mục',
          level: 0,
          isSubcategory: false,
          hasChildren: false,
        ),
      ),
      ..._flattenCategories().map(
        (node) => DropdownMenuItem<String?>(
          value: node.category.id,
          alignment: Alignment.centerLeft,
          child: _CategoryDropdownTile(
            label: node.category.name,
            level: node.level,
            isSubcategory: node.level > 0,
            hasChildren: node.hasChildren,
          ),
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
        helperText: 'Chọn danh mục cha và danh mục con (nếu có)',
      ),
      isExpanded: true,
      items: options,
      selectedItemBuilder: (context) {
        final tiles = [
          const _CategorySelectedTile(
            label: 'Không chọn danh mục',
            level: 0,
            isSubcategory: false,
          ),
          ..._flattenCategories().map(
            (node) => _CategorySelectedTile(
              label: node.category.name,
              level: node.level,
              isSubcategory: node.level > 0,
            ),
          ),
        ];
        return tiles;
      },
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
              child: CircularProgressIndicator(
                value: value,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(cellphoneZRed),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: cellphoneZRed,
                foregroundColor: Colors.white,
              ),
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh'),
            ),
            if (_pickedImageBytes != null || _existingImageUrl != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: cellphoneZRed,
                ),
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
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _CategoryDropdownTile extends StatelessWidget {
  const _CategoryDropdownTile({
    required this.label,
    required this.level,
    required this.isSubcategory,
    required this.hasChildren,
  });

  final String label;
  final int level;
  final bool isSubcategory;
  final bool hasChildren;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indent = level * 16.0;
    final background = isSubcategory
        ? cellphoneZRed.withOpacity(0.08)
        : colorScheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(isSubcategory ? 12 : 16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (indent > 0) SizedBox(width: indent),
          Icon(
            isSubcategory
                ? Icons.arrow_right_alt_rounded
                : Icons.category_outlined,
            size: 18,
            color: cellphoneZRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSubcategory ? FontWeight.w500 : FontWeight.w600,
                    color: Colors.black,
                  ),
            ),
          ),
          if (hasChildren)
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _CategorySelectedTile extends StatelessWidget {
  const _CategorySelectedTile({
    required this.label,
    required this.level,
    required this.isSubcategory,
  });

  final String label;
  final int level;
  final bool isSubcategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indent = level * 14.0;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (indent > 0) SizedBox(width: indent),
          if (isSubcategory)
            Icon(Icons.chevron_right, size: 16, color: cellphoneZRed),
          if (isSubcategory) const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSubcategory ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.black,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryNode {
  _CategoryNode({
    required this.category,
    required this.level,
    required this.hasChildren,
  });

  final Category category;
  final int level;
  final bool hasChildren;
}
