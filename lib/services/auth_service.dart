import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';
import 'dependency_injection.dart';

class AuthService {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  final UserRepository _userRepository = getIt<UserRepository>();

  // Get current user
  User? get currentUser => _authRepository.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _authRepository.isAuthenticated;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _authRepository.authStateChanges;

  // Sign in with email and password
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
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
  }

  // Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _authRepository.resetPassword(email);
  }

  // Update user profile
  Future<UserProfile> updateUserProfile({
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
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

    return _userRepository.updateUserFields(userId, updates);
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;

    return _userRepository.getUserById(currentUser!.id);
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    await _authRepository.updateUser(password: newPassword);
  }
}
