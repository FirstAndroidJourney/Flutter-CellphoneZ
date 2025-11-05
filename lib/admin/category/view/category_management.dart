import 'package:flutter/material.dart';
import 'package:shop/services/category_service.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({Key? key}) : super(key: key);

  @override
  _CategoryManagementState createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String? _errorMessage;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final categoryTree = await _categoryService.getCategoryTree();

      final uiCategories = categoryTree.map((categoryWithChildren) {
        return _categoryService.convertToUiModel(
            categoryWithChildren.category, categoryWithChildren.children);
      }).toList();

      setState(() {
        _categories = uiCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load categories: $e';
      });
      debugPrint('Error loading categories: $e');
    }
  }

  void _showAddCategoryDialog({String? parentId, String? parentName}) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(parentId == null ? 'Add Root Category' : 'Add Subcategory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parentName != null) ...[
                Text(
                  'Parent: $parentName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter category name')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _addCategory(name, parentId: parentId);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCategory(String name, {String? parentId}) async {
    try {
      await _categoryService.createCategory(name, parentId: parentId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$name" added successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Auto-expand parent category if adding subcategory
      if (parentId != null) {
        setState(() {
          _expandedCategories.add(parentId);
        });
      }

      await _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add category: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final TextEditingController nameController =
        TextEditingController(text: category.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter category name')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _editCategory(category.id, name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editCategory(String id, String name) async {
    try {
      await _categoryService.updateCategory(id, name);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category updated to "$name"'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCategoryOptions(CategoryModel category, {required bool isRoot}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Only allow adding subcategory to root categories
              if (isRoot)
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.blue),
                  title: const Text('Add Subcategory'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCategoryDialog(
                      parentId: category.id,
                      parentName: category.title,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteCategoryDialog(category);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteCategoryDialog(CategoryModel category) {
    final hasChildren = category.subCategories?.isNotEmpty ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${category.title}"?'),
              if (hasChildren) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will also delete all ${category.subCategories!.length} subcategories',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCategory(category.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategoryTree(CategoryModel category, {required bool isRoot}) {
    final hasChildren = category.subCategories?.isNotEmpty ?? false;
    final isExpanded = _expandedCategories.contains(category.id);

    if (hasChildren && isRoot) {
      // Root category with children - use ExpansionTile
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            key: PageStorageKey(category.id),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedCategories.add(category.id);
                } else {
                  _expandedCategories.remove(category.id);
                }
              });
            },
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            title: Text(
              category.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${category.subCategories!.length} subcategories',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showCategoryOptions(category, isRoot: true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            children: category.subCategories!.map((subCategory) {
              return _buildSubCategoryItem(subCategory);
            }).toList(),
          ),
        ),
      );
    } else {
      // Root category without children
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.folder_outlined,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
          title: Text(
            category.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'No subcategories',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showCategoryOptions(category, isRoot: true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          onTap: () => _showCategoryOptions(category, isRoot: true),
        ),
      );
    }
  }

  Widget _buildSubCategoryItem(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.blue[200]!,
            width: 2,
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 0),
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(
              Icons.label,
              color: Colors.grey[700],
              size: 18,
            ),
          ),
          title: Text(
            category.title,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            onPressed: () => _showCategoryOptions(category, isRoot: false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          onTap: () => _showCategoryOptions(category, isRoot: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No categories yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddCategoryDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Category'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCategories,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryTree(
                            _categories[index],
                            isRoot: true,
                          );
                        },
                      ),
                    ),
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Root Category'),
            )
          : null,
    );
  }
}
