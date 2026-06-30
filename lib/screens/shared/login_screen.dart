import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/custom_button.dart';
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
          // Warga not yet verified
          Navigator.of(context).pushReplacementNamed('/waiting-verification');
        } else {
          // Verified warga or admin
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
          // Radial Mesh Background elements
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
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Identity
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainerColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 44,
                            color: AppTheme.primaryFixedDim,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lapor Warga',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 28,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Membangun lingkungan lebih asri dan tertib bersama',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Login Container (Glass Card)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.outlineVariantColor.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.04,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
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
                                // Email Input
                                const Text(
                                  'EMAIL ATAU USERNAME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppTheme.secondaryColor,
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
                                  decoration: InputDecoration(
                                    hintText: 'user@laporwarga.id',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textSecondaryColor
                                          .withValues(alpha: 0.5),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: AppTheme.outlineColor,
                                      size: 22,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.outlineVariantColor,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.statusHigh,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.statusHigh,
                                        width: 1.5,
                                      ),
                                    ),
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

                                // Password Input
                                const Text(
                                  'KATA SANDI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textSecondaryColor
                                          .withValues(alpha: 0.5),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppTheme.outlineColor,
                                      size: 22,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppTheme.outlineColor,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.outlineVariantColor,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.statusHigh,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.statusHigh,
                                        width: 1.5,
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

                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Lupa Kata Sandi?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Quick login hint
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'AKUN DEMO',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Warga\nEmail : user@gmail.com\nPassword : 12345678\n\nAdmin RT\nEmail : agus@gmail.com\nPassword : 12345678',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondaryColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Action Button
                                CustomButton(
                                  text: 'Masuk ke Layanan',
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link -> goes to Role Selection
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
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RoleSelectionScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar Akun Baru',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Decorative Footer
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
        ],
      ),
    );
  }
}
