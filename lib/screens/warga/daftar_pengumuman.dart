import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/notification_bell_button.dart';
import 'detail_pengumuman.dart';

class DaftarPengumumanScreen extends StatelessWidget {
  const DaftarPengumumanScreen({super.key});

  Future<void> _refreshAnnouncements(BuildContext context) async {
    await context.read<AppState>().refreshAnnouncements().catchError((_) {});
  }

  List<Announcement> _filteredAnnouncements(AppState state) {
    final currentRtRw = state.currentUser?.rtRw?.trim() ?? '';
    final announcements = state.announcements
        .where(
          (announcement) =>
              announcement.rtRw.trim().isNotEmpty &&
              announcement.rtRw.trim() == currentRtRw,
        )
        .toList();

    announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return announcements;
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final announcements = _filteredAnnouncements(state);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Semua Pengumuman'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0.5,
        actions: const [NotificationBellButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAnnouncements(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcements.isEmpty)
                _EmptyAnnouncementState(
                  onRefresh: () {
                    state.refreshAnnouncements().catchError((_) {});
                  },
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < announcements.length; i++) ...[
                      _AnnouncementListCard(
                        announcement: announcements[i],
                        formatDate: _formatDate,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailPengumumanScreen(
                                announcement: announcements[i],
                              ),
                            ),
                          );
                        },
                      ),
                      if (i != announcements.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementListCard extends StatelessWidget {
  final Announcement announcement;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _AnnouncementListCard({
    required this.announcement,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formatDate(announcement.createdAt),
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAnnouncementState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyAnnouncementState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada pengumuman.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua pengumuman yang relevan akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRefresh, child: const Text('Muat Ulang')),
        ],
      ),
    );
  }
}
