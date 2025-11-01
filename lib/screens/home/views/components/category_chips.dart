import 'package:flutter/material.dart';

import '../../../../constants.dart';

class CellphoneZCategoryChips extends StatefulWidget {
  const CellphoneZCategoryChips({super.key});

  @override
  State<CellphoneZCategoryChips> createState() =>
      _CellphoneZCategoryChipsState();
}

class _CellphoneZCategoryChipsState extends State<CellphoneZCategoryChips> {
  final List<String> _categories = [
    "Điện thoại",
    "Laptop",
    "Tablet",
    "Đồng hồ",
    "Nhà thông minh",
    "Phụ kiện",
    "Ưu đãi hôm nay",
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text(
            "Danh mục nổi bật",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            children: List.generate(
              _categories.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right:
                      index == _categories.length - 1 ? 0 : defaultPadding / 2,
                ),
                child: ChoiceChip(
                  selected: _selected == index,
                  onSelected: (_) => setState(() => _selected = index),
                  backgroundColor: Colors.white,
                  selectedColor: cellphoneZRed,
                  label: Text(_categories[index]),
                  labelStyle: TextStyle(
                    color: _selected == index ? Colors.white : cellphoneZDark,
                    fontWeight:
                        _selected == index ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: _selected == index
                          ? cellphoneZRed
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
