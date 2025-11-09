import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

import 'screen_export.dart';

PageRoute<dynamic> _buildRoute({
  required RouteSettings settings,
  required Widget child,
  bool fullscreenDialog = false,
}) {
  return PageRouteBuilder(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: defaultDuration,
    reverseTransitionDuration: defaultDuration,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final exitFade = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: exitFade,
            child: child,
          ),
        ),
      );
    },
  );
}

int? _resolveAdminInitialIndex(Object? args) {
  if (args is int) return args;
  if (args is Map<String, dynamic>) {
    final value = args['initialIndex'];
    if (value is int) {
      return value;
    }
  }
  return null;
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const OnBordingScreen(),
      );
    case logInScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const LoginScreen(),
      );
    case signUpScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const SignUpScreen(),
      );
    case passwordRecoveryScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const PasswordRecoveryScreen(),
      );
    case productDetailScreenRoute:
      final String productId = settings.arguments as String;
      return _buildRoute(
        settings: settings,
        child: ProductDetailScreen(productId: productId),
      );
    case productReviewsScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const ProductReviewsScreen(),
      );
    case homeScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const HomeScreen(),
      );
    case discoverScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const DiscoverScreen(),
      );
    case onSaleScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const OnSaleScreen(),
      );
    case searchScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const SearchScreen(),
      );
    case searchResultsScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return _buildRoute(
        settings: settings,
        child: SearchResultsScreen(
            query: args['query'] as String,
            searchText: args['searchText'] as String),
      );
    case entryPointScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const MainScreen(),
      );
    case profileScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const ProfileScreen(),
      );
    case userInfoScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const UserInfoScreen(),
      );
    case notificationsScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const NotificationOptionsScreen(),
      );
    case ordersScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const OrdersScreen(),
      );
    case preferencesScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const PreferencesScreen(),
      );
    case cartScreenRoute:
      return _buildRoute(
        settings: settings,
        child: const CartScreen(),
      );
    case paymentScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      return _buildRoute(
        settings: settings,
        child: PaymentScreen(
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

      return _buildRoute(
        settings: settings,
        child: PaymentResultScreen(
          orderId: orderId,
          status: status,
          purchasedItemIds: purchasedItemIds,
        ),
      );

    case adminProductListScreenRoute:
      final args = settings.arguments;
      final initialIndex = _resolveAdminInitialIndex(args) ?? 0;
      return _buildRoute(
        settings: settings,
        child: AdminMainScreen(initialIndex: initialIndex),
      );

    case categoryManagementScreenRoute:
      final args = settings.arguments;
      final initialIndex = _resolveAdminInitialIndex(args) ?? 1;
      return _buildRoute(
        settings: settings,
        child: AdminMainScreen(initialIndex: initialIndex),
      );

    case orderConfirmationScreenRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      final orderId = args?['orderId'] as String?;

      if (orderId == null) {
        return _buildRoute(
          settings: settings,
          child: Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body:
                const Center(child: Text('Không tìm thấy thông tin đơn hàng')),
          ),
        );
      }

      return _buildRoute(
        settings: settings,
        child: OrderConfirmationScreen(orderId: orderId),
      );

    case orderHistoryScreenRoute:
      final userId = settings.arguments as String;
      return _buildRoute(
        settings: settings,
        child: OrderHistoryScreen(userId: userId),
      );

    default:
      return _buildRoute(
        settings: settings,
        child: const OnBordingScreen(),
      );
  }
}
