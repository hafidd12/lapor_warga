import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/report_card.dart';

class DashboardWargaScreen extends StatelessWidget {
  const DashboardWargaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final user = state.currentUser;

    // Filter reports for "Laporan Saya" section (show max 2)
    final myReports = state.reports.take(2).toList();
    final latestCompletedReports = state.completedReportsWithPhotos
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const _DashboardHeaderTitle(),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user?.name ?? "Warga"}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 25,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Wilayah RT 05 / RW 02',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (latestCompletedReports.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bukti Selesai dari RT',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 18.5,
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const Icon(
                      Icons.verified_outlined,
                      color: AppTheme.statusLow,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 218,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: latestCompletedReports.length,
                    itemBuilder: (context, index) {
                      return _buildCompletionProofCard(
                        context,
                        latestCompletedReports[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Section 1: Pengumuman Terbaru
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengumuman Terbaru',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 18.5,
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Lihat Semua',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              state.announcements.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Belum ada pengumuman baru.'),
                      ),
                    )
                  : SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.announcements.length,
                        itemBuilder: (context, index) {
                          final ann = state.announcements[index];
                          // Match badge and styling from Stitch mockup
                          final isKegiatan = index == 0;
                          final badgeText = isKegiatan
                              ? 'KEGIATAN'
                              : 'INFORMASI';
                          final badgeBg = isKegiatan
                              ? AppTheme.primaryColor
                              : AppTheme.tertiaryContainerColor;
                          final badgeTextColor = isKegiatan
                              ? Colors.white
                              : AppTheme.onTertiaryContainerColor;

                          return Container(
                            width: MediaQuery.of(context).size.width * 0.78,
                            margin: const EdgeInsets.only(
                              right: 14,
                              bottom: 6,
                              top: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.outlineVariantColor.withOpacity(
                                  0.4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.03,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Announcement image or styled illustration container
                                Container(
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryContainerColor
                                        .withOpacity(0.4),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          isKegiatan
                                              ? Icons.campaign_outlined
                                              : Icons.info_outline,
                                          size: 48,
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: badgeTextColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ann.title,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimaryColor,
                                              height: 1.25,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ann.content,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 12,
                                              color:
                                                  AppTheme.textSecondaryColor,
                                              height: 1.35,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${ann.createdAt.day} ${_getMonthName(ann.createdAt.month)} ${ann.createdAt.year}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppTheme.textSecondaryColor,
                                              fontWeight: FontWeight.w600,
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
                        },
                      ),
                    ),

              const SizedBox(height: 28),

              // Section 2: Laporan Saya
              Text(
                'Laporan Saya',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 18.5,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
              myReports.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'Belum ada laporan aktif. Gunakan tombol + untuk membuat laporan.',
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: myReports.map((report) {
                        return ReportCard(report: report, onTap: () {});
                      }).toList(),
                    ),

              const SizedBox(height: 28),

              // Section 3: Voting Lingkungan (Asymmetric Bento Style)
              Text(
                'Voting Lingkungan',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 18.5,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
              state.polls.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text('Tidak ada voting aktif saat ini.'),
                        ),
                      ),
                    )
                  : _buildBentoVotingCard(
                      context,
                      state.polls.first,
                      user?.id,
                      state,
                    ),
              const SizedBox(height: 80), // extra padding for fab
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoVotingCard(
    BuildContext context,
    Poll poll,
    String? userId,
    AppState state,
  ) {
    final hasVoted = poll.userVotes.containsKey(userId);
    final selectedOption = poll.userVotes[userId];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside card
          Row(
            children: const [
              Icon(Icons.how_to_vote, color: AppTheme.tertiaryFixed, size: 20),
              SizedBox(width: 8),
              Text(
                'AKTIF SAMPAI 30 NOV',
                style: TextStyle(
                  color: AppTheme.tertiaryFixed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question title
          Text(
            poll.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Sub-description
          Text(
            'Program ini bertujuan untuk mendukung pengolahan kompos mandiri di tingkat RT.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Options layout
          if (!hasVoted) ...[
            Row(
              children: [
                // Highlight option (Ya, Setuju / Option 0)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tertiaryFixed,
                      foregroundColor: AppTheme.tertiaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (poll.options.isNotEmpty) {
                        state.voteInPoll(poll.id, poll.options.first);
                      }
                    },
                    child: Text(
                      poll.options.isNotEmpty
                          ? poll.options.first
                          : 'Ya, Setuju',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // Secondary Option (Tidak / Option 1)
                if (poll.options.length > 1) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        state.voteInPoll(poll.id, poll.options[1]);
                      },
                      child: Text(
                        poll.options[1],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Fallback for more options
            if (poll.options.length > 2) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: poll.options.skip(2).map((opt) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30, width: 1),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      state.voteInPoll(poll.id, opt);
                    },
                    child: Text(opt, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            // Voted state showing percentages
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terima kasih atas partisipasi Anda!',
                    style: TextStyle(
                      color: AppTheme.tertiaryFixed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...poll.options.map((opt) {
                    final votes = poll.votes[opt] ?? 0;
                    final total = poll.totalVotes == 0 ? 1 : poll.totalVotes;
                    final percent = (votes / total).toDouble();
                    final isSelected = selectedOption == opt;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(percent * 100).toStringAsFixed(0)}% ($votes)',
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.tertiaryFixed
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSelected
                                    ? AppTheme.tertiaryFixed
                                    : Colors.white30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionProofCard(BuildContext context, Report report) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.76,
      margin: const EdgeInsets.only(right: 14, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
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
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusLow,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'SELESAI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Dikirim oleh ${report.completedBy ?? 'RT'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
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
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

class _DashboardHeaderTitle extends StatelessWidget {
  const _DashboardHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_lapor_warga_icon.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.eco,
              size: 28,
              color: AppTheme.primaryColor,
            );
          },
        ),
        const SizedBox(width: 9),
        Text(
          'Lapor Warga',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
