import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
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
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryFixedDim.withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainerColor.withValues(
                          alpha: 0.95,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.primaryFixedDim.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pilih Peran Anda',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 24,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Silakan pilih peran Anda untuk mendaftar di Lapor Warga. Setiap peran memiliki hak akses yang berbeda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Warga Card
                    _buildRoleCard(
                      index: 0,
                      icon: Icons.people_rounded,
                      title: 'Warga',
                      subtitle: 'Penduduk RT/RW',
                      description:
                          'Laporkan masalah lingkungan, ikuti voting, dan lihat pengumuman dari RT Anda.',
                      features: [
                        'Membuat laporan masalah',
                        'Voting dan polling komunitas',
                        'Melihat pengumuman RT',
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegisterScreen(isWarga: true),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // RT/RW Card
                    _buildRoleCard(
                      index: 1,
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'RT / RW',
                      subtitle: 'Pengurus Lingkungan',
                      description:
                          'Kelola warga, buat pengumuman, tangani laporan, dan selesaikan tugas lingkungan.',
                      features: [
                        'Verifikasi & kelola data warga',
                        'Buat pengumuman & voting',
                        'Tindak lanjuti laporan + foto bukti',
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegisterScreen(isWarga: false),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Back to login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRoleCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredIndex = index),
      onTapUp: (_) {
        setState(() => _hoveredIndex = null);
        onTap();
      },
      onTapCancel: () => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHovered
              ? AppTheme.primaryFixed.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHovered
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : AppTheme.outlineVariantColor.withValues(alpha: 0.4),
            width: isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : AppTheme.primaryColor.withValues(alpha: 0.03),
              blurRadius: isHovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainerColor.withValues(
                      alpha: 0.28,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(icon, size: 30, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primaryColor.withValues(alpha: 0.78),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
