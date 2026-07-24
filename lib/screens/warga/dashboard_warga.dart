import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/custom_image.dart';
import '../../widgets/announcement_preview_card.dart';
import '../../widgets/dashboard_top_section.dart';
import 'aktivitas_laporan.dart';
import 'daftar_pengumuman.dart';
import 'detail_pengumuman.dart';
import '../shared/detail_voting_screen.dart';

class DashboardWargaScreen extends StatefulWidget {
  const DashboardWargaScreen({super.key, this.onGoToAktivitas});

  final VoidCallback? onGoToAktivitas;

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

  Future<void> _refreshDashboard() async {
    final state = context.read<AppState>();
    await state.refreshCitizenDashboardData().catchError((_) {});
  }

  String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _openReportDetail(BuildContext context, Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailLaporanScreen(report: report)),
    );
  }

  void _showCompletedReportsSheet(
    BuildContext context, {
    required List<Report> reports,
    required String? rtRw,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Text(
                      'Bukti Selesai dari RT',
                      style: TextStyle(
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
                        final report = reports[index];
                        return _CompletionProofCard(
                          report: report,
                          rtRw: rtRw,
                          compact: true,
                          onTap: () => _openReportDetail(context, report),
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

  void _showAllPollsSheet(
    BuildContext context, {
    required List<Poll> polls,
    required String? userId,
  }) {
    final sortedPolls = [...polls]
      ..sort((a, b) {
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        return b.totalVotes.compareTo(a.totalVotes);
      });

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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Text(
                      'Daftar Voting',
                      style: TextStyle(
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
                      itemCount: sortedPolls.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final poll = sortedPolls[index];
                        final isUserVoted =
                            userId != null &&
                            poll.userVotes.containsKey(userId);
                        return _PollListCard(
                          poll: poll,
                          hasVoted: isUserVoted,
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailVotingScreen(pollId: poll.id),
                              ),
                            );
                          },
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

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;
    final goToAktivitas = widget.onGoToAktivitas;
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
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardTopSection(user: user),
                  const SizedBox(height: 18),
                  _buildHeroBanner(context),
                  const SizedBox(height: 22),
                  _buildSectionHeader(
                    title: 'Status Laporan Saya',
                    subtitle: 'Pantau perkembangan laporan Anda',
                    actionLabel: 'Lihat Semua',
                    onActionTap: goToAktivitas ?? () {},
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
                      height: 196,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: visibleMyReports.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return _ReportStatusCard(
                            report: visibleMyReports[index],
                            onTap: () => _openReportDetail(
                              context,
                              visibleMyReports[index],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    title: 'Pengumuman Terbaru',
                    subtitle: 'Informasi terbaru dari Ketua RT',
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
                      height: 226,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: announcements.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          return AnnouncementPreviewCard(
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
                      subtitle:
                          'Laporan yang telah ditindaklanjuti oleh Ketua RT',
                      height: 272,
                    )
                  else if (reportError != null && completedReports.isEmpty)
                    _buildErrorSection(
                      title: 'Bukti Selesai dari RT',
                      subtitle: reportError,
                      onRetry: () => state.refreshMyReports(),
                      height: 272,
                    )
                  else if (completedReports.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'Bukti Selesai dari RT',
                      subtitle:
                          'Laporan yang telah ditindaklanjuti oleh Ketua RT',
                      actionLabel: completedReports.length > 2
                          ? 'Lihat Semua'
                          : null,
                      onActionTap: completedReports.length > 2
                          ? () => _showCompletedReportsSheet(
                              context,
                              reports: completedReports,
                              rtRw: user?.rtRw,
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 272,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: visibleCompletedReports.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return _CompletionProofCard(
                            report: visibleCompletedReports[index],
                            rtRw: user?.rtRw,
                            onTap: () => _openReportDetail(
                              context,
                              visibleCompletedReports[index],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    title: 'Voting Lingkungan',
                    subtitle: 'Berikan suara untuk keputusan bersama warga',
                    actionLabel: 'Lihat Semua',
                    onActionTap: () => _showAllPollsSheet(
                      context,
                      polls: state.polls,
                      userId: userId,
                    ),
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
                  const SizedBox(height: 40),
                ],
              ),
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
        const NotificationBellButton(filled: true),
      ],
    );
  }

  Widget _buildGreetingCard(AppUser? user) {
    final rtRw = user?.rtRw;
    final greeting = _greetingFor(DateTime.now());
    final avatarUrl = user?.avatarUrl ?? '';

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
                Text(
                  greeting,
                  style: const TextStyle(
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
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.10),
            backgroundImage: avatarUrl.isNotEmpty
                ? CustomImageProvider.get(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryColor,
                    size: 38,
                  )
                : null,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.how_to_vote_rounded,
              color: AppTheme.primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voting aktif',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  poll.question,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                if (!hasVoted)
                  Row(
                    children: const [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Berakhir ...',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 114,
            height: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 4),
                  child: _PollStatusBadge(label: 'Aktif'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  child: SizedBox(
                    height: 32,
                    child: TextButton(
                      onPressed: onViewTap,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        hasVoted ? 'Lihat Hasil' : 'Berikan Suara',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
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

class _PollStatusBadge extends StatelessWidget {
  final String label;

  const _PollStatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isClosed = label.toLowerCase() == 'ditutup';
    final color = isClosed ? AppTheme.statusHigh : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompletionProofCard extends StatelessWidget {
  final Report report;
  final String? rtRw;
  final VoidCallback? onTap;
  final bool compact;

  const _CompletionProofCard({
    required this.report,
    required this.rtRw,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 248.0 : 270.0;
    final height = compact ? 256.0 : 274.0;
    final imageHeight = compact ? 150.0 : 158.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: width,
          height: height,
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
                  height: imageHeight,
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
                  padding: EdgeInsets.fromLTRB(
                    12,
                    compact ? 10 : 12,
                    12,
                    compact ? 8 : 10,
                  ),
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
                            _formatWibDate(
                              report.completedAt ?? report.createdAt,
                            ),
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
        ),
      ),
    );
  }
}

class _ReportStatusCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;

  const _ReportStatusCard({required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 324,
          height: 172,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _ReportLeading(report: report),
              ),
              const SizedBox(width: 16),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppTheme.outlineColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            report.locationLabel ?? 'Lokasi belum ditentukan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatWibDate(report.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.outlineColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PriorityBadge(priority: report.priority),
                            const SizedBox(width: 6),
                            _StatusBadge(status: report.status),
                          ],
                        ),
                      ),
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
        width: 114,
        height: 118,
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
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
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
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PollListCard extends StatelessWidget {
  final Poll poll;
  final bool hasVoted;
  final VoidCallback onTap;

  const _PollListCard({
    required this.poll,
    required this.hasVoted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = poll.isActive ? 'Aktif' : 'Ditutup';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        _PollStatusBadge(label: statusLabel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${poll.totalVotes} suara',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasVoted)
                          const _PollStatusBadge(label: 'Sudah Memilih'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.06,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
