import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'status_badge.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  bool get _hasCompletionPhoto =>
      report.status == ReportStatus.resolved &&
      report.completionPhotoUrl != null &&
      report.completionPhotoUrl!.trim().isNotEmpty;

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} hari yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _hasCompletionPhoto
                ? _buildResolvedLayout(context, state, isUpvoted)
                : _buildCompactLayout(context, state, isUpvoted),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    AppState state,
    bool isUpvoted,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryIconBox(52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Diajukan ${_formatTimeAgo(report.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.outlineColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                report.locationLabel ?? 'Lokasi belum ditentukan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _metadataChip(Icons.category_outlined, report.category),
                  const Spacer(),
                  _votePill(state, isUpvoted),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResolvedLayout(
    BuildContext context,
    AppState state,
    bool isUpvoted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                  letterSpacing: -0.05,
                ),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: report.status),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Diajukan ${_formatTimeAgo(report.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.outlineColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          report.locationLabel ?? 'Lokasi belum ditentukan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 118,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  report.completionPhotoUrl!,
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
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Bukti selesai dari RT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
        const SizedBox(height: 8),
        Row(
          children: [
            _metadataChip(Icons.category_outlined, report.category),
            const Spacer(),
            _votePill(state, isUpvoted),
          ],
        ),
      ],
    );
  }

  Widget _metadataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryIconBox(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIcon(report.category),
        color: AppTheme.primaryColor,
        size: size * 0.48,
      ),
    );
  }

  Widget _votePill(AppState state, bool isUpvoted) {
    return Material(
      color: isUpvoted ? AppTheme.primaryFixed : AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: () => state.upvoteReport(report.id),
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              const SizedBox(width: 3),
              Text(
                '${report.votesCount}',
                style: TextStyle(
                  color: isUpvoted
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
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
