import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/services/dependency_injection.dart';
import 'package:shop/theme/app_theme.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Load environment variables
  // await dotenv.load();

  // final String url = dotenv.env['SUPABASE_URL'] ?? '';
  // final String anonKey = dotenv.env['ANON_KEY'] ?? '';

  // // Debug: Print Supabase config values
  // print('Supabase URL: $url');
  // print('Supabase Anon Key: $anonKey');

  // // Initialize Supabase only once here
  // await Supabase.initialize(
  //   url: url,
  //   anonKey: anonKey,
  //   debug: true, // Debug mode for development
  // );

  // print('Supabase initialized in main.dart');

  // Setup dependency injection
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop Template by The Flutter Way',
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: onbordingScreenRoute,
    );
  }
}
