import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';

typedef ProductFormSubmit = Future<void> Function(ProductFormData data);

class ProductFormData {
  ProductFormData({
    this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.imageUrl,
    this.localImagePath,
    this.isAvailable = true,
    this.previousImageUrl,
  });

  final String? id;
  final String name;
  final double price;
  final String categoryId;
  final String? description;
  final String? imageUrl;
  final String? localImagePath;
  final bool isAvailable;
  final String? previousImageUrl;
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    this.product,
    required this.categories,
    required this.onSubmit,
  });

  final Product? product;
  final List<CategoryOption> categories;
  final ProductFormSubmit onSubmit;

  static Future<void> show(
    BuildContext context, {
    Product? product,
    required List<CategoryOption> categories,
    required ProductFormSubmit onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(
        product: product,
        categories: categories,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class CategoryOption {
  CategoryOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAvailable = true;
  String? _selectedCategoryId;
  String? _existingImageUrl;
  File? _pickedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(2);
      _descriptionController.text = product.description ?? '';
      _selectedCategoryId = product.categoryId;
      _existingImageUrl = product.imageUrl;
      _isAvailable = product.isAvailable;
    } else {
      _selectedCategoryId =
          widget.categories.isNotEmpty ? widget.categories.first.id : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      final price = double.parse(_priceController.text);
      await widget.onSubmit(
        ProductFormData(
          id: widget.product?.id,
          name: _nameController.text.trim(),
          price: price,
          categoryId: _selectedCategoryId!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          imageUrl: _pickedImage == null ? _existingImageUrl : null,
          localImagePath: _pickedImage?.path,
          isAvailable: _isAvailable,
          previousImageUrl: widget.product?.imageUrl,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Create Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories
                    .map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                      title: const Text('Available'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildImageSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final hasExisting = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;
    final hasPicked = _pickedImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (hasPicked)
          _ImagePreview(
            imageProvider: FileImage(_pickedImage!),
            onRemove: _removeImage,
          )
        else if (hasExisting)
          _ImagePreview(
            imageProvider: NetworkImage(_existingImageUrl!),
            onRemove: _removeImage,
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('No image selected'),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick Image'),
            ),
            const SizedBox(width: 12),
            if (hasPicked || hasExisting)
              TextButton(
                onPressed: _removeImage,
                child: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageProvider,
    required this.onRemove,
  });

  final ImageProvider imageProvider;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }
}
