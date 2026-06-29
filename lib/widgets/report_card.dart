import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'status_badge.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({Key? key, required this.report, required this.onTap})
    : super(key: key);

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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
        _categoryIconBox(64),
        const SizedBox(width: 14),
        Expanded(
          child: _reportTextContent(
            context: context,
            state: state,
            isUpvoted: isUpvoted,
            descriptionMaxLines: 1,
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
        _reportTextContent(
          context: context,
          state: state,
          isUpvoted: isUpvoted,
          descriptionMaxLines: 2,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 148,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.58),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Bukti selesai dari RT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
    );
  }

  Widget _reportTextContent({
    required BuildContext context,
    required AppState state,
    required bool isUpvoted,
    required int descriptionMaxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PriorityBadge(priority: report.priority),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                report.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: report.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          report.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: -0.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          report.description,
          maxLines: descriptionMaxLines,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        if (report.locationLabel != null || report.reportPhotoUrl != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (report.locationLabel != null)
                _metadataChip(Icons.location_on_outlined, 'Lokasi dipilih'),
              if (report.reportPhotoUrl != null)
                _metadataChip(Icons.photo_camera_outlined, 'Foto terlampir'),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pelapor: ${report.citizenName} - ${_formatTimeAgo(report.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.outlineColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _votePill(state, isUpvoted),
          ],
        ),
      ],
    );
  }

  Widget _metadataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 10,
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
                size: 13,
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
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
