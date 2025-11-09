import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../network_image_with_loader.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.press,
    this.discountPercent,
    this.priceAfterDiscount,
  });

  factory ProductCard.fromProduct({
    required Product product,
    required VoidCallback onPressed,
    int? discountPercent,
    double? priceAfterDiscount,
  }) {
    return ProductCard(
      product: product,
      press: onPressed,
      discountPercent: discountPercent,
      priceAfterDiscount: priceAfterDiscount,
    );
  }

  final Product product;
  final VoidCallback press;
  final int? discountPercent;
  final double? priceAfterDiscount;

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        product.imageUrl ?? "https://placehold.co/600x400?text=No+Image";
    final String name = product.name;
    final double productPrice = product.price;

    // Format VNĐ
    final formatCurrency =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return GestureDetector(
      onTap: press,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: NetworkImageWithLoader(
                      fit: BoxFit.fitWidth,
                      imageUrl,
                      radius: 0,
                    ),
                  ),
                ),
                if (discountPercent != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 15, height: 1.2),
                    ),
                    const Spacer(),
                    if (priceAfterDiscount != null)
                      Row(
                        children: [
                          Text(
                            formatCurrency.format(priceAfterDiscount),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatCurrency.format(productPrice),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        formatCurrency.format(productPrice),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
