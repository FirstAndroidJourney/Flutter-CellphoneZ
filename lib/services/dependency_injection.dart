import 'package:get_it/get_it.dart';
import 'package:shop/common/app_logger.dart';
import '../clients/database_client.dart';
import '../repository/auth_repository.dart';
import '../repository/product_repository.dart';
import '../repository/category_repository.dart';
import '../repository/cart_repository.dart';
import '../repository/order_repository.dart';
import '../repository/order_item_repository.dart';
import '../repository/user_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'storage_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  print('Setting up dependencies - START');

  // Load environment variables
  await dotenv.load();

  final String url = dotenv.env['SUPABASE_URL'] ?? '';
  final String anonKey = dotenv.env['ANON_KEY'] ?? '';

  try {
    // Use the already initialized Supabase instance via DatabaseClient
    print('URL from config: ${url}');
    print('AnonKey from config: ${anonKey.substring(0, 5)}...');

    await DatabaseClient.instance.initialize(
      url: url,
      anonKey: anonKey,
    );
    print('DatabaseClient initialized successfully');

    // register logger
    getIt.registerSingleton<AppLogger>(AppLogger.instance);

    // Register repositories
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
    getIt.registerLazySingleton<ProductRepository>(() => ProductRepository());
    getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepository());
    getIt.registerLazySingleton<CartRepository>(() => CartRepository());
    getIt.registerLazySingleton<OrderRepository>(() => OrderRepository());
    getIt.registerLazySingleton<OrderItemRepository>(
        () => OrderItemRepository());
    getIt.registerLazySingleton<UserRepository>(() => UserRepository());
    getIt.registerLazySingleton<StorageService>(() => StorageService());
    print('All repositories registered successfully');
  } catch (e) {
    print('Error during dependency setup: $e');
    rethrow; // Re-throw to ensure the app knows there was an issue
  }

  print('Setting up dependencies - COMPLETE');
}
