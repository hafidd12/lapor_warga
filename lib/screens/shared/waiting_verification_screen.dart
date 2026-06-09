import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme.dart';

class WaitingVerificationScreen extends StatefulWidget {
  const WaitingVerificationScreen({Key? key}) : super(key: key);

  @override
  State<WaitingVerificationScreen> createState() =>
      _WaitingVerificationScreenState();
}

class _WaitingVerificationScreenState extends State<WaitingVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryFixedDim.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryFixed.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainerColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 36,
                                  color: AppTheme.primaryFixedDim,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Menunggu Verifikasi',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 24,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Akun Anda sedang menunggu verifikasi dari Ketua RT. Proses ini diperlukan untuk memastikan bahwa Anda adalah warga yang terdaftar di wilayah ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Status info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              AppTheme.outlineVariantColor.withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.assignment_turned_in_outlined,
                            title: 'Data telah dikirim',
                            subtitle:
                                'Informasi pendaftaran Anda telah berhasil dikirim',
                            isCompleted: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 18),
                            child: Divider(
                                height: 24,
                                color: AppTheme.surfaceContainer),
                          ),
                          _buildInfoRow(
                            icon: Icons.verified_user_outlined,
                            title: 'Verifikasi oleh RT',
                            subtitle:
                                'RT sedang memverifikasi data Anda. Mohon bersabar.',
                            isCompleted: false,
                            isActive: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 18),
                            child: Divider(
                                height: 24,
                                color: AppTheme.surfaceContainer),
                          ),
                          _buildInfoRow(
                            icon: Icons.check_circle_outline,
                            title: 'Akun aktif',
                            subtitle:
                                'Setelah diverifikasi, Anda dapat login dan menggunakan fitur warga.',
                            isCompleted: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Back to login
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Kembali ke Halaman Login',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.tertiaryContainerColor.withOpacity(0.15)
                : isActive
                    ? AppTheme.primaryFixed.withOpacity(0.3)
                    : AppTheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : icon,
            size: 18,
            color: isCompleted
                ? AppTheme.tertiaryContainerColor
                : isActive
                    ? AppTheme.primaryColor
                    : AppTheme.outlineColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
