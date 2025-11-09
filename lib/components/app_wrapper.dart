import 'package:flutter/material.dart';
import 'package:shop/common/app_logger.dart';
import 'package:shop/repository/auth_repository.dart';
import 'package:shop/services/role_service.dart';
import 'package:shop/admin/view/admin_main_screen.dart';
import 'package:shop/screens/main_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final AuthRepository _authRepository = AuthRepository();
  final RoleService _roleService = RoleService();
  final AppLogger _logger = AppLogger.instance;

  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();
  }

  Future<void> _checkAuthAndRole() async {
    try {
      _logger.d('🔒 [AppWrapper] Checking authentication state...');

      if (_authRepository.isAuthenticated) {
        _logger.d('🔒 [AppWrapper] User is authenticated, checking role...');

        final role = await _roleService.resolveCurrentUserRole();
        _logger.d('🔒 [AppWrapper] User role: $role');

        setState(() {
          _isAdmin = role == 'admin';
          _isLoading = false;
        });
      } else {
        _logger.d(
            '🔒 [AppWrapper] User not authenticated, showing user interface');
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('🔒 [AppWrapper] Error checking auth/role', e);
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Navigate to appropriate screen based on role
    return _isAdmin ? const AdminMainScreen() : const MainScreen();
  }
}
