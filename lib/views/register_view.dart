import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localErrorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    ref.read(authControllerProvider.notifier).reset();

    if (_displayNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _localErrorMessage = 'Please fill up all fields.';
      });
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _localErrorMessage = 'Invalid email address.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _localErrorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _localErrorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    await ref
        .read(authControllerProvider.notifier)
        .register(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );

    final authState = ref.read(authControllerProvider);
    if (!authState.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    }
  }

  void _clearLocalError() {
    final authState = ref.read(authControllerProvider);

    if (_localErrorMessage == null && !authState.hasError) {
      return;
    }

    if (authState.hasError) {
      ref.read(authControllerProvider.notifier).reset();
    }

    setState(() {
      _localErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorMessage =
        _localErrorMessage ??
        (authState.hasError ? 'Unable to create account.' : null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 64, 32, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 92,
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
                          // const _BrandLogo(size: 150),
                          const SizedBox(height: 24),
                          Text(
                            'Create an Account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: _AuthColors.mutedText,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            'Create an account to access dashboard.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: _AuthColors.mutedText),
                          ),
                          const SizedBox(height: 42),
                          _AuthTextField(
                            controller: _displayNameController,
                            hintText: 'Name',
                            icon: Icons.person_outline_rounded,
                            onChanged: (_) => _clearLocalError(),
                          ),
                          const SizedBox(height: 20),
                          _AuthTextField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => _clearLocalError(),
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
                            onChanged: (_) => _clearLocalError(),
                          ),
                          const SizedBox(height: 20),
                          _AuthTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                            onChanged: (_) => _clearLocalError(),
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 44),
                          if (authState.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            _PrimaryAuthButton(
                              label: 'Register',
                              onPressed: _register,
                            ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have account? ',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: _AuthColors.bodyText),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .reset();
                                  context.go('/login');
                                },
                                child: Text(
                                  'Sign In',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: _AuthColors.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
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

// class _BrandLogo extends StatelessWidget {
//   final double size;

//   const _BrandLogo({required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Image.asset(
//         'assets/images/wolf_of_cavite.png',
//         width: size,
//         height: size,
//         fit: BoxFit.contain,
//       ),
//     );
//   }
// }

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
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

bool _isValidEmail(String email) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}
