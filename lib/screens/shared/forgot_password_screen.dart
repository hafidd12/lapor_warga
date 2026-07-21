import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    final result = await state.sendPasswordResetLink(_emailController.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] as String? ??
              'Terjadi kesalahan saat mengirim link reset password.',
        ),
        backgroundColor: result['success'] == true
            ? AppTheme.primaryColor
            : AppTheme.statusHigh,
      ),
    );

    if (result['success'] == true) {
      _emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lupa Kata Sandi',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed.withValues(alpha: 0.18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryFixedDim.withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.outlineVariantColor.withValues(
                                alpha: 0.55,
                              ),
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
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 84,
                                      height: 84,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryContainerColor
                                            .withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: AppTheme.primaryFixedDim
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Center(
                                        child: Transform.translate(
                                          offset: Offset(2, 2),
                                          child: Icon(
                                            Icons.lock_reset_rounded,
                                            size: 44,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Atur Ulang Kata Sandi',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Masukkan email akun Anda. Kami akan mengirim link reset password ke email tersebut.',
                                      style: TextStyle(
                                        color: AppTheme.secondaryColor,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'EMAIL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.7,
                                        color: AppTheme.secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        hintText: 'user@laporwarga.id',
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                          color: AppTheme.outlineColor,
                                          size: 20,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                              minWidth: 48,
                                              minHeight: 48,
                                            ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.outlineVariantColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.outlineVariantColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorStyle: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.2,
                                        ),
                                      ),
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!email.contains('@') ||
                                            !email.contains('.')) {
                                          return 'Format email tidak valid';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _sendResetLink,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          minimumSize: const Size.fromHeight(
                                            52,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
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
                                                  'Kirim Link Reset',
                                                  key: ValueKey('text'),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Pastikan email yang dimasukkan sesuai dengan akun yang terdaftar.',
                                        style: TextStyle(
                                          color: AppTheme.secondaryColor,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
