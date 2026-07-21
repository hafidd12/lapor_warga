import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final state = Provider.of<AppState>(context, listen: false);
      final result = await state.loginWithSupabase(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        final role = result['role'] as UserRole;
        final verStatus = result['verificationStatus'] as VerificationStatus;

        if (role == UserRole.warga &&
            verStatus != VerificationStatus.verified) {
          Navigator.of(context).pushReplacementNamed('/waiting-verification');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Login Gagal! Periksa email dan password.',
            ),
            backgroundColor: AppTheme.statusHigh,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed.withValues(alpha: 0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryFixedDim.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainerColor
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: AppTheme.primaryFixedDim.withValues(
                                    alpha: 0.45,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.eco,
                                size: 54,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lapor Warga',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 30,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Membangun lingkungan lebih asri dan tertib bersama',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.outlineVariantColor.withValues(
                                alpha: 0.55,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 16),
                                        child: Text(
                                          'EMAIL ATAU USERNAME',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.7,
                                            color: AppTheme.secondaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                      decoration: _buildInputDecoration(
                                        hintText: 'user@laporwarga.id',
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Format email salah';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSectionLabel('KATA SANDI'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscureText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                      decoration: _buildInputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscureText = !_obscureText;
                                            });
                                          },
                                          icon: Icon(
                                            _obscureText
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppTheme.outlineColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Kata sandi tidak boleh kosong';
                                        }
                                        if (value.length < 6) {
                                          return 'Kata sandi minimal 6 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppTheme.primaryColor,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Lupa Kata Sandi?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: _buildPrimaryButtonStyle(),
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Masuk ke Layanan',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum memiliki akun? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RoleSelectionScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Daftar Akun Baru',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        Opacity(
                          opacity: 0.4,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.forest_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.nature_people_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.recycling,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'BERPARTISIPASI MENJAGA KEASRIAN LINGKUNGAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: AppTheme.secondaryColor,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(prefixIcon, color: AppTheme.outlineColor, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(fontSize: 11.5, height: 1.2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppTheme.outlineVariantColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.statusHigh, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.statusHigh, width: 1.5),
      ),
    );
  }

  ButtonStyle _buildPrimaryButtonStyle() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppTheme.surfaceContainerHighest;
        }
        if (states.contains(MaterialState.pressed)) {
          return AppTheme.tertiaryColor;
        }
        if (states.contains(MaterialState.hovered)) {
          return AppTheme.primaryColor.withValues(alpha: 0.92);
        }
        return AppTheme.primaryColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppTheme.textSecondaryColor.withValues(alpha: 0.65);
        }
        return Colors.white;
      }),
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        if (states.contains(MaterialState.hovered)) {
          return Colors.white.withValues(alpha: 0.06);
        }
        return null;
      }),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
      elevation: MaterialStateProperty.all(0),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: MaterialStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(52)),
    );
  }
}
