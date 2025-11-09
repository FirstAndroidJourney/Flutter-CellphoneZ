import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/components/network_image_with_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ProductService _productService = ProductService();

  bool _isDropdownVisible = false;
  List<Product> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    // Auto focus when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showDropdown();
    }
  }

  void _showDropdown() {
    setState(() {
      _isDropdownVisible = true;
      if (_searchController.text.isEmpty) {
        _searchResults = [];
      }
    });
  }

  void _hideDropdown() {
    setState(() {
      _isDropdownVisible = false;
    });
  }

  Future<void> _onSearchChanged(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isDropdownVisible = _focusNode.hasFocus;
        _isSearching = false;
      });
      return;
    }

    // Show loading immediately
    setState(() {
      _isSearching = true;
      _isDropdownVisible = true;
    });

    // Debounce the search request
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
      try {
        // Generate slug from the query for searching
        final searchSlug = _generateSlug(query);

        // Search products by slug using the service
        final results = await _productService.searchProductsBySlug(searchSlug);

        if (mounted) {
          setState(() {
            _searchResults = results.take(8).toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _onSearchResultSelected(Product product) {
    _searchController.text = product.name;
    _hideDropdown();
    _focusNode.unfocus();

    Navigator.pushNamed(
      context,
      productDetailScreenRoute,
      arguments: product.id,
    );
  }

  void _onSearchSubmit(String query) async {
    if (query.trim().isEmpty) return;

    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    _focusNode.unfocus();
    _hideDropdown();

    // Generate slug from the query for search results
    final searchSlug = _generateSlug(query.trim());

    // Navigate to search results screen with the slug
    Navigator.pushNamed(
      context,
      searchResultsScreenRoute,
      arguments: {'query': searchSlug, 'searchText': query.trim()},
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmit,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.grey, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _onSearchSubmit(_searchController.text),
            child: Text(
              'Tìm',
              style: TextStyle(
                color: cellphoneZRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownResults() {
    if (!_isDropdownVisible) {
      return const SizedBox.shrink();
    }

    if (_isSearching) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(cellphoneZRed),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Không tìm thấy sản phẩm nào',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          return ListTile(
            dense: true,
            leading: SizedBox(
              width: 40,
              height: 40,
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: NetworkImageWithLoader(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              product.slug,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _onSearchResultSelected(product),
            trailing: const Icon(
              Icons.north_west,
              size: 16,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularSearches() {
    final popularSearches = [
      'iPhone 15',
      'Samsung Galaxy',
      'MacBook',
      'AirPods',
      'Gaming Laptop',
      'Wireless Charger',
      'Phone Case',
      'Bluetooth Speaker',
    ];

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: cellphoneZRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tìm kiếm phổ biến',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearchSubmit(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    search,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recentSearches = [
      'iPhone 15 Pro Max',
      'Samsung S24 Ultra',
      'MacBook Pro M3',
      'AirPods Pro 2',
    ];

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Clear recent searches
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa lịch sử tìm kiếm'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontSize: 14,
                    color: cellphoneZRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentSearches.map((search) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.history,
                color: Colors.grey.shade500,
                size: 18,
              ),
              title: Text(
                search,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.grey.shade500,
                  size: 18,
                ),
                onPressed: () {
                  // TODO: Remove this search from recent
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa "$search" khỏi lịch sử'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              onTap: () {
                _searchController.text = search;
                _onSearchSubmit(search);
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_isDropdownVisible) {
              _hideDropdown();
            }
          },
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: Stack(
                  children: [
                    // Main content (popular searches, recent searches)
                    if (!_isDropdownVisible) ...[
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildPopularSearches(),
                            const SizedBox(height: 8),
                            _buildRecentSearches(),
                          ],
                        ),
                      ),
                    ],

                    // Dropdown results overlay
                    if (_isDropdownVisible) ...[
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildDropdownResults(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
