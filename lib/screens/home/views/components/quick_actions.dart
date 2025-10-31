import 'package:flutter/material.dart';

import '../../../../constants.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.title,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
}

class CellphoneZQuickActions extends StatelessWidget {
  CellphoneZQuickActions({super.key});

  final List<QuickActionItem> _items = [
    const QuickActionItem(
      title: "Đặt lịch sửa",
      icon: Icons.build_outlined,
      accentColor: Color(0xFFFD9536),
    ),
    const QuickActionItem(
      title: "Tra cứu bảo hành",
      icon: Icons.verified_outlined,
      accentColor: Color(0xFF3DC2EC),
    ),
    const QuickActionItem(
      title: "Thu cũ đổi mới",
      icon: Icons.autorenew,
      accentColor: cellphoneZRed,
    ),
    const QuickActionItem(
      title: "Ưu đãi DN",
      icon: Icons.business_center_outlined,
      accentColor: Color(0xFF55E3A4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Row(
        children: [
          ...List.generate(
            _items.length,
            (index) {
              final item = _items[index];
              return Padding(
                padding: EdgeInsets.only(
                    right: index == _items.length - 1 ? 0 : defaultPadding / 2),
                child: _QuickActionButton(item: item),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.item});

  final QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cellphoneZGrey,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: item.onTap ?? () {},
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding / 1.5,
            vertical: defaultPadding / 1.2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.accentColor.withOpacity(.15),
                child: Icon(
                  item.icon,
                  color: item.accentColor,
                ),
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
