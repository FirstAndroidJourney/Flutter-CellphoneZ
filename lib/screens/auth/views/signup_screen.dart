import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/auth/views/components/sign_up_form.dart';
import 'package:shop/repository/auth_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  // Form data
  String? _email;
  String? _password;
  String? _fullName;

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
                child: _buildSignUpCard(
                  context: context,
                  decorationTheme: pillInputTheme,
                  buttonColor: brandPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpCard({
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
          const SizedBox(height: defaultPadding * 1.2),
          Text(
            "Tạo tài khoản",
            style: (theme.textTheme.headlineSmall ??
                    theme.textTheme.headlineMedium ??
                    const TextStyle())
                .copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: defaultPadding * 0.5),
          Text(
            "Vui lòng nhập thông tin hợp lệ để tạo tài khoản.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                  blackColor60,
            ),
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
            child: SignUpForm(
              formKey: _formKey,
              onEmailSaved: (email) => _email = email,
              onPasswordSaved: (password) => _password = password,
              onFullNameSaved: (fullName) => _fullName = fullName,
            ),
          ),
          const SizedBox(height: defaultPadding),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                activeColor: buttonColor,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text(
                      "Tôi đồng ý với",
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          termsOfServicesScreenRoute,
                        );
                      },
                      child: Text(
                        "Điều khoản dịch vụ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: buttonColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "& chính sách bảo mật.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7) ??
                            blackColor60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding * 1.5),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleContinue,
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
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Đăng ký",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bạn đã có tài khoản?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                      blackColor60,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, logInScreenRoute);
                },
                style: TextButton.styleFrom(
                  foregroundColor: buttonColor,
                ),
                child: const Text("Đăng nhập"),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check terms agreement
    if (!_agreedToTerms) {
      _showErrorSnackBar(
        'Vui lòng đồng ý với Điều khoản dịch vụ và chính sách bảo mật để tiếp tục.',
      );
      return;
    }

    // Save form data
    _formKey.currentState!.save();

    // Validate data
    if (_email == null || _password == null || _fullName == null) {
      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🚀 Đang gửi request đăng ký với email: $_email');
      debugPrint('📧 Email redirect to: cellphonez://verify-email');

      // Gửi OTP qua email (signUp với emailRedirectTo sẽ tự động gửi OTP)
      final response = await _authRepository.signUp(
        email: _email!,
        password: _password!,
        data: {
          'name': _fullName,
          'email': _email,
        },
        emailRedirectTo: 'cellphonez://verify-email',
      );

      debugPrint('✅ SignUp Response: ${response.user?.id}');
      debugPrint(
          '📧 Email confirmation sent: ${response.user?.emailConfirmedAt}');
      debugPrint('🔐 User confirmed: ${response.user?.confirmedAt}');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Đã gửi mã OTP đến email của bạn. Vui lòng kiểm tra!'),
            backgroundColor: successColor,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to OTP verification screen
        Navigator.pushNamed(
          context,
          otpVerificationScreenRoute,
          arguments: {
            'email': _email!,
            'password': _password!,
            'fullName': _fullName!,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ SignUp Error: $e');
      String errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';

      // Handle specific errors
      if (e.toString().contains('email')) {
        if (e.toString().contains('already')) {
          errorMessage = 'Email này đã được sử dụng. Vui lòng chọn email khác.';
        } else if (e.toString().contains('invalid')) {
          errorMessage = 'Địa chỉ email không hợp lệ.';
        }
      } else if (e.toString().contains('password')) {
        errorMessage = 'Mật khẩu không đủ mạnh. Vui lòng chọn mật khẩu khác.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
      }

      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
