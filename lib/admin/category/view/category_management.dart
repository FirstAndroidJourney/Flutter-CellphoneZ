import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
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
        _errorMessage = 'Không thể tải danh mục: $e';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            parentId == null ? 'Thêm danh mục gốc' : 'Thêm danh mục con',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parentName != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cellphoneZRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cellphoneZRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder,
                        color: cellphoneZRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Danh mục cha: $parentName',
                          style: TextStyle(
                            fontSize: 14,
                            color: cellphoneZRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'Nhập tên danh mục...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cellphoneZRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _addCategory(name, parentId: parentId);
              },
              child: const Text('Thêm'),
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
          content: Text('Đã thêm danh mục "$name" thành công'),
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
          content: Text('Không thể thêm danh mục: $e'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Chỉnh sửa danh mục',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Tên danh mục',
              hintText: 'Nhập tên danh mục...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cellphoneZRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _editCategory(category.id, name);
              },
              child: const Text('Lưu'),
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
          content: Text('Đã cập nhật danh mục thành "$name"'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật danh mục: $e'),
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
                  leading: const Icon(Icons.add, color: cellphoneZRed),
                  title: const Text('Thêm danh mục con'),
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
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn có chắc muốn xóa danh mục "${category.title}"?'),
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
                          'Sẽ xóa cả ${category.subCategories!.length} danh mục con',
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
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCategory(category.id);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
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
          content: Text('Đã xóa danh mục thành công'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa danh mục: $e'),
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
                color: cellphoneZRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder,
                color: cellphoneZRed,
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
              '${category.subCategories!.length} danh mục con',
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
              color: const Color.fromARGB(255, 248, 226, 226),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.category_outlined,
              color: cellphoneZRed,
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
            'Không có danh mục con',
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
            color: cellphoneZRed.withOpacity(0.1),
            width: 3,
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 0),
        elevation: 1,
        color: const Color(0xFFFFF1F1),
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
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cellphoneZRed.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.arrow_right_alt_rounded,
              color: cellphoneZRed,
              size: 18,
            ),
          ),
          title: Text(
            category.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 18, color: cellphoneZRed),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 24,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(6, 6),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(-6, -6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/logo/CellphoneZ.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Quản lý danh mục',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cellphoneZRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _loadCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
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
                              size: 64, color: cellphoneZRed.withOpacity(0.7)),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có danh mục nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: cellphoneZRed,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showAddCategoryDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm danh mục đầu tiên'),
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
          ? FloatingActionButton(
              onPressed: () => _showAddCategoryDialog(),
              backgroundColor: cellphoneZRed,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
