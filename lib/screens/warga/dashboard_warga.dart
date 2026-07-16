import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'daftar_pengumuman.dart';
import 'detail_pengumuman.dart';
import '../shared/detail_voting_screen.dart';

class DashboardWargaScreen extends StatefulWidget {
  const DashboardWargaScreen({super.key});

  @override
  State<DashboardWargaScreen> createState() => _DashboardWargaScreenState();
}

class _DashboardWargaScreenState extends State<DashboardWargaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshPolls().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;
    final isReportsLoading = state.reportsLoading;
    final reportError = state.reportsError;
    final isAnnouncementsLoading = state.announcementsLoading;
    final announcementError = state.announcementsError;
    final isPollsLoading = state.pollsLoading;
    final pollsError = state.pollsError;
    final completedReports = state.completedReportsWithPhotos;
    final visibleCompletedReports = completedReports.take(2).toList();
    final currentRtRw = user?.rtRw?.trim() ?? '';
    final announcements = state.announcements
        .where(
          (announcement) =>
              announcement.rtRw.trim().isNotEmpty &&
              announcement.rtRw.trim() == currentRtRw,
        )
        .take(2)
        .toList();
    final myReports = state.myReports;
    final visibleMyReports = myReports.take(2).toList();
    final activePolls = state.polls.where((poll) => poll.isActive).toList();
    final poll = activePolls.isNotEmpty ? activePolls.first : null;
    final userId = user?.id;
    final hasVoted =
        poll != null && userId != null && poll.userVotes.containsKey(userId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildGreetingCard(user),
                const SizedBox(height: 18),
                _buildHeroBanner(context),
                const SizedBox(height: 22),
                _buildSectionHeader(
                  title: 'Status Laporan Saya',
                  subtitle: 'Pantau laporan yang sudah Anda kirim',
                  actionLabel: 'Lihat Semua',
                  onActionTap: () =>
                      _showMyReportsSheet(context, reports: myReports),
                ),
                const SizedBox(height: 14),
                if (isReportsLoading && myReports.isEmpty)
                  _buildSectionLoadingIndicator(
                    message: 'Memuat laporan Anda...',
                    height: 190,
                  )
                else if (reportError != null && myReports.isEmpty)
                  _buildReportErrorState(
                    message: reportError,
                    onRetry: () => state.refreshMyReports(),
                    height: 190,
                  )
                else if (myReports.isEmpty)
                  _buildEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Belum ada laporan aktif',
                    subtitle: 'Gunakan tombol Laporkan Sekarang untuk mulai.',
                  )
                else
                  SizedBox(
                    height: 188,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleMyReports.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return _ReportStatusCard(
                          report: visibleMyReports[index],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  title: 'Pengumuman Terbaru',
                  subtitle: 'Informasi penting untuk warga',
                  actionLabel: 'Lihat Semua',
                  onActionTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DaftarPengumumanScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (isAnnouncementsLoading && announcements.isEmpty)
                  _buildSectionLoadingIndicator(
                    message: 'Memuat pengumuman...',
                    height: 228,
                  )
                else if (announcementError != null && announcements.isEmpty)
                  _buildErrorSection(
                    title: 'Pengumuman Terbaru',
                    subtitle: announcementError,
                    onRetry: () {
                      state.refreshAnnouncements().catchError((_) {});
                    },
                    height: 228,
                  )
                else if (announcements.isEmpty)
                  _buildEmptyState(
                    icon: Icons.campaign_rounded,
                    title: 'Belum ada pengumuman baru',
                    subtitle: 'Semua pengumuman akan tampil di sini.',
                  )
                else
                  SizedBox(
                    height: 228,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: announcements.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return _AnnouncementCard(
                          announcement: announcements[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailPengumumanScreen(
                                  announcement: announcements[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 28),
                if (isReportsLoading && completedReports.isEmpty)
                  _buildLoadingSection(
                    title: 'Bukti Selesai dari RT',
                    subtitle: 'Memuat laporan dari Supabase...',
                    height: 252,
                  )
                else if (reportError != null && completedReports.isEmpty)
                  _buildErrorSection(
                    title: 'Bukti Selesai dari RT',
                    subtitle: reportError,
                    onRetry: () => state.refreshMyReports(),
                    height: 252,
                  )
                else if (completedReports.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Bukti Selesai dari RT',
                    subtitle: 'Laporan yang sudah ditindaklanjuti',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 252,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleCompletedReports.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return _CompletionProofCard(
                          report: visibleCompletedReports[index],
                          rtRw: user?.rtRw,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                _buildSectionHeader(
                  title: 'Voting Lingkungan',
                  subtitle: 'Berikan suara untuk keputusan bersama warga',
                ),
                const SizedBox(height: 14),
                if (isPollsLoading && poll == null)
                  _buildSectionLoadingIndicator(
                    message: 'Memuat voting...',
                    height: 180,
                  )
                else if (pollsError != null && poll == null)
                  _buildErrorSection(
                    title: 'Voting Lingkungan',
                    subtitle: pollsError,
                    onRetry: () => state.refreshPolls().catchError((_) {}),
                    height: 180,
                  )
                else if (poll == null)
                  _buildEmptyState(
                    icon: Icons.how_to_vote_rounded,
                    title: 'Tidak ada voting aktif',
                    subtitle: 'Voting aktif akan muncul di sini.',
                  )
                else
                  _buildPollSummaryCard(
                    context,
                    poll: poll,
                    hasVoted: hasVoted,
                    onViewTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailVotingScreen(pollId: poll.id),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection({
    required String title,
    required String subtitle,
    required double height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 16),
        _buildSectionLoadingIndicator(
          message: 'Sedang memuat data laporan...',
          height: height,
        ),
      ],
    );
  }

  Widget _buildSectionLoadingIndicator({
    required String message,
    required double height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection({
    required String title,
    required String subtitle,
    required VoidCallback onRetry,
    required double height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 16),
        _buildReportErrorState(
          message: subtitle,
          onRetry: onRetry,
          height: height,
        ),
      ],
    );
  }

  Widget _buildReportErrorState({
    required String message,
    required VoidCallback onRetry,
    required double height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.statusHigh,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Lapor Warga',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Warga peduli lingkungan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
      ],
    );
  }

  Widget _buildGreetingCard(AppUser? user) {
    final rtRw = user?.rtRw;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Pagi',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'Warga',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoChip(
                  icon: Icons.location_on_rounded,
                  label: rtRw != null && rtRw.isNotEmpty
                      ? 'RT/RW $rtRw'
                      : 'RT/RW belum tersedia',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primaryColor,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: 16,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTag(
                      label: 'Peduli lingkungan',
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.08,
                      ),
                      textColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Bersama Menjaga Lingkungan',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Laporkan masalah di sekitar Anda agar segera ditindaklanjuti RT.',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/buat-laporan');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Laporkan Sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(
                width: 118,
                height: 170,
                child: _EnvironmentalIllustration(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessRow(BuildContext context) {
    final items = <_QuickActionItem>[
      _QuickActionItem(
        label: 'Lapor',
        icon: Icons.assignment_rounded,
        onTap: () => Navigator.of(context).pushNamed('/buat-laporan'),
      ),
      _QuickActionItem(
        label: 'Pengumuman',
        icon: Icons.campaign_rounded,
        onTap: () {},
      ),
      _QuickActionItem(
        label: 'Aktivitas',
        icon: Icons.timeline_rounded,
        onTap: () {},
      ),
      _QuickActionItem(
        label: 'Bantuan',
        icon: Icons.help_rounded,
        onTap: () {},
      ),
    ];

    return LayoutBuilder(
      builder: (context, _) {
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(item: items[i])),
            ],
          ],
        );
      },
    );
  }

  void _showMyReportsSheet(
    BuildContext context, {
    required List<Report> reports,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.42,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Text(
                      'Semua Status Laporan',
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: double.infinity,
                          child: _ReportStatusCard(report: reports[index]),
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
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildPollSummaryCard(
    BuildContext context, {
    required Poll poll,
    required bool hasVoted,
    required VoidCallback onViewTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.6),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.how_to_vote_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Voting aktif',
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const _PollStatusBadge(label: 'Aktif'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  poll.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${poll.totalVotes} suara',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (hasVoted)
                      const _PollStatusBadge(label: 'Sudah Memilih'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: TextButton(
              onPressed: onViewTap,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                hasVoted ? 'Lihat Hasil' : 'Pilih',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollStatusBadge extends StatelessWidget {
  final String label;

  const _PollStatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isClosed = label.toLowerCase() == 'ditutup';
    final color = isClosed ? AppTheme.statusHigh : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionItem item;

  const _QuickActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.8),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: AppTheme.primaryColor, size: 27),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionProofCard extends StatelessWidget {
  final Report report;
  final String? rtRw;

  const _CompletionProofCard({required this.report, required this.rtRw});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 136,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    report.completionPhotoUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _CompletionFallback(
                        icon: _categoryIcon(report.category),
                      );
                    },
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SectionTag(
                      label: 'SELESAI',
                      backgroundColor: AppTheme.primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.citizenName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rtRw != null && rtRw!.isNotEmpty
                              ? 'RT/RW $rtRw'
                              : 'RT/RW belum tersedia',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(report.completedAt ?? report.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 10,
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
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 286,
          height: 210,
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
              const SizedBox(height: 14),
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
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(announcement.createdAt),
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
      ),
    );
  }
}

class _ReportStatusCard extends StatelessWidget {
  final Report report;

  const _ReportStatusCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 314,
      height: 160,
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportLeading(report: report),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.locationLabel ?? 'Lokasi belum ditentukan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _PriorityBadge(priority: report.priority),
                    _StatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppTheme.outlineColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _timeAgo(report.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.outlineColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _ReportLeading extends StatelessWidget {
  final Report report;

  const _ReportLeading({required this.report});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        report.reportPhotoUrl != null &&
        report.reportPhotoUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 92,
        height: 136,
        child: hasPhoto
            ? Image.network(
                report.reportPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _CompletionFallback(
                    icon: _categoryIcon(report.category),
                  );
                },
              )
            : _CompletionFallback(icon: _categoryIcon(report.category)),
      ),
    );
  }
}

class _CompletionFallback extends StatelessWidget {
  final IconData icon;

  const _CompletionFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 24),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final ReportPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      ReportPriority.high => AppTheme.statusHigh,
      ReportPriority.medium => AppTheme.statusMedium,
      ReportPriority.low => AppTheme.statusLow,
    };

    return _InfoChip(
      icon: Icons.flag_rounded,
      label: _priorityLabel(priority),
      backgroundColor: color.withValues(alpha: 0.10),
      iconColor: color,
      textColor: color,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReportStatus.submitted => AppTheme.statusMedium,
      ReportStatus.processed => const Color(0xFF2563EB),
      ReportStatus.resolved => AppTheme.primaryColor,
    };

    return _InfoChip(
      icon: Icons.verified_rounded,
      label: _statusLabel(status),
      backgroundColor: color.withValues(alpha: 0.10),
      iconColor: color,
      textColor: color,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.backgroundColor = AppTheme.surfaceContainerLow,
    this.iconColor = AppTheme.primaryColor,
    this.textColor = AppTheme.textSecondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTag extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _SectionTag({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EnvironmentalIllustration extends StatelessWidget {
  const _EnvironmentalIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 8,
          top: 18,
          child: _IllustrationOrb(
            size: 76,
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 18,
          child: _IllustrationOrb(
            size: 54,
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          top: 6,
          right: 18,
          child: Icon(
            Icons.nature_rounded,
            color: AppTheme.primaryColor.withValues(alpha: 0.26),
            size: 34,
          ),
        ),
        Positioned(
          bottom: 18,
          left: 14,
          child: Icon(
            Icons.water_drop_rounded,
            color: AppTheme.primaryColor.withValues(alpha: 0.22),
            size: 24,
          ),
        ),
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.95),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 54),
        ),
      ],
    );
  }
}

class _IllustrationOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _IllustrationOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('infrastruktur')) return Icons.construction_rounded;
  if (value.contains('penerangan') || value.contains('lampu')) {
    return Icons.lightbulb_rounded;
  }
  if (value.contains('kebersihan') || value.contains('sampah')) {
    return Icons.delete_rounded;
  }
  if (value.contains('aman') || value.contains('keamanan')) {
    return Icons.security_rounded;
  }
  if (value.contains('air') || value.contains('drainase')) {
    return Icons.water_drop_rounded;
  }
  return Icons.report_problem_rounded;
}

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

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = months[dateTime.month - 1];
  return '$day $month ${dateTime.year}';
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays > 0) return '${diff.inDays} hari lalu';
  if (diff.inHours > 0) return '${diff.inHours} jam lalu';
  if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
  return 'Baru saja';
}

String _priorityLabel(ReportPriority priority) {
  return switch (priority) {
    ReportPriority.high => 'Prioritas Tinggi',
    ReportPriority.medium => 'Prioritas Sedang',
    ReportPriority.low => 'Prioritas Rendah',
  };
}

String _statusLabel(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => 'Diajukan',
    ReportStatus.processed => 'Diproses',
    ReportStatus.resolved => 'Selesai',
  };
}
