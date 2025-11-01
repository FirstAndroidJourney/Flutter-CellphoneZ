import 'package:flutter/material.dart';

import 'package:provider/provider.dart'; // <-- Đã thêm
import 'package:shop/providers/cart_provider.dart'; // <-- Đã thêm
import 'package:shop/providers/tab_provider.dart';
import 'package:shop/route/route_constants.dart';

import 'package:shop/route/router.dart' as router;
import 'package:shop/screens/shop/views/shop_screen.dart';
import 'package:shop/services/dependency_injection.dart';
import 'package:shop/theme/app_theme.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup dependency injection
  await setupDependencies();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => TabProvider()),
      ],
      child: const MyApp(), // Đây là app gốc của bạn
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CellphoneZ',
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      // Khởi động trực tiếp vào ShopScreen để test Category Filter & Search
      home: const ShopScreen(),
    );
  }
}
