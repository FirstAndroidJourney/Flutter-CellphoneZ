import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/auth_service.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: defaultPadding),
            Text(
              'Chào mừng bạn đến với CellphoneZ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              'Đăng nhập để trải nghiệm mua sắm tuyệt vời',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: defaultPadding * 2),
            // Nút Đăng nhập
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, logInScreenRoute);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cellphoneZRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            // Nút Đăng ký
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, signUpScreenRoute);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: cellphoneZRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: cellphoneZRed, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Đăng ký tài khoản mới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView() {
    final user = _authService.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'User';
    final userEmail = user?.email ?? '';

    return ListView(
      children: [
        Container(
          color: cellphoneZRed,
          padding: const EdgeInsets.only(bottom: defaultPadding),
          child: ProfileCard(
            name: userName,
            email: userEmail,
            imageSrc: "https://i.imgur.com/IXnwbLk.png",
            press: () {
              Navigator.pushNamed(context, userInfoScreenRoute);
            },
          ),
        ),

        // Account Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(defaultPadding),
          margin: const EdgeInsets.only(
              top: defaultPadding, bottom: defaultPadding / 2),
          child: Text(
            "Tài khoản",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ProfileMenuListTile(
          text: "Lịch sử mua hàng",
          svgSrc: "assets/icons/Order.svg",
          press: () {
            final user = _authService.currentUser;
            if (user != null) {
              Navigator.pushNamed(
                context,
                orderHistoryScreenRoute,
                arguments: user.id,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng đăng nhập để xem lịch sử đơn hàng'),
                ),
              );
            }
          },
        ),
        ProfileMenuListTile(
          text: "Phương thức thanh toán",
          svgSrc: "assets/icons/card.svg",
          press: () {
            Navigator.pushNamed(context, emptyPaymentScreenRoute);
          },
        ),

        // Support Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(defaultPadding),
          margin: const EdgeInsets.only(
              top: defaultPadding, bottom: defaultPadding / 2),
          child: Text(
            "Hỗ trợ & Chính sách",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ProfileMenuListTile(
          text: "Tư vấn hỗ trợ",
          svgSrc: "assets/icons/Help.svg",
          press: () {
            Navigator.pushNamed(context, getHelpScreenRoute);
          },
        ),
        ProfileMenuListTile(
          text: "Chính sách đổi trả",
          svgSrc: "assets/icons/Return.svg",
          press: () {},
        ),
        ProfileMenuListTile(
          text: "Điều khoản sử dụng",
          svgSrc: "assets/icons/FAQ.svg",
          press: () {
            Navigator.pushNamed(context, termsOfServicesScreenRoute);
          },
        ),
        ProfileMenuListTile(
          text: "Câu hỏi thường gặp",
          svgSrc: "assets/icons/FAQ.svg",
          press: () {},
        ),

        // Settings Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(defaultPadding),
          margin: const EdgeInsets.only(
              top: defaultPadding, bottom: defaultPadding / 2),
          child: Text(
            "Cài đặt",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        DividerListTileWithTrilingText(
          svgSrc: "assets/icons/Notification.svg",
          title: "Thông báo",
          trilingText: "Tắt",
          press: () {
            Navigator.pushNamed(context, enableNotificationScreenRoute);
          },
        ),
        ProfileMenuListTile(
          text: "Ngôn ngữ",
          svgSrc: "assets/icons/Language.svg",
          press: () {
            Navigator.pushNamed(context, selectLanguageScreenRoute);
          },
        ),
        ProfileMenuListTile(
          text: "Vị trí",
          svgSrc: "assets/icons/Location.svg",
          press: () {},
        ),

        // Logout
        Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: defaultPadding),
          child: ListTile(
            onTap: () async {
              final shouldLogout = await _showLogoutDialog();

              if (shouldLogout == true) {
                try {
                  await _authService.signOut();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng xuất thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi đăng xuất: $e'),
                        backgroundColor: cellphoneZRed,
                      ),
                    );
                  }
                }
              }
            },
            minLeadingWidth: 24,
            leading: SvgPicture.asset(
              "assets/icons/Logout.svg",
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(
                cellphoneZRed,
                BlendMode.srcIn,
              ),
            ),
            title: const Text(
              "Đăng xuất",
              style: TextStyle(
                  color: cellphoneZRed,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: defaultPadding),
      ],
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final titleStyle = Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold);

        final captionStyle = Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey[600]);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cellphoneZRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.logout,
                    color: cellphoneZRed,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Xác nhận đăng xuất',
                  style: titleStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Bạn sẽ cần đăng nhập lại để tiếp tục quản lý tài khoản và đơn hàng.',
                  textAlign: TextAlign.center,
                  style: captionStyle,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cellphoneZRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Đăng xuất'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authService.isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: cellphoneZRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tài khoản'),
        centerTitle: true,
      ),
      body: isAuthenticated ? _buildLoggedInView() : _buildGuestView(),
    );
  }
}
