import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/dashboard_top_section.dart';
import '../../widgets/status_badge.dart';
import 'buat_pengumuman_admin.dart';
import 'buat_voting_admin.dart';
import 'detail_laporan_admin.dart';
import '../shared/detail_voting_screen.dart';

String _formatWibDate(DateTime dateTime) {
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

  final wib = dateTime.toUtc().add(const Duration(hours: 7));
  final day = wib.day.toString().padLeft(2, '0');
  final month = months[wib.month - 1];
  final hour = wib.hour.toString().padLeft(2, '0');
  final minute = wib.minute.toString().padLeft(2, '0');
  return '$day $month ${wib.year}, $hour:$minute WIB';
}

String _formatPollDeadline(Poll poll) {
  final match = RegExp(r'^poll-(\d+)$').firstMatch(poll.id);
  if (match != null) {
    final microseconds = int.tryParse(match.group(1) ?? '');
    if (microseconds != null) {
      final createdAt = DateTime.fromMicrosecondsSinceEpoch(
        microseconds,
        isUtc: true,
      );
      final deadline = createdAt.add(const Duration(days: 7));
      return _formatWibDate(deadline);
    }
  }

  return poll.isActive ? 'Belum diatur' : 'Sudah dinonaktifkan';
}

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({
    super.key,
    this.onGoToPendingWarga,
    this.onGoToApprovedWarga,
  });

  final VoidCallback? onGoToPendingWarga;
  final VoidCallback? onGoToApprovedWarga;

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reportSectionKey = GlobalKey();

  String _selectedStatusFilter = 'Semua Status';
  String _selectedCategoryFilter = 'Semua Kategori';

  final List<String> _statusOptions = const [
    'Semua Status',
    'Baru',
    'Diproses',
    'Selesai',
  ];

  final List<String> _categoryOptions = const [
    'Semua Kategori',
    'Infrastruktur',
    'Kebersihan',
    'Keamanan',
    'Penerangan Jalan',
    'Sosial & Tetangga',
    'Lainnya',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshAnnouncements().catchError((_) {});
      context.read<AppState>().refreshPolls().catchError((_) {});
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} hari yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('infrastruktur')) return Icons.construction_rounded;
    if (value.contains('kebersihan') || value.contains('sampah')) {
      return Icons.delete_rounded;
    }
    if (value.contains('keamanan') || value.contains('aman')) {
      return Icons.security_rounded;
    }
    if (value.contains('penerangan') || value.contains('lampu')) {
      return Icons.lightbulb_rounded;
    }
    if (value.contains('sosial') || value.contains('tetangga')) {
      return Icons.people_rounded;
    }
    return Icons.report_problem_rounded;
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'report_completed':
        return Icons.verified_rounded;
      case 'verification':
        return Icons.verified_user_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'poll':
        return Icons.how_to_vote_rounded;
      case 'warga_removed':
        return Icons.person_remove_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'report_completed':
        return AppTheme.primaryColor;
      case 'verification':
        return const Color(0xFF2563EB);
      case 'announcement':
        return AppTheme.statusMedium;
      case 'poll':
        return const Color(0xFF7C3AED);
      case 'warga_removed':
        return AppTheme.statusHigh;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  List<_WeeklyPoint> _buildWeeklyPoints(List<Report> reports) {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final count = reports.where((report) {
        final reportDay = DateTime(
          report.createdAt.year,
          report.createdAt.month,
          report.createdAt.day,
        );
        return reportDay == day;
      }).length;

      return _WeeklyPoint(label: labels[day.weekday - 1], value: count);
    });
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  Future<void> _openAnnouncementForm(
    BuildContext context, {
    Announcement? announcement,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BuatPengumumanAdminScreen(announcement: announcement),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      await context.read<AppState>().refreshAnnouncements().catchError((_) {});
    }
  }

  void _showAllAnnouncementsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer<AppState>(
              builder: (context, state, _) {
                final sortedAnnouncements = [...state.announcements]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariantColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Text(
                          'Semua Pengumuman',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: sortedAnnouncements.isEmpty
                            ? const _EmptyDashboardState(
                                icon: Icons.campaign_rounded,
                                title: 'Belum ada pengumuman',
                                subtitle:
                                    'Pengumuman terbaru akan tampil di sini.',
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                itemCount: sortedAnnouncements.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final announcement =
                                      sortedAnnouncements[index];
                                  return _AdminAnnouncementCard(
                                    announcement: announcement,
                                    onEditTap: () => _openAnnouncementForm(
                                      context,
                                      announcement: announcement,
                                    ),
                                    onDeleteTap: () =>
                                        _confirmDeleteAnnouncement(
                                          context,
                                          announcement,
                                        ),
                                    showLatestBadge: false,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteAnnouncement(
    BuildContext context,
    Announcement announcement,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pengumuman?'),
        content: Text(
          'Pengumuman "${announcement.title}" akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.statusHigh),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final state = context.read<AppState>();
    await state.deleteAnnouncement(announcement.id);
    await state.refreshAnnouncements().catchError((_) {});
  }

  Future<void> _openPollForm(BuildContext context, {Poll? poll}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BuatVotingAdminScreen(poll: poll)),
    );

    if (!mounted) return;
    if (result == true) {
      await context.read<AppState>().refreshPolls().catchError((_) {});
    }
  }

  void _openPendingWargaTab() {
    widget.onGoToPendingWarga?.call();
  }

  void _openApprovedWargaTab() {
    widget.onGoToApprovedWarga?.call();
  }

  Future<void> _confirmDeletePoll(BuildContext context, Poll poll) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Voting?'),
        content: Text(
          'Voting "${poll.question}" akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.statusHigh),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final state = context.read<AppState>();
    await state.deletePoll(poll.id);
    await state.refreshPolls().catchError((_) {});
  }

  Future<void> _confirmDeactivatePoll(BuildContext context, Poll poll) async {
    final shouldDeactivate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nonaktifkan Voting?'),
        content: Text(
          'Voting "${poll.question}" akan dinonaktifkan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.statusHigh),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (shouldDeactivate != true || !mounted) return;

    await context.read<AppState>().updatePoll(
      pollId: poll.id,
      question: poll.question,
      isActive: false,
      options: poll.options,
    );
    await context.read<AppState>().refreshPolls().catchError((_) {});
  }

  void _showAllPollsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Consumer<AppState>(
              builder: (context, state, _) {
                final sortedPolls = [...state.polls]
                  ..sort((a, b) {
                    if (a.isActive != b.isActive) {
                      return a.isActive ? -1 : 1;
                    }
                    return 0;
                  });
                final maxVotes = sortedPolls.fold<int>(
                  0,
                  (max, poll) => poll.totalVotes > max ? poll.totalVotes : max,
                );

                return Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariantColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Semua Voting',
                                      style: TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Daftar voting aktif maupun nonaktif.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: sortedPolls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final poll = sortedPolls[index];
                              return _AdminPollCard(
                                poll: poll,
                                maxVotes: maxVotes,
                                onDetailTap: () {
                                  Navigator.of(sheetContext).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailVotingScreen(pollId: poll.id),
                                    ),
                                  );
                                },
                                onDeactivateTap: poll.isActive
                                    ? () => _confirmDeactivatePoll(
                                        sheetContext,
                                        poll,
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAllReportsSheet(
    BuildContext context, {
    required List<Report> reports,
  }) {
    final sortedReports = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariantColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semua Laporan',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Daftar laporan masuk terbaru dari warga.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: sortedReports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final report = sortedReports[index];
                          return _AdminReportCard(
                            report: report,
                            categoryIcon: _categoryIcon(report.category),
                            onTap: () {
                              Navigator.of(sheetContext).push(
                                MaterialPageRoute(
                                  builder: (_) => DetailLaporanAdminScreen(
                                    reportId: report.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'warga':
        _openPendingWargaTab();
        break;
      case 'announcement':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BuatPengumumanAdminScreen()),
        );
        break;
      case 'poll':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BuatVotingAdminScreen()),
        );
        break;
      case 'reports':
        _scrollToSection(_reportSectionKey);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;
    final isReportsLoading = state.reportsLoading;
    final reportError = state.reportsError;
    final announcements = state.announcements;
    final isAnnouncementsLoading = state.announcementsLoading;
    final announcementError = state.announcementsError;
    final polls = state.polls;
    final isPollsLoading = state.pollsLoading;
    final pollsError = state.pollsError;
    final userJabatan = user?.jabatan?.toUpperCase();
    final canAddAnnouncement =
        user?.role == UserRole.admin && (userJabatan?.contains('RT') ?? false);

    final reports = state.adminReports;
    final newCount = reports
        .where((r) => r.status == ReportStatus.submitted)
        .length;
    final processedCount = reports
        .where((r) => r.status == ReportStatus.processed)
        .length;
    final resolvedCount = reports
        .where((r) => r.status == ReportStatus.resolved)
        .length;
    final verifiedWargaCount = state.verifiedWarga.length;
    final pendingWargaCount = state.pendingWarga.length;
    final totalWargaCount = state.allWarga.length;
    final sortedAnnouncements = [...announcements]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestAnnouncement = sortedAnnouncements.isNotEmpty
        ? sortedAnnouncements.first
        : null;
    final activePolls = polls.where((poll) => poll.isActive).toList();
    final highlightedPoll = activePolls.isNotEmpty ? activePolls.first : null;
    final maxPollVotes = polls.fold<int>(
      0,
      (max, poll) => poll.totalVotes > max ? poll.totalVotes : max,
    );
    final sortedReports = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestReport = sortedReports.isNotEmpty ? sortedReports.first : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardTopSection(user: user),
                const SizedBox(height: 18),
                _buildHeroCard(
                  context,
                  totalWargaCount: totalWargaCount,
                  verifiedWargaCount: verifiedWargaCount,
                  pendingWargaCount: pendingWargaCount,
                ),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Statistik Hari Ini',
                  subtitle: 'Ringkasan cepat aktivitas dan kondisi terkini',
                ),
                const SizedBox(height: 16),
                _buildStatisticsGrid(
                  newCount: newCount,
                  processedCount: processedCount,
                  resolvedCount: resolvedCount,
                  totalWargaCount: totalWargaCount,
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Akses Cepat',
                  subtitle: 'Aksi yang paling sering digunakan RT',
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.outlineVariantColor.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengumuman RT',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Informasi terbaru dari Ketua RT',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showAllAnnouncementsSheet(context),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isAnnouncementsLoading && latestAnnouncement == null)
                        const _LoadingDashboardState(
                          title: 'Memuat pengumuman',
                          subtitle: 'Mengambil data pengumuman dari Supabase.',
                        )
                      else if (announcementError != null &&
                          latestAnnouncement == null)
                        _AnnouncementSectionErrorState(
                          message: announcementError,
                          onRetry: () {
                            state.refreshAnnouncements().catchError((_) {});
                          },
                        )
                      else if (latestAnnouncement == null)
                        const _EmptyDashboardState(
                          icon: Icons.campaign_rounded,
                          title: 'Belum ada pengumuman',
                          subtitle: 'Pengumuman terbaru akan tampil di sini.',
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AdminAnnouncementCard(
                              announcement: latestAnnouncement,
                              onEditTap: () => _openAnnouncementForm(
                                context,
                                announcement: latestAnnouncement,
                              ),
                              onDeleteTap: () => _confirmDeleteAnnouncement(
                                context,
                                latestAnnouncement,
                              ),
                              showLatestBadge: true,
                            ),
                          ],
                        ),
                      if (canAddAnnouncement) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openAnnouncementForm(context),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah Pengumuman'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.outlineVariantColor.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voting RT',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Voting aktif yang sedang berjalan',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAllPollsSheet(context),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isPollsLoading && highlightedPoll == null)
                        const _LoadingDashboardState(
                          title: 'Memuat voting',
                          subtitle: 'Mengambil data voting dari Supabase.',
                        )
                      else if (pollsError != null && highlightedPoll == null)
                        _PollSectionErrorState(
                          message: pollsError,
                          onRetry: () {
                            context.read<AppState>().refreshPolls().catchError(
                              (_) {},
                            );
                          },
                        )
                      else if (highlightedPoll == null)
                        const _EmptyDashboardState(
                          icon: Icons.how_to_vote_rounded,
                          title: 'Belum ada voting aktif',
                          subtitle:
                              'Voting aktif akan tampil di sini ketika tersedia.',
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AdminPollCard(
                              poll: highlightedPoll,
                              maxVotes: maxPollVotes,
                              onDetailTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetailVotingScreen(
                                      pollId: highlightedPoll.id,
                                    ),
                                  ),
                                );
                              },
                              onDeactivateTap: () => _confirmDeactivatePoll(
                                context,
                                highlightedPoll,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openPollForm(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Voting'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  key: _reportSectionKey,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.outlineVariantColor.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Laporan Masuk',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Laporan terbaru dari warga.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showAllReportsSheet(context, reports: reports),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (isReportsLoading && latestReport == null)
                        const _LoadingDashboardState(
                          title: 'Memuat laporan masuk',
                          subtitle: 'Mengambil data laporan dari Supabase.',
                        )
                      else if (reportError != null && latestReport == null)
                        _ReportSectionErrorState(
                          message: reportError,
                          onRetry: () => state.refreshAdminReports(),
                        )
                      else if (latestReport == null)
                        const _EmptyDashboardState(
                          icon: Icons.inbox_rounded,
                          title: 'Belum ada laporan masuk',
                          subtitle:
                              'Laporan warga yang baru masuk akan tampil di sini.',
                        )
                      else
                        _AdminReportCard(
                          report: latestReport,
                          categoryIcon: _categoryIcon(latestReport.category),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailLaporanAdminScreen(
                                  reportId: latestReport.id,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${user?.name ?? 'Pak RT'} \u{1F44B}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pantau dan kelola laporan warga dengan efisien.',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          tooltip: 'Aksi cepat',
          icon: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.outlineVariantColor.withValues(alpha: 0.6),
              ),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          onSelected: (value) {
            if (value == 'announcement') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BuatPengumumanAdminScreen(),
                ),
              );
            } else if (value == 'poll') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BuatVotingAdminScreen(),
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'announcement',
              child: Row(
                children: [
                  Icon(
                    Icons.campaign_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text('Buat Pengumuman'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'poll',
              child: Row(
                children: [
                  Icon(
                    Icons.how_to_vote_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text('Buat Voting'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.textPrimaryColor,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceContainerLow,
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          backgroundImage: user?.avatarUrl.isNotEmpty == true
              ? NetworkImage(user!.avatarUrl)
              : null,
          child: user?.avatarUrl.isNotEmpty == true
              ? null
              : const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required int totalWargaCount,
    required int verifiedWargaCount,
    required int pendingWargaCount,
  }) {
    return InkWell(
      onTap: () {
        _openApprovedWargaTab();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B6B3A), Color(0xFF0F8A4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -14,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 10,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Warga',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalWargaCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Terverifikasi: $verifiedWargaCount  |  Menunggu: $pendingWargaCount',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid({
    required int newCount,
    required int processedCount,
    required int resolvedCount,
    required int totalWargaCount,
  }) {
    final cards = [
      _StatisticData(
        title: 'Laporan Baru',
        value: newCount,
        icon: Icons.inbox_rounded,
        color: AppTheme.statusHigh,
      ),
      _StatisticData(
        title: 'Sedang Diproses',
        value: processedCount,
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF2563EB),
      ),
      _StatisticData(
        title: 'Laporan Selesai',
        value: resolvedCount,
        icon: Icons.verified_rounded,
        color: AppTheme.primaryColor,
      ),
      _StatisticData(
        title: 'Total Warga',
        value: totalWargaCount,
        icon: Icons.groups_rounded,
        color: AppTheme.statusMedium,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.26,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return _StatisticCard(data: item);
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'Verifikasi Warga',
        icon: Icons.verified_user_rounded,
        onTap: () => _openQuickAction(context, 'warga'),
      ),
      _QuickActionData(
        label: 'Pengumuman',
        icon: Icons.campaign_rounded,
        onTap: () => _openQuickAction(context, 'announcement'),
      ),
      _QuickActionData(
        label: 'Voting',
        icon: Icons.how_to_vote_rounded,
        onTap: () => _openQuickAction(context, 'poll'),
      ),
      _QuickActionData(
        label: 'Kelola Laporan',
        icon: Icons.assignment_turned_in_rounded,
        onTap: () => _openQuickAction(context, 'reports'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final childAspectRatio = constraints.maxWidth > 700 ? 3.2 : 2.45;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _QuickActionCard(data: actions[index]);
          },
        );
      },
    );
  }

  Widget _buildReportFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final filterRow = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: _FilterDropdown(
                value: _selectedStatusFilter,
                options: _statusOptions,
                icon: Icons.filter_alt_rounded,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatusFilter = value);
                  }
                },
              ),
            ),
            SizedBox(
              width: isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: _FilterDropdown(
                value: _selectedCategoryFilter,
                options: _categoryOptions,
                icon: Icons.category_rounded,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategoryFilter = value);
                  }
                },
              ),
            ),
          ],
        );

        return filterRow;
      },
    );
  }
}

class _AdminPollCard extends StatelessWidget {
  const _AdminPollCard({
    required this.poll,
    this.maxVotes = 0,
    required this.onDetailTap,
    this.onDeactivateTap,
  });

  final Poll poll;
  final int maxVotes;
  final VoidCallback onDetailTap;
  final VoidCallback? onDeactivateTap;

  @override
  Widget build(BuildContext context) {
    final progressValue = maxVotes <= 0
        ? (poll.totalVotes > 0 ? 1.0 : 0.0)
        : (poll.totalVotes / maxVotes).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetailTap,
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
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.how_to_vote_rounded,
                      color: poll.isActive
                          ? AppTheme.primaryColor
                          : AppTheme.statusHigh,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                poll.question,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _PollStatusBadge(
                              isActive: poll.isActive,
                              label: poll.isActive ? 'Aktif' : 'Nonaktif',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Progress pemilih',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${poll.totalVotes} suara',
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 6,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.10,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Berakhir ${_formatPollDeadline(poll)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDetailTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: AppTheme.outlineVariantColor.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (poll.isActive && onDeactivateTap != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDeactivateTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusHigh,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: AppTheme.statusHigh.withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Nonaktifkan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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

class _PollSectionErrorState extends StatelessWidget {
  const _PollSectionErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.statusHigh,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _PollStatusBadge extends StatelessWidget {
  const _PollStatusBadge({required this.isActive, this.label});

  final bool isActive;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryColor : AppTheme.statusHigh;
    final resolvedLabel = label ?? (isActive ? 'Aktif' : 'Nonaktif');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        resolvedLabel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _StatisticData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatisticData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatisticCard extends StatelessWidget {
  final _StatisticData data;

  const _StatisticCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          Text(
            data.value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: AppTheme.primaryColor, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyPoint {
  final String label;
  final int value;

  const _WeeklyPoint({required this.label, required this.value});
}

class _WeeklyReportChart extends StatelessWidget {
  final List<_WeeklyPoint> points;

  const _WeeklyReportChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );
    final hasData = maxValue > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Laporan 7 Hari Terakhir',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasData)
            const _EmptyDashboardState(
              icon: Icons.bar_chart_rounded,
              title: 'Belum ada data laporan',
              subtitle: 'Grafik akan terisi otomatis saat laporan baru masuk.',
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < points.length; i++) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              points[i].value.toString(),
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 120,
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                height:
                                    14 + ((points[i].value / maxValue) * 106),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0B6B3A),
                                      Color(0xFF18A65A),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              points[i].label,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.7),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(icon, size: 18, color: AppTheme.primaryColor),
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map(
                (opt) => DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final Report report;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const _AdminReportCard({
    required this.report,
    required this.categoryIcon,
    required this.onTap,
  });

  bool get _hasPhoto =>
      report.reportPhotoUrl != null && report.reportPhotoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 520;
              final preview = ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: isWide ? 112 : 92,
                  height: isWide ? 112 : 92,
                  child: _hasPhoto
                      ? Image.network(
                          report.reportPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _ReportFallbackIcon(icon: categoryIcon);
                          },
                        )
                      : _ReportFallbackIcon(icon: categoryIcon),
                ),
              );

              final content = Column(
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
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PriorityBadge(priority: report.priority),
                      _MetaPill(
                        icon: Icons.location_on_outlined,
                        label:
                            report.locationLabel ?? 'Lokasi belum ditentukan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formatWibDate(report.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preview,
                        const SizedBox(width: 14),
                        Expanded(child: content),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [preview, const SizedBox(height: 12), content],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

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
          Icon(icon, size: 13, color: AppTheme.primaryColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportFallbackIcon extends StatelessWidget {
  final IconData icon;

  const _ReportFallbackIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 24),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AdminActivity activity;
  final IconData icon;
  final Color color;
  final String Function(DateTime) formatTimeAgo;

  const _ActivityTile({
    required this.activity,
    required this.icon,
    required this.color,
    required this.formatTimeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatTimeAgo(activity.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActivityChip(label: activity.type.replaceAll('_', ' ')),
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

class _ActivityChip extends StatelessWidget {
  final String label;

  const _ActivityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyDashboardState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
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
            child: Icon(icon, color: AppTheme.primaryColor, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDashboardState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoadingDashboardState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSectionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ReportSectionErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.statusHigh,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _AnnouncementSectionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AnnouncementSectionErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.statusHigh,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _AdminAnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool showLatestBadge;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _AdminAnnouncementCard({
    required this.announcement,
    this.showLatestBadge = false,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
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
                            ),
                            if (showLatestBadge) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Terbaru',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatWibDate(announcement.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onEditTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: AppTheme.outlineVariantColor.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDeleteTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statusHigh,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: AppTheme.statusHigh.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
