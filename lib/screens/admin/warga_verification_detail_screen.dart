import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/warga_verification_service.dart';
import '../../theme.dart';
import '../../widgets/notification_bell_button.dart';

class WargaVerificationDetailScreen extends StatefulWidget {
  const WargaVerificationDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<WargaVerificationDetailScreen> createState() =>
      _WargaVerificationDetailScreenState();
}

class _WargaVerificationDetailScreenState
    extends State<WargaVerificationDetailScreen> {
  final WargaVerificationService _service = WargaVerificationService();
  late Future<AppUser?> _userFuture;
  late Future<String?> _ktpUrlFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _service.getWargaById(widget.userId);
    _ktpUrlFuture = _loadKtpUrl();
  }

  Future<String?> _loadKtpUrl() async {
    final user = await _userFuture;
    return _service.getKtpSignedUrl(user?.ktpImagePath);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final d = dateTime;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _handleAction(bool approve, AppUser user) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final state = context.read<AppState>();
      if (approve) {
        await state.verifyWarga(user.id);
      } else {
        await state.rejectWarga(user.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${user.name} berhasil disetujui.'
                : '${user.name} berhasil ditolak.',
          ),
          backgroundColor: approve
              ? AppTheme.primaryColor
              : AppTheme.statusHigh,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppTheme.statusHigh,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _statusLabel(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'PENDING',
      VerificationStatus.verified => 'APPROVED',
      VerificationStatus.rejected => 'REJECTED',
    };
  }

  Color _statusColor(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => AppTheme.statusMedium,
      VerificationStatus.verified => AppTheme.primaryColor,
      VerificationStatus.rejected => AppTheme.statusHigh,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Verifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0.5,
        actions: const [NotificationBellButton()],
      ),
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _userFuture = _service.getWargaById(widget.userId);
                  _ktpUrlFuture = _loadKtpUrl();
                });
              },
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const _ErrorState(message: 'Data warga tidak ditemukan.');
          }

          return FutureBuilder<String?>(
            future: _ktpUrlFuture,
            builder: (context, ktpSnapshot) {
              final ktpUrl = ktpSnapshot.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileCard(
                    user: user,
                    statusLabel: _statusLabel(user.verificationStatus),
                    statusColor: _statusColor(user.verificationStatus),
                    formatDate: _formatDate,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Informasi KTP',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 240,
                            color: AppTheme.surfaceContainerLow,
                            child:
                                ktpSnapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ktpUrl == null || ktpUrl.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Foto KTP tidak tersedia',
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Image.network(
                                      ktpUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Text(
                                                'Foto KTP gagal dimuat',
                                                style: TextStyle(
                                                  color: AppTheme
                                                      .textSecondaryColor,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.ktpImagePath ?? '-',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Detail Data',
                    child: Column(
                      children: [
                        _InfoRow(label: 'Nama', value: user.name),
                        _InfoRow(label: 'Email', value: user.email),
                        _InfoRow(
                          label: 'No. KTP',
                          value: user.ktpNumber ?? '-',
                        ),
                        _InfoRow(label: 'RT/RW', value: user.rtRw ?? '-'),
                        _InfoRow(label: 'No. HP', value: user.phone ?? '-'),
                        _InfoRow(label: 'Alamat', value: user.address ?? '-'),
                        _InfoRow(
                          label: 'Kode Reg.',
                          value: user.registrationCode ?? '-',
                        ),
                        _InfoRow(
                          label: 'Terdaftar',
                          value: _formatDate(user.registeredAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (user.verificationStatus == VerificationStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleAction(false, user),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.statusHigh,
                              side: const BorderSide(
                                color: AppTheme.statusHigh,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleAction(true, user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Approve',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.statusLabel,
    required this.statusColor,
    required this.formatDate,
  });

  final AppUser user;
  final String statusLabel;
  final Color statusColor;
  final String Function(DateTime?) formatDate;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Profil Warga',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      label: user.rtRw ?? '-',
                      icon: Icons.map_outlined,
                    ),
                    _MetaChip(
                      label: formatDate(user.registeredAt),
                      icon: Icons.schedule_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.statusHigh,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
