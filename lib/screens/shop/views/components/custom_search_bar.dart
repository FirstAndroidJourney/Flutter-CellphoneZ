import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? initialQuery;
  final String hintText;
  final bool showHistory;

  const CustomSearchBar({
    Key? key,
    required this.onSearch,
    this.initialQuery,
    this.hintText = 'Tìm kiếm sản phẩm...',
    this.showHistory = true,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _searchController;
  Timer? _debounceTimer;
  List<String> _searchHistory = [];
  bool _showHistory = false;
  final FocusNode _focusNode = FocusNode();
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 10;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _loadSearchHistory();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _searchHistory.isNotEmpty) {
        setState(() {
          _showHistory = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    if (!widget.showHistory) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    if (!widget.showHistory || query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove if already exists
      _searchHistory.remove(query);

      // Add to the beginning
      _searchHistory.insert(0, query);

      // Keep only max items
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
      }

      await prefs.setStringList(_historyKey, _searchHistory);
      setState(() {});
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      setState(() {
        _searchHistory.clear();
        _showHistory = false;
      });
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  Future<void> _removeHistoryItem(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory.remove(query);
      await prefs.setStringList(_historyKey, _searchHistory);
      setState(() {});
    } catch (e) {
      debugPrint('Error removing history item: $e');
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _saveSearchHistory(query);
        widget.onSearch(query);
        setState(() {
          _showHistory = false;
        });
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    _debounceTimer?.cancel();
    _saveSearchHistory(query);
    widget.onSearch(query);
    setState(() {
      _showHistory = false;
    });
    _focusNode.unfocus();
  }

  void _onHistoryItemSelected(String query) {
    _searchController.text = query;
    _onSearchSubmitted(query);
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearch('');
    setState(() {
      _showHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? primaryColor
                  : Colors.grey.shade300,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: SvgPicture.asset(
                  'assets/icons/Search.svg',
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade600,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                      color: Colors.grey.shade600,
                    )
                  : null,
            ),
          ),
        ),

        // Search History
        if (_showHistory && _searchHistory.isNotEmpty && widget.showHistory)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tìm kiếm gần đây',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      TextButton(
                        onPressed: _clearSearchHistory,
                        child: const Text('Xóa tất cả'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchHistory.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final query = _searchHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeHistoryItem(query),
                      ),
                      onTap: () => _onHistoryItemSelected(query),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
