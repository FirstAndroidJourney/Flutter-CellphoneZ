import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../constants.dart';

class FlashDeal {
  const FlashDeal({
    required this.title,
    required this.image,
    required this.price,
    required this.oldPrice,
    required this.discount,
    this.shippingNote,
  });

  final String title;
  final String image;
  final double price;
  final double oldPrice;
  final int discount;
  final String? shippingNote;
}

class FlashSaleSection extends StatefulWidget {
  const FlashSaleSection({super.key});

  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection> {
  late Duration _timeLeft;
  Timer? _timer;

  final List<FlashDeal> _deals = [
    FlashDeal(
      title: "iPhone 15 Pro Max 256GB",
      image: productDemoImg2,
      price: 28990000,
      oldPrice: 32990000,
      discount: 12,
      shippingNote: "Giao nhanh 2h",
    ),
    FlashDeal(
      title: "Samsung Galaxy Z Fold6",
      image: productDemoImg3,
      price: 40990000,
      oldPrice: 44990000,
      discount: 9,
    ),
    FlashDeal(
      title: "MacBook Pro 14\" M3 Pro",
      image: productDemoImg1,
      price: 51990000,
      oldPrice: 56990000,
      discount: 8,
      shippingNote: "Trả góp 0%",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timeLeft = const Duration(hours: 2, minutes: 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft.inSeconds <= 0) return;
      setState(() {
        _timeLeft = _timeLeft - const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Row(
            children: [
              Text(
                "Flash Sale",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: defaultPadding),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cellphoneZRed.withOpacity(.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _format(_timeLeft),
                  style: const TextStyle(
                    color: cellphoneZRed,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding / 2),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            itemCount: _deals.length,
            itemBuilder: (context, index) {
              final deal = _deals[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _deals.length - 1 ? 0 : defaultPadding / 1.5,
                ),
                child: _FlashSaleCard(deal: deal),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({required this.deal});

  final FlashDeal deal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: Colors.black.withOpacity(.07),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cellphoneZRed.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "-${deal.discount}%",
                    style: const TextStyle(
                      color: cellphoneZRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (deal.shippingNote != null)
                  Text(
                    deal.shippingNote!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cellphoneZDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: defaultPadding / 2),
            Expanded(
              child: Center(
                child: Image.network(
                  deal.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              deal.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "${deal.price.toStringAsFixed(0)} ₫",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cellphoneZRed,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              "${deal.oldPrice.toStringAsFixed(0)} ₫",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
