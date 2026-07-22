import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  bool get _hasCompletionPhoto =>
      report.status == ReportStatus.resolved &&
      report.completionPhotoUrl != null &&
      report.completionPhotoUrl!.trim().isNotEmpty;

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${_formatDate(dateTime)}, $hour:$minute WIB';
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('infrastruktur')) return Icons.construction_outlined;
    if (cat.contains('bersih')) return Icons.delete_sweep_outlined;
    if (cat.contains('aman')) return Icons.security_outlined;
    if (cat.contains('terang') || cat.contains('lampu')) {
      return Icons.lightbulb_outline;
    }
    if (cat.contains('sosial') || cat.contains('tetangga')) {
      return Icons.people_outline;
    }
    return Icons.report_problem_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final userId = state.currentUser?.id ?? '';
    final isUpvoted = report.upvotedByUserIds.contains(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(context, report.status),
                const SizedBox(height: 12),
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.15,
                      ),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  context,
                  Icons.location_on_outlined,
                  report.locationLabel ?? 'Lokasi belum ditentukan',
                ),
                const SizedBox(height: 6),
                _infoRow(
                  context,
                  Icons.schedule_outlined,
                  _formatDateTime(report.createdAt),
                ),
                if (report.reportPhotoUrl != null &&
                    report.reportPhotoUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionHeader(context, Icons.photo_library_outlined, 'Foto Laporan'),
                  const SizedBox(height: 10),
                  _photoFrame(
                    context,
                    imageUrl: report.reportPhotoUrl!,
                    overlayLabel: 'Foto laporan',
                    height: 180,
                  ),
                ],
                if (_hasCompletionPhoto) ...[
                  const SizedBox(height: 14),
                  _sectionHeader(
                    context,
                    Icons.verified_outlined,
                    'Bukti Penyelesaian RT',
                  ),
                  const SizedBox(height: 10),
                  _photoFrame(
                    context,
                    imageUrl: report.completionPhotoUrl!,
                    overlayLabel: 'Bukti selesai RT',
                    height: 180,
                    accentColor: AppTheme.statusLow,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _categoryChip(context, report.category, _getCategoryIcon(report.category)),
                    const Spacer(),
                    _votePill(state, isUpvoted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, ReportStatus status) {
    Color baseColor;
    String text;

    switch (status) {
      case ReportStatus.submitted:
        baseColor = AppTheme.statusMedium;
        text = 'Diajukan';
        break;
      case ReportStatus.processed:
        baseColor = const Color(0xFF005BC1);
        text = 'Diproses';
        break;
      case ReportStatus.resolved:
        baseColor = AppTheme.statusLow;
        text = 'Selesai';
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseColor.withValues(alpha: 0.16)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.1,
              ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }

  Widget _photoFrame(
    BuildContext context, {
    required String imageUrl,
    required String overlayLabel,
    required double height,
    Color? accentColor,
  }) {
    final overlayColor = accentColor ?? AppTheme.primaryColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.surfaceContainerHigh,
                  child: const Center(
                    child: Icon(
                      Icons.photo_outlined,
                      color: AppTheme.outlineColor,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: overlayColor == AppTheme.statusLow
                          ? Colors.white
                          : Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      overlayLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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

  Widget _categoryChip(BuildContext context, String category, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 5),
          Text(
            category,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Widget _votePill(AppState state, bool isUpvoted) {
    return Material(
      color: isUpvoted ? AppTheme.primaryFixed : AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => state.upvoteReport(report.id),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward,
                size: 12,
                color: isUpvoted
                    ? AppTheme.primaryColor
                    : AppTheme.outlineColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${report.votesCount}',
                style: TextStyle(
                  color: isUpvoted
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
