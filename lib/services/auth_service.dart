import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';
import '../models/user_profile.dart';
import 'dependency_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  final UserRepository _userRepository = getIt<UserRepository>();

  // Get current user
  User? get currentUser => _authRepository.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _authRepository.isAuthenticated;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _authRepository.authStateChanges;

  // Sign up with email and password
  Future<UserProfile> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      // Create auth user
      final authResponse = await _authRepository.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'email': email,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }

      // Create user profile
      final userProfile = UserProfile(
        id: authResponse.user!.id,
        email: email,
        name: name,
        phone: phone,
      );

      return await _userRepository.createUserProfile(userProfile);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Get or create user profile
        UserProfile? userProfile =
            await _userRepository.getUserById(authResponse.user!.id);

        if (userProfile == null) {
          // Create profile if doesn't exist
          userProfile = UserProfile(
            id: authResponse.user!.id,
            email: email,
            name: authResponse.user!.userMetadata?['name'],
          );
          userProfile = await _userRepository.createUserProfile(userProfile);
        }

        return userProfile;
      }

      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  // Update user profile
  Future<UserProfile> updateUserProfile({
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = currentUser!.id;

      // Update auth user metadata if name changed
      if (name != null) {
        await _authRepository.updateUser(data: {'name': name});
      }

      // Update user profile
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      return await _userRepository.updateUserFields(userId, updates);
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      return await _userRepository.getUserById(currentUser!.id);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      await _authRepository.updateUser(password: newPassword);
    } catch (e) {
      throw Exception('Change password failed: $e');
    }
  }
}
