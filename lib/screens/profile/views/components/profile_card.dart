import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/network_image_with_loader.dart';

import '../../../../constants.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.imageSrc,
    this.proLableText = "Pro",
    this.isPro = false,
    this.press,
    this.isShowHi = true,
    this.isShowArrow = true,
  });

  final String name, email, imageSrc;
  final String proLableText;
  final bool isPro, isShowHi, isShowArrow;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        child: NetworkImageWithLoader(
          imageSrc,
          radius: 100,
        ),
      ),
      title: Row(
        children: [
          Text(
            isShowHi ? "Hi, $name" : name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: defaultPadding / 2),
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2, vertical: defaultPadding / 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.all(Radius.circular(defaultBorderRadious)),
              ),
              child: Text(
                proLableText,
                style: const TextStyle(
                  fontFamily: grandisExtendedFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cellphoneZRed,
                  letterSpacing: 0.7,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        email,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: isShowArrow
          ? SvgPicture.asset(
              "assets/icons/miniRight.svg",
              color: Colors.white,
            )
          : null,
    );
  }
}
