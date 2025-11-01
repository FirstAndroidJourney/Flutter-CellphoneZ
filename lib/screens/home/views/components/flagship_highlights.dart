import 'package:flutter/material.dart';

import '../../../../constants.dart';

class FlagshipHighlight {
  const FlagshipHighlight({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.image,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String price;
  final String image;
  final String badge;
}

class FlagshipHighlightsSection extends StatelessWidget {
  FlagshipHighlightsSection({super.key});

  final List<FlagshipHighlight> _items = const [
    FlagshipHighlight(
      title: "iPhone 15 Pro Max",
      subtitle: "Titan tự nhiên - 256GB",
      price: "Từ 28.990.000 ₫",
      image: productDemoImg2,
      badge: "Độc quyền CellphoneZ",
    ),
    FlagshipHighlight(
      title: "Galaxy S24 Ultra",
      subtitle: "AI Camera 200MP",
      price: "Từ 28.490.000 ₫",
      image: productDemoImg3,
      badge: "Quà 5.000.000 ₫",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text(
            "Top flagship",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: defaultPadding),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [cellphoneZDark, Colors.black87],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item.badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            item.subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                          ),
                          const Spacer(),
                          Text(
                            item.price,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: defaultPadding / 2),
                    Image.network(
                      item.image,
                      width: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
