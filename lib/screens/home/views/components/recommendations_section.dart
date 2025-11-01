import 'package:flutter/material.dart';

import '../../../../constants.dart';

class RecommendationItem {
  const RecommendationItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class RecommendationSection extends StatelessWidget {
  RecommendationSection({super.key});

  final List<RecommendationItem> _items = const [
    RecommendationItem(
      title: "Chơi game",
      description: "90Hz+, Snapdragon mới nhất",
      icon: Icons.sports_esports_outlined,
    ),
    RecommendationItem(
      title: "Chụp ảnh",
      description: "Camera tele 5x, chống rung",
      icon: Icons.camera_alt_outlined,
    ),
    RecommendationItem(
      title: "Làm việc",
      description: "Pin 5000mAh, sạc 45W",
      icon: Icons.work_outline,
    ),
    RecommendationItem(
      title: "Học online",
      description: "Màn 11\", loa kép",
      icon: Icons.school_outlined,
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
            "Gợi ý theo nhu cầu",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _items.length - 1 ? 0 : defaultPadding / 2,
                ),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cellphoneZGrey),
                  ),
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.icon,
                        color: cellphoneZRed,
                      ),
                      const SizedBox(height: defaultPadding / 3),
                      Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
