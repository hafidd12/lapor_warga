import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';
import 'detail_laporan_admin.dart';
import 'buat_voting_admin.dart';
import 'buat_pengumuman_admin.dart';
import 'daftar_warga_admin.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({Key? key}) : super(key: key);

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  String _selectedStatusFilter = 'Semua Status';
  String _selectedCategoryFilter = 'Semua Kategori';

  final List<String> _statusOptions = [
    'Semua Status',
    'Baru',
    'Diproses',
    'Selesai',
  ];
  final List<String> _categoryOptions = [
    'Semua Kategori',
    'Infrastruktur',
    'Kebersihan',
    'Keamanan',
    'Penerangan Jalan',
    'Sosial & Tetangga',
    'Lainnya',
  ];

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Calculate Admin Stats
    final newCount = state.reports
        .where((r) => r.status == ReportStatus.submitted)
        .length;
    final processedCount = state.reports
        .where((r) => r.status == ReportStatus.processed)
        .length;
    final resolvedCount = state.reports
        .where((r) => r.status == ReportStatus.resolved)
        .length;
    final verifiedWargaCount = state.verifiedWarga.length;
    final pendingWargaCount = state.pendingWarga.length;

    // Filter reports
    final filteredReports = state.reports.where((report) {
      bool matchStatus = true;
      if (_selectedStatusFilter == 'Baru') {
        matchStatus = report.status == ReportStatus.submitted;
      } else if (_selectedStatusFilter == 'Diproses') {
        matchStatus = report.status == ReportStatus.processed;
      } else if (_selectedStatusFilter == 'Selesai') {
        matchStatus = report.status == ReportStatus.resolved;
      }

      bool matchCategory = true;
      if (_selectedCategoryFilter != 'Semua Kategori') {
        matchCategory =
            report.category.toLowerCase() ==
            _selectedCategoryFilter.toLowerCase();
      }

      return matchStatus && matchCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const _DashboardHeaderTitle(),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.primaryColor,
            ),
            onSelected: (value) {
              if (value == 'announcement') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BuatPengumumanAdminScreen(),
                  ),
                );
              } else if (value == 'poll') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BuatVotingAdminScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'announcement',
                child: Row(
                  children: [
                    Icon(
                      Icons.announcement,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Buat Pengumuman'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'poll',
                child: Row(
                  children: [
                    Icon(Icons.poll, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text('Buat Voting Komunitas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hallo, ${state.currentUser?.name ?? "Pak RT"}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 25,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau dan kelola laporan warga dengan efisien.',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Warga Stats Card
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DaftarWargaAdminScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryContainerColor,
                      AppTheme.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JUMLAH WARGA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppTheme.primaryFixedDim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                verifiedWargaCount.toString(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'terverifikasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryFixedDim,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (pendingWargaCount > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.statusMedium.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$pendingWargaCount menunggu verifikasi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.statusMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report Stats Row
            Row(
              children: [
                _buildStatCard(
                  label: 'Laporan Baru',
                  value: newCount.toString().padLeft(2, '0'),
                  subtext: 'Perlu ditangani',
                  indicatorColor: AppTheme.statusHigh,
                  icon: Icons.priority_high,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  label: 'Sedang Diproses',
                  value: processedCount.toString().padLeft(2, '0'),
                  subtext: 'Berjalan lancar',
                  indicatorColor: AppTheme.primaryColor,
                  icon: Icons.sync,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  label: 'Selesai',
                  value: resolvedCount.toString().padLeft(2, '0'),
                  subtext: 'Bulan ini',
                  indicatorColor: AppTheme.statusLow,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                Expanded(child: const SizedBox()),
              ],
            ),
            const SizedBox(height: 28),

            // Content Container with Filters & Report List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.outlineVariantColor.withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Laporan Masuk',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 16.5,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.outlineVariantColor
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedStatusFilter,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: AppTheme.secondaryColor,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: _statusOptions.map((String opt) {
                                      return DropdownMenuItem<String>(
                                        value: opt,
                                        child: Text(opt),
                                      );
                                    }).toList(),
                                    onChanged: (newVal) {
                                      if (newVal != null) {
                                        setState(() {
                                          _selectedStatusFilter = newVal;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.outlineVariantColor
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategoryFilter,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.filter_list,
                                      size: 18,
                                      color: AppTheme.secondaryColor,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: _categoryOptions.map((String opt) {
                                      return DropdownMenuItem<String>(
                                        value: opt,
                                        child: Text(
                                          opt,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newVal) {
                                      if (newVal != null) {
                                        setState(() {
                                          _selectedCategoryFilter = newVal;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppTheme.surfaceContainer),

                  // Report Items
                  filteredReports.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 40.0,
                              horizontal: 16,
                            ),
                            child: Text(
                              'Tidak ada laporan yang sesuai dengan filter.',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReports.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppTheme.surfaceContainerLow,
                          ),
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            final isHigh =
                                report.priority == ReportPriority.high;
                            final isResolved =
                                report.status == ReportStatus.resolved;

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            AppTheme.secondaryContainerColor,
                                        child: const Icon(
                                          Icons.person,
                                          color: AppTheme
                                              .onSecondaryContainerColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    report.citizenName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme
                                                          .textPrimaryColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isHigh
                                                        ? AppTheme
                                                              .statusHighContainer
                                                        : AppTheme
                                                              .secondaryContainerColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isHigh
                                                        ? 'HIGH PRIORITY'
                                                        : 'NORMAL',
                                                    style: TextStyle(
                                                      color: isHigh
                                                          ? AppTheme.statusHigh
                                                          : AppTheme
                                                                .secondaryColor,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              report.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              report.description,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.category_outlined,
                                                  size: 12,
                                                  color: AppTheme
                                                      .textSecondaryColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  report.category,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme
                                                        .textSecondaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Icon(
                                                  Icons.schedule,
                                                  size: 12,
                                                  color: AppTheme
                                                      .textSecondaryColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatTimeAgo(
                                                    report.createdAt,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme
                                                        .textSecondaryColor,
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
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.textPrimaryColor,
                                            side: const BorderSide(
                                              color: AppTheme.outlineColor,
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailLaporanAdminScreen(
                                                      reportId: report.id,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Detail',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!isResolved) ...[
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DetailLaporanAdminScreen(
                                                        reportId: report.id,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Tindak Lanjut',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtext,
    required Color indicatorColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: indicatorColor, width: 4),
            top: const BorderSide(color: AppTheme.surfaceContainer),
            right: const BorderSide(color: AppTheme.surfaceContainer),
            bottom: const BorderSide(color: AppTheme.surfaceContainer),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Icon(icon, size: 14, color: indicatorColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: indicatorColor.withOpacity(0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
