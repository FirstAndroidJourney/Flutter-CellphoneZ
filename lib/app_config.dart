import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:shop/services/database_schema.dart';

class SupabaseConfig {
  static final _env = dotenv.DotEnv()..load();

  // Thay thế bằng thông tin thực tế từ Supabase Dashboard > Settings > API
  static String get url => _env['SUPABASE_URL'] ?? '';
  static String get anonKey => _env['ANON_KEY'] ?? '';

  // Database schema - Sử dụng DatabaseSchema để truy cập
  static final tables = DatabaseSchema.tables;
  static final schema = DatabaseSchema();

  // Storage buckets
  static final storageBuckets = const StorageBuckets();
}

// Environment configuration
class AppConfig {
  static const bool isDevelopment = true;
  static const bool enableLogging = isDevelopment;

  // App settings
  static const String appName = 'E-commerce Shop';
  static const String appVersion = '1.0.0';
}
