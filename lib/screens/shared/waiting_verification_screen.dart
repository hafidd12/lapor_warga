import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
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

  String _titleForStatus(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'Menunggu Verifikasi',
      VerificationStatus.rejected => 'Pendaftaran Ditolak',
      VerificationStatus.verified => 'Akun Sudah Aktif',
    };
  }

  String _bodyForStatus(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending =>
        'Akun Anda sedang menunggu verifikasi dari RT/Admin. Setelah disetujui, Anda bisa masuk ke dashboard warga.',
      VerificationStatus.rejected =>
        'Pendaftaran Anda ditolak oleh RT/Admin. Silakan hubungi pengurus setempat untuk mengetahui alasan penolakan dan langkah berikutnya.',
      VerificationStatus.verified =>
        'Akun Anda sudah diverifikasi. Silakan masuk kembali ke aplikasi untuk melanjutkan.',
    };
  }

  IconData _iconForStatus(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => Icons.hourglass_top_rounded,
      VerificationStatus.rejected => Icons.cancel_rounded,
      VerificationStatus.verified => Icons.verified_rounded,
    };
  }

  Color _colorForStatus(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => AppTheme.primaryColor,
      VerificationStatus.rejected => AppTheme.statusHigh,
      VerificationStatus.verified => AppTheme.primaryColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final status = user?.verificationStatus ?? VerificationStatus.pending;
    final isRejected = status == VerificationStatus.rejected;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: _colorForStatus(status).withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _colorForStatus(
                                        status,
                                      ).withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _iconForStatus(status),
                                  size: 36,
                                  color: _colorForStatus(status),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _titleForStatus(status),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 24,
                            color: _colorForStatus(status),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _bodyForStatus(status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.outlineVariantColor.withOpacity(0.4),
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
                                'Informasi pendaftaran Anda sudah masuk ke sistem',
                            isCompleted: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 18),
                            child: Divider(
                              height: 24,
                              color: AppTheme.surfaceContainer,
                            ),
                          ),
                          _buildInfoRow(
                            icon: isRejected
                                ? Icons.cancel_outlined
                                : Icons.verified_user_outlined,
                            title: isRejected
                                ? 'Pendaftaran ditolak'
                                : 'Verifikasi oleh RT/Admin',
                            subtitle: isRejected
                                ? 'Pendaftaran Anda belum dapat dilanjutkan.'
                                : 'RT/Admin sedang memeriksa data Anda.',
                            isCompleted: isRejected
                                ? true
                                : status == VerificationStatus.verified,
                            isActive: status == VerificationStatus.pending,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 18),
                            child: Divider(
                              height: 24,
                              color: AppTheme.surfaceContainer,
                            ),
                          ),
                          _buildInfoRow(
                            icon: Icons.check_circle_outline,
                            title: 'Akun aktif',
                            subtitle:
                                'Jika disetujui, Anda langsung masuk ke dashboard warga.',
                            isCompleted: status == VerificationStatus.verified,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _colorForStatus(status),
                          side: BorderSide(
                            color: _colorForStatus(status),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Kembali ke Halaman Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user != null)
                      Text(
                        'Akun: ${user.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
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
