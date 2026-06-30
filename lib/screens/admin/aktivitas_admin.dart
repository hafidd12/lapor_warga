import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';

class AktivitasAdminScreen extends StatelessWidget {
  const AktivitasAdminScreen({super.key});

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'verification':
        return Icons.verified_user;
      case 'announcement':
        return Icons.campaign;
      case 'report_completed':
        return Icons.task_alt;
      case 'poll':
        return Icons.poll;
      case 'warga_removed':
        return Icons.person_remove;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'verification':
        return AppTheme.statusLow;
      case 'announcement':
        return AppTheme.primaryColor;
      case 'report_completed':
        return AppTheme.tertiaryContainerColor;
      case 'poll':
        return AppTheme.statusMedium;
      case 'warga_removed':
        return AppTheme.statusHigh;
      default:
        return AppTheme.secondaryColor;
    }
  }

  String _getActivityLabel(String type) {
    switch (type) {
      case 'verification':
        return 'VERIFIKASI';
      case 'announcement':
        return 'PENGUMUMAN';
      case 'report_completed':
        return 'LAPORAN SELESAI';
      case 'poll':
        return 'VOTING';
      case 'warga_removed':
        return 'WARGA KELUAR';
      default:
        return 'AKTIVITAS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final activities = state.activities;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Aktivitas Admin',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppTheme.outlineVariantColor,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada aktivitas',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityCard(context, activity);
              },
            ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AdminActivity activity) {
    final color = _getActivityColor(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  size: 20,
                  color: color,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppTheme.outlineVariantColor.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.outlineVariantColor.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getActivityLabel(activity.type),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimeAgo(activity.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                      height: 1.3,
                    ),
                  ),

                  // Photo proof if available
                  if (activity.photoUrl != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              activity.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.photo,
                                        size: 32,
                                        color: AppTheme.outlineColor,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Bukti Foto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Bukti Foto',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
