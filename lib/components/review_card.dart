import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.rating,
    required this.numOfReviews,
    this.numOfFiveStar = 0,
    this.numOfFourStar = 0,
    this.numOfThreeStar = 0,
    this.numOfTwoStar = 0,
    this.numOfOneStar = 0,
  });

  final double rating;
  final int numOfReviews;
  final int numOfFiveStar,
      numOfFourStar,
      numOfThreeStar,
      numOfTwoStar,
      numOfOneStar;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.clamp(0.0, 5.0);

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.035),
        borderRadius:
            const BorderRadius.all(Radius.circular(defaultBorderRadious)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: "${normalizedRating.toStringAsFixed(1)} ",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: "/5",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Text("Based on $numOfReviews Reviews"),
                const SizedBox(height: defaultPadding),
                Row(
                  children: List.generate(
                    5,
                    (index) {
                      final starIndex = index + 1;
                      final isHalf = normalizedRating >= starIndex - 0.5 &&
                          normalizedRating < starIndex;
                      final isFilled = normalizedRating >= starIndex;
                      Color iconColor;
                      if (isFilled) {
                        iconColor = warningColor;
                      } else if (isHalf) {
                        iconColor = warningColor.withOpacity(0.6);
                      } else {
                        iconColor = Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.2);
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(right: defaultPadding / 4),
                        child: SvgPicture.asset(
                          "assets/icons/Star_filled.svg",
                          colorFilter:
                              ColorFilter.mode(iconColor, BlendMode.srcIn),
                          height: 20,
                          width: 20,
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              children: [
                RateBar(star: 5, value: numOfFiveStar / numOfReviews),
                RateBar(star: 4, value: numOfFourStar / numOfReviews),
                RateBar(star: 3, value: numOfThreeStar / numOfReviews),
                RateBar(star: 2, value: numOfTwoStar / numOfReviews),
                RateBar(star: 1, value: numOfOneStar / numOfReviews),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RateBar extends StatelessWidget {
  const RateBar({
    super.key,
    required this.star,
    required this.value,
  });

  final int star;
  final double value;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.isNaN || value.isInfinite
        ? 0.0
        : value.clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(bottom: star == 1 ? 0 : defaultPadding / 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$star Star",
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
          ),
          const SizedBox(width: defaultPadding / 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(defaultBorderRadious),
              ),
              child: LinearProgressIndicator(
                minHeight: 6,
                color: warningColor,
                backgroundColor: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .color!
                    .withOpacity(0.05),
                value: clampedValue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
