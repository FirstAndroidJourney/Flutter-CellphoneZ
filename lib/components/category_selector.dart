import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    this.onCategoryChanged,
    this.labelText = 'Danh mục',
    this.helperText = 'Chọn danh mục cha và danh mục con (nếu có)',
    this.allowEmpty = true,
    this.emptyLabel = 'Không chọn danh mục',
  });

  final String? selectedCategoryId;
  final ValueChanged<String?>? onCategoryChanged;
  final String labelText;
  final String helperText;
  final bool allowEmpty;
  final String emptyLabel;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  final CategoryService _categoryService = CategoryService();
  bool _loadingCategories = true;
  List<Category> _categories = const [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
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
      if (widget.allowEmpty)
        DropdownMenuItem<String?>(
          value: null,
          alignment: Alignment.centerLeft,
          child: _CategoryDropdownTile(
            label: widget.emptyLabel,
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
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
      ),
      isExpanded: true,
      items: options,
      selectedItemBuilder: (context) {
        final tiles = [
          if (widget.allowEmpty)
            _CategorySelectedTile(
              label: widget.emptyLabel,
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
        widget.onCategoryChanged?.call(value);
      },
    );
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
