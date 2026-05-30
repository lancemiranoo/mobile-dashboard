import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (!next.isLoading && !next.hasError && next.value != null) {
        context.go('/home');
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 56, 32, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 84,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandLogo(size: 132),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: _AuthColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Sign in to dashboard.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: _AuthColors.mutedText),
                          ),
                          const SizedBox(height: 42),
                          _AuthTextField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter email'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          _AuthTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter password'
                                : null,
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Forgot your password?',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _AuthColors.bodyText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 28),
                          if (authState.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            _PrimaryAuthButton(
                              label: 'Sign in',
                              onPressed: _login,
                            ),
                          if (authState.hasError) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${authState.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 28),
                          Text(
                            'OR',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: _AuthColors.bodyText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 28),
                          _OutlineAuthButton(
                            label: 'Create new account',
                            onPressed: () => context.push('/register'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthColors {
  static const primary = Color(0xFF101828);
  static const accent = Color(0xFF2563EB);
  static const bodyText = Color(0xFF1F2937);
  static const mutedText = Color(0xFF667085);
  static const fieldText = Color(0xFF4B5563);
  static const divider = Color(0xFFE5E7EB);
}

class _BrandLogo extends StatelessWidget {
  final double size;

  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/wolf_of_cavite.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: _AuthColors.fieldText,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _AuthColors.fieldText,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: _AuthColors.fieldText, size: 30),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _AuthColors.divider),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _AuthColors.accent, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AuthColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OutlineAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineAuthButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AuthColors.bodyText,
          side: const BorderSide(color: _AuthColors.accent, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _AuthColors.bodyText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
