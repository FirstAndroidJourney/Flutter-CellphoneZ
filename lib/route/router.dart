import 'package:flutter/material.dart';

import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnBordingScreen(),
      );
    case logInScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
    case productDetailScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final String productId = settings.arguments as String;
          return ProductDetailScreen(productId: productId);
        },
      );
    case productReviewsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProductReviewsScreen(),
      );
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    case discoverScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    case onSaleScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnSaleScreen(),
      );
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      );
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const MainScreen(),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    case userInfoScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const UserInfoScreen(),
      );
    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationOptionsScreen(),
      );
    case ordersScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      );
    case preferencesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
      );
    case cartScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const CartScreen(),
      );
    case paymentScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderSummary: args?['orderSummary'],
          deliveryAddress: args?['deliveryAddress'] ?? '',
          items: args?['items'] ?? [],
          customerNote: args?['customerNote'],
          isBuyNow: args?['isBuyNow'] ?? false,
        ),
      );
    case paymentResultScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      final orderId = args?['orderId'] ?? 'unknown';
      final status = args?['status'] ?? 'pending';
      final purchasedItemIds = args?['purchasedItemIds'] as List<String>?;

      return MaterialPageRoute(
        builder: (context) => PaymentResultScreen(
          orderId: orderId,
          status: status,
          purchasedItemIds: purchasedItemIds,
        ),
      );

    case adminProductListScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProductListScreen(),
      );

    case categoryManagementScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const CategoryManagement(),
      );

    case orderConfirmationScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      final orderId = args?['orderId'] as String?;

      if (orderId == null) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body:
                const Center(child: Text('Không tìm thấy thông tin đơn hàng')),
          ),
        );
      }

      return MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(orderId: orderId),
      );

    case orderHistoryScreenRoute:
      final userId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => OrderHistoryScreen(userId: userId),
      );

    default:
      return MaterialPageRoute(
        // Make a screen for undefine
        builder: (context) => const OnBordingScreen(),
      );
  }
}
