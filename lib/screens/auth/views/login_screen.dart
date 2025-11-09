import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/common/app_logger.dart';
import 'package:shop/constants.dart';
import 'package:shop/repository/auth_repository.dart';
import 'package:shop/route/route_constants.dart';

import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();
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

      if (!mounted) return;

      _logger.d(
        '🔒 [LoginScreen] Login successful. Navigating to entryPoint for role detection.',
      );

      // Always navigate to entryPoint - AppWrapper will handle role-based routing
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
        (route) => false,
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
    final theme = Theme.of(context);
    const Color brandPrimary = cellphoneZRed;
    final Color inputFillColor =
        theme.inputDecorationTheme.fillColor ?? lightGreyColor;

    final InputDecorationThemeData pillInputTheme =
        theme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color:
            theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? blackColor40,
        fontWeight: FontWeight.w500,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/login_background.svg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding * 1.4,
                  vertical: defaultPadding * 1.2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: defaultPadding * 1.5),
                    _buildLoginCard(
                      context: context,
                      decorationTheme: pillInputTheme,
                      buttonColor: brandPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard({
    required BuildContext context,
    required InputDecorationThemeData decorationTheme,
    required Color buttonColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(defaultPadding * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Cellphone",
                style: (theme.textTheme.headlineLarge ??
                        theme.textTheme.headlineSmall ??
                        const TextStyle())
                    .copyWith(
                  fontWeight: FontWeight.w800,
                  color: buttonColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/logo/CellphoneZ.svg',
                height: 48,
                width: 48,
              ),
            ],
          ),
          const SizedBox(height: defaultPadding * 1.5),
          Theme(
            data: theme.copyWith(
              inputDecorationTheme: decorationTheme,
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: buttonColor,
                selectionColor: buttonColor.withOpacity(0.2),
                selectionHandleColor: buttonColor,
              ),
            ),
            child: LogInForm(
              formKey: _formKey,
              onEmailSaved: (email) => _email = email,
              onPasswordSaved: (password) => _password = password,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, passwordRecoveryScreenRoute);
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonColor,
              ),
              child: const Text("Forgot password?"),
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 8,
                shadowColor: buttonColor.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                      blackColor60,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, signUpScreenRoute);
                },
                style: TextButton.styleFrom(
                  foregroundColor: buttonColor,
                ),
                child: const Text("Sign up"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
