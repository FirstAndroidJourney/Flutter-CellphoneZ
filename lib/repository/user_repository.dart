import '../models/user_profile.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  @override
  String get tableName => usersSchema.table;

  // Get all user profiles as UserProfile objects
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final data = await getAll();
      return data.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user profiles: $e');
    }
  }

  // Get user profile by ID
  Future<UserProfile?> getUserById(String id) async {
    try {
      final data = await getById(id);
      return data != null ? UserProfile.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Get user profile by email
  Future<UserProfile?> getUserByEmail(String email) async {
    try {
      final response =
          await queryBuilder.select().eq(usersSchema.email, email).maybeSingle();
      return response != null ? UserProfile.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch user profile by email: $e');
    }
  }

  // Create new user profile
  Future<UserProfile> createUserProfile(UserProfile userProfile) async {
    try {
      final data = await create(userProfile.toJson());
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Update user profile
  Future<UserProfile> updateUserProfile(
      String id, UserProfile userProfile) async {
    try {
      final data = await update(id, userProfile.toJson());
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update specific user fields
  Future<UserProfile> updateUserFields(
      String id, Map<String, dynamic> fields) async {
    try {
      final data = await update(id, fields);
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update user fields: $e');
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String id) async {
    try {
      await delete(id);
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Update user avatar
  Future<UserProfile> updateUserAvatar(String id, String avatarUrl) async {
    try {
      return await updateUserFields(id, {'avatarUrl': avatarUrl});
    } catch (e) {
      throw Exception('Failed to update user avatar: $e');
    }
  }

  // Update user phone
  Future<UserProfile> updateUserPhone(String id, String phone) async {
    try {
      return await updateUserFields(id, {'phone': phone});
    } catch (e) {
      throw Exception('Failed to update user phone: $e');
    }
  }

  // Update user address
  Future<UserProfile> updateUserAddress(String id, String address) async {
    try {
      return await updateUserFields(id, {'address': address});
    } catch (e) {
      throw Exception('Failed to update user address: $e');
    }
  }

  // Search users by name or email
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await queryBuilder
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%');
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
