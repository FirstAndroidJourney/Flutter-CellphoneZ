import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/repository/auth_repository.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  String? _email;
  bool _isSubmitting = false;

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
                child: _buildRecoveryCard(
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

  Widget _buildRecoveryCard({
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
            "Forgot password",
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
            "Enter the email address associated with your account so we can send you a reset link.",
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
            child: Form(
              key: _formKey,
              child: TextFormField(
                onSaved: (email) => _email = email?.trim(),
                validator: emaildValidator.call,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: "Email address",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: defaultPadding * 0.75,
                    ),
                    child: SvgPicture.asset(
                      "assets/icons/Message.svg",
                      height: 24,
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        theme.textTheme.bodyLarge?.color?.withOpacity(0.3) ??
                            blackColor40,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding * 1.5),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 8,
                shadowColor: buttonColor.withOpacity(0.4),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Send reset link",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonColor,
              ),
              child: const Text("Back to login"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    if (_email == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authRepository.resetPassword(_email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Reset link sent! Please check $_email to continue the process.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send reset link: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
