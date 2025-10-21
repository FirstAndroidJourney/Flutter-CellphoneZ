import 'package:supabase_flutter/supabase_flutter.dart';
import 'schema_accessor.dart';

/// Lớp cơ sở cho tất cả các repository
/// 
/// Cung cấp các phương thức CRUD cơ bản và truy cập đến database schema
abstract class BaseRepository with SchemaAccessor {
  final SupabaseClient client = Supabase.instance.client;

  @override
  String get tableName;

  // Common CRUD operations
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await client.from(tableName).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch data from $tableName: $e');
    }
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      final response =
          await client.from(tableName).select().eq(idColumn, id).maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch item with id $id from $tableName: $e');
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response =
          await client.from(tableName).insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to create item in $tableName: $e');
    }
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await client
          .from(tableName)
          .update(data)
          .eq(idColumn, id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to update item with id $id in $tableName: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await client.from(tableName).delete().eq(idColumn, id);
    } catch (e) {
      throw Exception('Failed to delete item with id $id from $tableName: $e');
    }
  }

  // Query builder for custom queries
  PostgrestQueryBuilder get queryBuilder => client.from(tableName);
}
