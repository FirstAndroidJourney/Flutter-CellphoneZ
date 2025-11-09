import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/category_service.dart';
import 'components/category_chips.dart';
import 'components/category_products_section.dart';
import 'components/hero_carousel.dart';
import 'components/news_and_services.dart';
import 'components/popular_products.dart';
import 'components/quick_actions.dart';
import 'components/recommendations_section.dart';
import 'components/support_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _featuredCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedCategories();
  }

  Future<void> _loadFeaturedCategories() async {
    try {
      final categories = await _categoryService.getFeaturedCategories();
      if (mounted) {
        setState(() {
          _featuredCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              titleSpacing: defaultPadding,
              title: Row(
                children: [
                  Text(
                    "CellphoneZ",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cellphoneZRed,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.pushNamed(context, searchScreenRoute);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, cartScreenRoute);
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: CellphoneZHeroCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            SliverToBoxAdapter(child: CellphoneZQuickActions()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: CellphoneZCategoryChips()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: PopularProducts()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...(_featuredCategories.map((category) => SliverToBoxAdapter(
                    child: Column(
                      children: [
                        CategoryProductsSection(category: category),
                        const SizedBox(height: defaultPadding),
                      ],
                    ),
                  ))),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            SliverToBoxAdapter(child: RecommendationSection()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: NewsAndServicesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: SupportFooter()),
            const SliverToBoxAdapter(
                child: SizedBox(height: defaultPadding * 2)),
          ],
        ),
      ),
    );
  }
}
