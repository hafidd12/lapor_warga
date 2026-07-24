import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/notification_bell_button.dart';

class AktivitasAdminScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const AktivitasAdminScreen({super.key, this.onBackPressed});

  Future<void> _refreshActivities(BuildContext context) async {
    await context.read<AppState>().refreshActivities().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final activities = _buildActivitiesFromAdminActivities(state.activities);
    final groupedActivities = _groupActivitiesByDate(activities);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        toolbarHeight: 78,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const _ActivityHeaderTitle(
          title: 'Riwayat Aktivitas RT',
          subtitle: 'Riwayat aktivitas yang telah dilakukan RT',
        ),
        actions: const [NotificationBellButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: () => _refreshActivities(context),
            child: groupedActivities.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: const _ActivityEmptyState(),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: groupedActivities.length,
                    itemBuilder: (context, index) {
                      final group = groupedActivities[index];
                      final isLastGroup = index == groupedActivities.length - 1;
                      return _ActivitySection(
                        group: group,
                        isLastGroup: isLastGroup,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  List<_ActivityEntry> _buildActivitiesFromAdminActivities(
    List<AdminActivity> activities,
  ) {
    final entries = <_ActivityEntry>[];

    for (final activity in activities) {
      entries.add(
        _ActivityEntry(
          icon: _activityIcon(activity.type),
          color: _activityColor(activity.type),
          label: _activityLabel(activity.type),
          title: activity.description,
          time: activity.createdAt,
          subtitle: _activitySubtitle(activity),
          photoUrl: activity.photoUrl,
        ),
      );
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries;
  }

  List<_ActivityGroup> _groupActivitiesByDate(List<_ActivityEntry> activities) {
    if (activities.isEmpty) return const [];

    final groups = <String, _ActivityGroup>{};
    final orderedKeys = <String>[];
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    for (final activity in activities) {
      final localTime = activity.time.toLocal();
      final date = DateTime(localTime.year, localTime.month, localTime.day);
      final dateKey = date.toIso8601String();
      final groupLabel = _formatActivityDateLabel(
        date,
        todayStart: todayStart,
        yesterdayStart: yesterdayStart,
      );

      final existing = groups[dateKey];
      if (existing == null) {
        orderedKeys.add(dateKey);
        groups[dateKey] = _ActivityGroup(
          label: groupLabel,
          activities: [activity],
        );
      } else {
        groups[dateKey] = _ActivityGroup(
          label: existing.label,
          activities: [...existing.activities, activity],
        );
      }
    }

    return orderedKeys.map((key) => groups[key]!).toList();
  }
}

class _ActivityHeaderTitle extends StatelessWidget {
  const _ActivityHeaderTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.secondaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ActivityEntry {
  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final DateTime time;
  final String subtitle;
  final String? photoUrl;

  const _ActivityEntry({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    required this.time,
    required this.subtitle,
    required this.photoUrl,
  });
}

class _ActivityGroup {
  final String label;
  final List<_ActivityEntry> activities;

  const _ActivityGroup({required this.label, required this.activities});
}

class _ActivitySection extends StatelessWidget {
  final _ActivityGroup group;
  final bool isLastGroup;

  const _ActivitySection({required this.group, required this.isLastGroup});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLastGroup ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              group.label,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ...List.generate(group.activities.length, (index) {
            final activity = group.activities[index];
            final isLast = index == group.activities.length - 1;
            return _ActivityCard(activity: activity, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _ActivityEmptyState extends StatelessWidget {
  const _ActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 44, 24, 40),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada aktivitas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aktivitas RT akan muncul di sini setelah Anda melakukan tindakan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _activityIcon(String type) {
  return switch (type) {
    'verification' => Icons.verified_user_rounded,
    'announcement' => Icons.campaign_rounded,
    'poll' => Icons.how_to_vote_rounded,
    'report_completed' => Icons.verified_rounded,
    'warga_removed' => Icons.person_remove_rounded,
    _ => Icons.history_rounded,
  };
}

Color _activityColor(String type) {
  return switch (type) {
    'verification' => AppTheme.primaryColor,
    'announcement' => AppTheme.statusMedium,
    'poll' => const Color(0xFF7C3AED),
    'report_completed' => AppTheme.statusLow,
    'warga_removed' => AppTheme.statusHigh,
    _ => AppTheme.textSecondaryColor,
  };
}

String _activityLabel(String type) {
  return switch (type) {
    'verification' => 'Verifikasi Warga',
    'announcement' => 'Pengumuman',
    'poll' => 'Voting',
    'report_completed' => 'Laporan',
    'warga_removed' => 'Warga Dihapus',
    _ => 'Aktivitas RT',
  };
}

String _activitySubtitle(AdminActivity activity) {
  final relatedId = activity.relatedId?.trim();
  switch (activity.type) {
    case 'verification':
      return relatedId?.isNotEmpty == true
          ? 'ID terkait: $relatedId'
          : 'Verifikasi data warga';
    case 'announcement':
      return relatedId?.isNotEmpty == true
          ? 'ID pengumuman: $relatedId'
          : 'Pengumuman RT';
    case 'poll':
      return relatedId?.isNotEmpty == true
          ? 'ID voting: $relatedId'
          : 'Voting RT';
    case 'report_completed':
      return activity.photoUrl?.trim().isNotEmpty == true
          ? 'Bukti foto tersedia'
          : 'Laporan selesai diproses';
    case 'warga_removed':
      return relatedId?.isNotEmpty == true
          ? 'ID warga: $relatedId'
          : 'Warga dihapus dari data';
    default:
      return relatedId?.isNotEmpty == true
          ? 'ID terkait: $relatedId'
          : 'Aktivitas RT';
  }
}

String _formatActivityDateLabel(
  DateTime dateTime, {
  required DateTime todayStart,
  required DateTime yesterdayStart,
}) {
  if (dateTime == todayStart) return 'Hari Ini';
  if (dateTime == yesterdayStart) return 'Kemarin';

  const monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${dateTime.day} ${monthNames[dateTime.month - 1]} ${dateTime.year}';
}

class _ActivityCard extends StatelessWidget {
  final _ActivityEntry activity;
  final bool isLast;

  const _ActivityCard({required this.activity, required this.isLast});

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
                  height: 44,
                  color: AppTheme.outlineVariantColor.withValues(alpha: 0.4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
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
                                    color: activity.color.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    activity.label,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
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
                                    fontWeight: FontWeight.w500,
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
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                                height: 1.28,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              activity.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activity.photoUrl?.trim().isNotEmpty == true) ...[
                        const SizedBox(width: 12),
                        _ActivityThumbnail(photoUrl: activity.photoUrl!),
                      ],
                    ],
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

class _ActivityThumbnail extends StatelessWidget {
  final String photoUrl;

  const _ActivityThumbnail({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        color: AppTheme.surfaceContainerLow,
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              color: AppTheme.surfaceContainerLow,
              child: const Icon(
                Icons.image_not_supported_rounded,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
            );
          },
        ),
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
