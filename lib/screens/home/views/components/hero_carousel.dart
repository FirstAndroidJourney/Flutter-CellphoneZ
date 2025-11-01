import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shop/components/dot_indicators.dart';

import '../../../../constants.dart';

class HeroBannerItem {
  const HeroBannerItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.description,
    required this.image,
    required this.gradient,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String description;
  final String image;
  final List<Color> gradient;
  final VoidCallback? onTap;
}

class CellphoneZHeroCarousel extends StatefulWidget {
  const CellphoneZHeroCarousel({super.key});

  @override
  State<CellphoneZHeroCarousel> createState() => _CellphoneZHeroCarouselState();
}

class _CellphoneZHeroCarouselState extends State<CellphoneZHeroCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  final List<HeroBannerItem> _items = [
    HeroBannerItem(
      title: "Flash Sale Z-Verse",
      subtitle: "Giảm 40%",
      badge: "Hàng chính hãng",
      description: "iPhone 15 Pro Max\nTrả góp 0% + quà 2.000k",
      image: productDemoImg2,
      gradient: [
        cellphoneZDark,
        const Color(0xFF2C0C10),
      ],
    ),
    HeroBannerItem(
      title: "Thu cũ đổi mới",
      subtitle: "Thêm đến 3 triệu",
      badge: "Trade-in",
      description: "Đổi máy cũ lên đời Galaxy Z Fold6\nHoàn tiền trong ngày",
      image: productDemoImg3,
      gradient: [
        const Color(0xFF330000),
        cellphoneZRed,
      ],
    ),
    HeroBannerItem(
      title: "Combo Workstation",
      subtitle: "Ưu đãi doanh nghiệp",
      badge: "Giao nhanh 2h",
      description: "MacBook Pro + Apple Care+\nGiảm thêm 10% khi mua kèm iPad",
      image: productDemoImg1,
      gradient: [
        const Color(0xFF102030),
        const Color(0xFF304760),
      ],
    ),
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.positions.isEmpty) return;
      _index = (_index + 1) % _items.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.only(
                  left: defaultPadding,
                  right: defaultPadding / 2,
                ),
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: item.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 12,
                          bottom: 0,
                          top: 0,
                          child: Image.network(
                            item.image,
                            fit: BoxFit.contain,
                            width: 140,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(defaultPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    item.badge.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: defaultPadding / 2),
                                Text(
                                  item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  item.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                ),
                                const SizedBox(height: defaultPadding / 1.2),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: cellphoneZDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  onPressed: item.onTap ?? () {},
                                  child: const Text("Mua ngay"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              _items.length,
              (index) => DotIndicator(
                isActive: index == _index,
                activeColor: cellphoneZRed,
                inActiveColor: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
