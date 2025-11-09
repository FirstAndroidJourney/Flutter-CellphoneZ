import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/auth/views/components/sign_up_form.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;

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
            "Create account",
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
            "Please enter your valid data in order to create an account.",
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
            child: SignUpForm(formKey: _formKey),
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
                      "I agree with the",
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
                        "Terms of service",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: buttonColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "& privacy policy.",
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
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 8,
                shadowColor: buttonColor.withOpacity(0.4),
              ),
              child: const Text(
                "Continue",
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
                "Do you have an account?",
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
                child: const Text("Log in"),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms of service & privacy policy to continue.',
          ),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    Navigator.pushNamed(context, entryPointScreenRoute);
  }
}
