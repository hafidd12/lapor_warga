import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/status_badge.dart';
import 'buat_pengumuman_admin.dart';
import 'buat_voting_admin.dart';
import 'daftar_warga_admin.dart';
import 'detail_laporan_admin.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reportSectionKey = GlobalKey();
  final GlobalKey _activitySectionKey = GlobalKey();

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

  void _openQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'warga':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarWargaAdminScreen()),
        );
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

    final reports = state.reports;
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

    final filteredReports = reports.where((report) {
      final statusMatch = switch (_selectedStatusFilter) {
        'Baru' => report.status == ReportStatus.submitted,
        'Diproses' => report.status == ReportStatus.processed,
        'Selesai' => report.status == ReportStatus.resolved,
        _ => true,
      };

      final categoryMatch =
          _selectedCategoryFilter == 'Semua Kategori' ||
          report.category.toLowerCase() ==
              _selectedCategoryFilter.toLowerCase();

      return statusMatch && categoryMatch;
    }).toList();

    final weeklyPoints = _buildWeeklyPoints(reports);
    final latestActivities = state.activities.take(5).toList();

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
                _buildHeader(context, user),
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
                _SectionHeader(
                  title: 'Laporan 7 Hari Terakhir',
                  subtitle: 'Distribusi laporan masuk dalam seminggu terakhir',
                ),
                const SizedBox(height: 16),
                _WeeklyReportChart(points: weeklyPoints),
                const SizedBox(height: 28),
                Container(
                  key: _reportSectionKey,
                  padding: const EdgeInsets.all(18),
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
                            child: _SectionHeader(
                              title: 'Daftar Laporan Masuk',
                              subtitle:
                                  'Kelola laporan warga dengan filter yang lebih cepat',
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () =>
                                _scrollToSection(_activitySectionKey),
                            child: const Text(
                              'Lihat Aktivitas',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReportFilters(),
                      const SizedBox(height: 16),
                      if (filteredReports.isEmpty)
                        const _EmptyDashboardState(
                          icon: Icons.inbox_rounded,
                          title: 'Tidak ada laporan yang sesuai',
                          subtitle:
                              'Coba ubah filter untuk melihat laporan lain.',
                        )
                      else
                        Column(
                          children: [
                            for (
                              var i = 0;
                              i < filteredReports.length;
                              i++
                            ) ...[
                              _AdminReportCard(
                                report: filteredReports[i],
                                categoryIcon: _categoryIcon(
                                  filteredReports[i].category,
                                ),
                                formatTimeAgo: _formatTimeAgo,
                                onDetailTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetailLaporanAdminScreen(
                                        reportId: filteredReports[i].id,
                                      ),
                                    ),
                                  );
                                },
                                onFollowUpTap:
                                    filteredReports[i].status ==
                                        ReportStatus.resolved
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetailLaporanAdminScreen(
                                                  reportId:
                                                      filteredReports[i].id,
                                                ),
                                          ),
                                        );
                                      }
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetailLaporanAdminScreen(
                                                  reportId:
                                                      filteredReports[i].id,
                                                ),
                                          ),
                                        );
                                      },
                              ),
                              if (i != filteredReports.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  key: _activitySectionKey,
                  padding: const EdgeInsets.all(18),
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
                      const _SectionHeader(
                        title: 'Aktivitas Terbaru',
                        subtitle: 'Riwayat tindakan terbaru dari admin RT',
                      ),
                      const SizedBox(height: 16),
                      if (latestActivities.isEmpty)
                        const _EmptyDashboardState(
                          icon: Icons.history_rounded,
                          title: 'Belum ada aktivitas terbaru',
                          subtitle:
                              'Saat ada tindakan baru, semuanya muncul di sini.',
                        )
                      else
                        Column(
                          children: [
                            for (
                              var i = 0;
                              i < latestActivities.length;
                              i++
                            ) ...[
                              _ActivityTile(
                                activity: latestActivities[i],
                                icon: _activityIcon(latestActivities[i].type),
                                color: _activityColor(latestActivities[i].type),
                                formatTimeAgo: _formatTimeAgo,
                              ),
                              if (i != latestActivities.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
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
                      const _SectionHeader(
                        title: 'Status Warga',
                        subtitle: 'Ringkasan verifikasi warga yang terdaftar',
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 640;
                          final child = Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _MiniSummaryChip(
                                label: 'Terverifikasi',
                                value: verifiedWargaCount.toString(),
                                color: AppTheme.primaryColor,
                              ),
                              _MiniSummaryChip(
                                label: 'Menunggu',
                                value: pendingWargaCount.toString(),
                                color: AppTheme.statusMedium,
                              ),
                              _MiniSummaryChip(
                                label: 'Total Warga',
                                value: totalWargaCount.toString(),
                                color: const Color(0xFF2563EB),
                              ),
                            ],
                          );
                          return isWide ? child : child;
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarWargaAdminScreen()),
        );
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            _QuickActionCard(data: actions[i]),
          ],
        ],
      ),
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 150,
          height: 92,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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
  final String Function(DateTime) formatTimeAgo;
  final VoidCallback onDetailTap;
  final VoidCallback onFollowUpTap;

  const _AdminReportCard({
    required this.report,
    required this.categoryIcon,
    required this.formatTimeAgo,
    required this.onDetailTap,
    required this.onFollowUpTap,
  });

  bool get _hasPhoto =>
      report.reportPhotoUrl != null && report.reportPhotoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isResolved = report.status == ReportStatus.resolved;

    return Container(
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
              width: isWide ? 116 : 92,
              height: isWide ? 116 : 92,
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PriorityBadge(priority: report.priority),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
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
              const SizedBox(height: 6),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.location_on_outlined,
                    label: report.locationLabel ?? 'Lokasi belum ditentukan',
                  ),
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: formatTimeAgo(report.createdAt),
                  ),
                  _MetaPill(
                    icon: Icons.thumb_up_rounded,
                    label: '${report.votesCount} dukungan',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDetailTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: BorderSide(
                          color: AppTheme.outlineVariantColor.withValues(
                            alpha: 0.9,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Detail',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onFollowUpTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isResolved ? 'Selesai' : 'Tindak Lanjut',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
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
