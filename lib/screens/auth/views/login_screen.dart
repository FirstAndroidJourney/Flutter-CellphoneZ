import 'package:flutter/material.dart';
import 'package:shop/common/app_logger.dart';
import 'package:shop/constants.dart';
import 'package:shop/repository/auth_repository.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/role_service.dart';

import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();
  final RoleService _roleService = RoleService();
  final AppLogger _logger = AppLogger.instance;

  String? _email;
  String? _password;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    // Kiểm tra xem người dùng đã đăng nhập chưa
    if (_authRepository.isAuthenticated) {
      _logger.d(
          '🔒 [LoginScreen] Existing session found, redirecting to entry point');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          entryPointScreenRoute,
          (route) => false,
        );
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (_email == null || _password == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.d('🔒 [LoginScreen] Attempting sign in for $_email');
      final authResponse = await _authRepository.signIn(
        email: _email!,
        password: _password!,
      );

      _logger.d(
        '🔒 [LoginScreen] Sign in succeeded. Supabase user: ${authResponse.user?.id ?? 'null'} (current: ${_authRepository.currentUser?.id ?? 'null'})',
      );

      final role = await _roleService.resolveCurrentUserRole();

      if (!mounted) return;

      final targetRoute =
          role == 'admin' ? adminProductListScreenRoute : entryPointScreenRoute;

      _logger.d(
        '🔒 [LoginScreen] Role resolved as "$role". Navigating to $targetRoute',
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        ModalRoute.withName(logInScreenRoute),
      );
    } catch (e) {
      _logger.e('🔒 [LoginScreen] Login error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/login_dark.png",
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  const Text(
                    "Log in with your data that you intered during your registration.",
                  ),
                  const SizedBox(height: defaultPadding),
                  LogInForm(
                    formKey: _formKey,
                    onEmailSaved: (email) => _email = email,
                    onPasswordSaved: (password) => _password = password,
                  ),
                  Align(
                    child: TextButton(
                      child: const Text("Forgot password"),
                      onPressed: () {
                        Navigator.pushNamed(
                            context, passwordRecoveryScreenRoute);
                      },
                    ),
                  ),
                  SizedBox(
                    height:
                        size.height > 700 ? size.height * 0.1 : defaultPadding,
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text("Log in"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, signUpScreenRoute);
                        },
                        child: const Text("Sign up"),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
