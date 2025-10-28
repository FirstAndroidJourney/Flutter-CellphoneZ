import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/category_chips.dart';
import 'components/flash_sale_section.dart';
import 'components/flagship_highlights.dart';
import 'components/hero_carousel.dart';
import 'components/news_and_services.dart';
import 'components/popular_products.dart';
import 'components/quick_actions.dart';
import 'components/recommendations_section.dart';
import 'components/support_footer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
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
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            SliverToBoxAdapter(child: CellphoneZQuickActions()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: CellphoneZCategoryChips()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: FlashSaleSection()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: PopularProducts()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            SliverToBoxAdapter(child: FlagshipHighlightsSection()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            SliverToBoxAdapter(child: RecommendationSection()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            SliverToBoxAdapter(child: NewsAndServicesSection()),
            SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
            const SliverToBoxAdapter(child: SupportFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding * 2)),
          ],
        ),
      ),
    );
  }
}
