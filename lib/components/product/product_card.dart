import 'package:flutter/material.dart';

import '../../constants.dart';
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
  
  /// Factory constructor để tạo ProductCard từ Product model
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
    // Sử dụng các giá trị từ Product model
    final String imageUrl = product.imageUrl ?? "https://placehold.co/600x400?text=No+Image";
    final String name = product.name;
    final double productPrice = product.price;
    
    // Trích xuất categoryId để làm brandName tạm thời
    final String brandName = product.categoryId; 

    return OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(140, 220),
          maximumSize: const Size(140, 220),
          padding: const EdgeInsets.all(8)),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: [
                NetworkImageWithLoader(imageUrl, radius: defaultBorderRadious),
                if (discountPercent != null)
                  Positioned(
                    right: defaultPadding / 2,
                    top: defaultPadding / 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding / 2),
                      height: 16,
                      decoration: const BoxDecoration(
                        color: errorColor,
                        borderRadius: BorderRadius.all(
                            Radius.circular(defaultBorderRadious)),
                      ),
                      child: Text(
                        "$discountPercent% off",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2, vertical: defaultPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandName.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontSize: 12),
                  ),
                  const Spacer(),
                  priceAfterDiscount != null
                      ? Row(
                          children: [
                            Text(
                              "\$$priceAfterDiscount",
                              style: const TextStyle(
                                color: Color(0xFF31B0D8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: defaultPadding / 4),
                            Text(
                              "\$$productPrice",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "\$$productPrice",
                          style: const TextStyle(
                            color: Color(0xFF31B0D8),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
