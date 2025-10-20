import 'package:get_it/get_it.dart';
import '../clients/database_client.dart';
import '../repository/auth_repository.dart';
import '../app_config.dart';
import '../repository/product_repository.dart';
import '../repository/category_repository.dart';
import '../repository/cart_repository.dart';
import '../repository/order_repository.dart';
import '../repository/order_item_repository.dart';
import '../repository/user_repository.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Initialize Supabase
  await DatabaseClient.instance.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Register repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepository());
  getIt.registerLazySingleton<CategoryRepository>(() => CategoryRepository());
  getIt.registerLazySingleton<CartRepository>(() => CartRepository());
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepository());
  getIt.registerLazySingleton<OrderItemRepository>(() => OrderItemRepository());
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
}
