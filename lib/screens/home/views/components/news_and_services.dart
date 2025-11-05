import 'package:flutter/material.dart';

import '../../../../constants.dart';

class NewsItem {
  const NewsItem({
    required this.title,
    required this.category,
    required this.timeLabel,
  });

  final String title;
  final String category;
  final String timeLabel;
}

class NewsAndServicesSection extends StatelessWidget {
  const NewsAndServicesSection({super.key});

  final List<NewsItem> _news = const [
    NewsItem(
      title: "So sánh iPhone 15 Pro vs 15 Pro Max – nên nâng cấp mẫu nào?",
      category: "Review",
      timeLabel: "5 phút trước",
    ),
    NewsItem(
      title: "Lịch mở bán Galaxy Z Fold6 tại CellphoneZ",
      category: "Tin khuyến mãi",
      timeLabel: "30 phút trước",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tin công nghệ & dịch vụ",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: defaultPadding / 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: cellphoneZGrey,
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: cellphoneZRed),
                const SizedBox(width: defaultPadding / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thu cũ đổi mới – thêm đến 3 triệu",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        "Định giá tại nhà, hoàn tiền trong 24h",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("Đăng ký"),
                ),
              ],
            ),
          ),
          const SizedBox(height: defaultPadding),
          ..._news.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: defaultPadding / 1.5),
              child: Container(
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cellphoneZGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cellphoneZRed.withOpacity(.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: cellphoneZRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.timeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(
                      item.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
