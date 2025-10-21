import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class DatabaseClient {
  static DatabaseClient? _instance;
  late final sb.Supabase _supabase;

  // Private constructor
  DatabaseClient._();

  // Singleton instance
  static DatabaseClient get instance {
    _instance ??= DatabaseClient._();
    return _instance!;
  }

  // Initialize Supabase - use existing instance if already initialized
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await sb.Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true, // Set false for production
    );
    _supabase = sb.Supabase.instance;
  }

  // Get Supabase client
  sb.SupabaseClient get client => _supabase.client;

  // Auth helpers
  sb.User? get currentUser => _supabase.client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Auth stream
  Stream<sb.AuthState> get authStateChanges =>
      _supabase.client.auth.onAuthStateChange;

  // Database helpers
  sb.PostgrestQueryBuilder from(String table) => _supabase.client.from(table);

  // Storage helpers
  sb.SupabaseStorageClient get storage => _supabase.client.storage;

  // Realtime helpers
  sb.RealtimeChannel channel(String name) => _supabase.client.channel(name);
}

// Global instance for easy access
final supabase = DatabaseClient.instance.client;
