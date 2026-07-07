import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class AktivitasAdminScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const AktivitasAdminScreen({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final reports = state.adminReports;
    final activities = _buildActivitiesFromReports(reports);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Aktivitas Admin',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0.5,
        scrolledUnderElevation: 1,
      ),
      body: activities.isEmpty
          ? const Center(child: Text('Belum ada aktivitas.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isLast = index == activities.length - 1;
                return _ActivityCard(
                  activity: activity,
                  isLast: isLast,
                );
              },
            ),
    );
  }

  List<_ActivityEntry> _buildActivitiesFromReports(List<Report> reports) {
    final entries = <_ActivityEntry>[];

    for (final report in reports) {
      entries.add(
        _ActivityEntry(
          icon: Icons.assignment_outlined,
          color: AppTheme.primaryColor,
          label: 'Laporan dibuat',
          title: report.title,
          status: report.status,
          time: report.createdAt,
          subtitle:
              '${report.category} • ${_statusLabel(report.status)}',
        ),
      );

      if (report.status == ReportStatus.processed ||
          report.status == ReportStatus.resolved) {
        entries.add(
          _ActivityEntry(
            icon: Icons.play_arrow_rounded,
            color: AppTheme.statusMedium,
            label: 'Laporan diproses',
            title: report.title,
            status: report.status,
            time: report.completedAt ?? report.createdAt,
            subtitle: report.citizenName,
          ),
        );
      }

      if (report.status == ReportStatus.resolved) {
        entries.add(
          _ActivityEntry(
            icon: Icons.verified_rounded,
            color: AppTheme.statusLow,
            label: 'Laporan diselesaikan',
            title: report.title,
            status: report.status,
            time: report.completedAt ?? report.createdAt,
            subtitle: report.completedByNameText,
          ),
        );
      }
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries;
  }
}

class _ActivityEntry {
  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final ReportStatus status;
  final DateTime time;
  final String subtitle;

  const _ActivityEntry({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    required this.status,
    required this.time,
    required this.subtitle,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityEntry activity;
  final bool isLast;

  const _ActivityCard({
    required this.activity,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.icon, size: 20, color: activity.color),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  color: AppTheme.outlineVariantColor.withValues(alpha: 0.4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.outlineVariantColor.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: activity.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          activity.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: activity.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimeAgo(activity.time),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays > 0) {
    return '${diff.inDays} hari yang lalu';
  }
  if (diff.inHours > 0) {
    return '${diff.inHours} jam yang lalu';
  }
  if (diff.inMinutes > 0) {
    return '${diff.inMinutes} menit yang lalu';
  }
  return 'Baru saja';
}

String _statusLabel(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => 'Diajukan',
    ReportStatus.processed => 'Diproses',
    ReportStatus.resolved => 'Selesai',
  };
}

extension on Report {
  String get completedByNameText => completedBy?.trim().isNotEmpty == true
      ? completedBy!.trim()
      : 'Admin';
}
