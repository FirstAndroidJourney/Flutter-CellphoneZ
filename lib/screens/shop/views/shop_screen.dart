import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/shop/blocs/product_list_bloc.dart';
import 'package:shop/screens/shop/blocs/product_list_event.dart';
import 'package:shop/screens/shop/blocs/product_list_state.dart';
import 'package:shop/screens/shop/views/components/category_filter.dart';
import 'package:shop/screens/shop/views/components/custom_search_bar.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductListBloc()..add(const LoadProducts()),
      child: const ShopScreenView(),
    );
  }
}

class ShopScreenView extends StatefulWidget {
  const ShopScreenView({Key? key}) : super(key: key);

  @override
  State<ShopScreenView> createState() => _ShopScreenViewState();
}

class _ShopScreenViewState extends State<ShopScreenView> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
              if (!_showSearch) {
                // Clear search when closing
                context.read<ProductListBloc>().add(const ClearFilters());
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (conditionally shown)
          if (_showSearch)
            CustomSearchBar(
              onSearch: (query) {
                if (query.trim().isEmpty) {
                  context.read<ProductListBloc>().add(const LoadProducts());
                } else {
                  context.read<ProductListBloc>().add(SearchProducts(query));
                }
              },
              hintText: 'Tìm kiếm sản phẩm...',
              showHistory: true,
            ),

          // Category Filter (hidden when searching)
          if (!_showSearch) ...[
            const CategoryFilter(),
            const Divider(height: 1),
          ],

          // Product List
          Expanded(
            child: BlocBuilder<ProductListBloc, ProductListState>(
              builder: (context, state) {
                if (state is ProductListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is ProductListError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: defaultPadding),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: defaultPadding),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<ProductListBloc>()
                                .add(const RefreshProducts());
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ProductListEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: defaultPadding),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: defaultPadding),
                        if (state.message.contains('danh mục'))
                          TextButton(
                            onPressed: () {
                              context
                                  .read<ProductListBloc>()
                                  .add(const ClearFilters());
                            },
                            child: const Text('Xem tất cả sản phẩm'),
                          ),
                      ],
                    ),
                  );
                }

                if (state is ProductListLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ProductListBloc>()
                          .add(const RefreshProducts());
                    },
                    child: CustomScrollView(
                      slivers: [
                        // Product count header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(defaultPadding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.products.length} sản phẩm',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (state.isFiltered)
                                  TextButton.icon(
                                    onPressed: () {
                                      context
                                          .read<ProductListBloc>()
                                          .add(const ClearFilters());
                                    },
                                    icon: const Icon(Icons.clear, size: 18),
                                    label: const Text('Xóa bộ lọc'),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Product Grid
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: defaultPadding,
                              mainAxisSpacing: defaultPadding,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return ProductCard(
                                  product: state.products[index],
                                  press: () {
                                    // Navigate to product detail
                                    // Navigator.pushNamed(
                                    //   context,
                                    //   productDetailsScreenRoute,
                                    //   arguments: state.products[index],
                                    // );
                                  },
                                );
                              },
                              childCount: state.products.length,
                            ),
                          ),
                        ),

                        // Bottom padding
                        const SliverToBoxAdapter(
                          child: SizedBox(height: defaultPadding),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
