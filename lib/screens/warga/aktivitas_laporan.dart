import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/report_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/notification_bell_button.dart';

class AktivitasLaporanScreen extends StatefulWidget {
  const AktivitasLaporanScreen({super.key});

  @override
  State<AktivitasLaporanScreen> createState() => _AktivitasLaporanScreenState();
}

class _AktivitasLaporanScreenState extends State<AktivitasLaporanScreen> {
  String _selectedFilter = 'Semua';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = const [
    'Semua',
    'Diajukan',
    'Diproses',
    'Selesai',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshReports() async {
    final state = context.read<AppState>();
    await state.refreshMyReports().catchError((_) {});
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
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${_formatDate(dateTime)}, $hour:$minute WIB';
  }

  bool _matchesFilter(Report report) {
    switch (_selectedFilter) {
      case 'Diajukan':
        return report.status == ReportStatus.submitted;
      case 'Diproses':
        return report.status == ReportStatus.processed;
      case 'Selesai':
        return report.status == ReportStatus.resolved;
      default:
        return true;
    }
  }

  List<Report> _filteredReports(List<Report> reports) {
    final search = _query.trim().toLowerCase();
    return reports.where((report) {
      final matchesText =
          search.isEmpty ||
          report.title.toLowerCase().contains(search) ||
          report.description.toLowerCase().contains(search) ||
          report.category.toLowerCase().contains(search);
      return _matchesFilter(report) && matchesText;
    }).toList();
  }

  void _showReportDetail(BuildContext context, Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailLaporanScreen(report: report),
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _buildReportImageWidget(photoUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metadataRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker(ReportStatus status) {
    final stepProcessed =
        status == ReportStatus.processed || status == ReportStatus.resolved;
    final stepResolved = status == ReportStatus.resolved;

    return Row(
      children: [
        _trackerNode('Diajukan', true),
        _trackerConnector(stepProcessed),
        _trackerNode('Diproses', stepProcessed),
        _trackerConnector(stepResolved),
        _trackerNode('Selesai', stepResolved),
      ],
    );
  }

  Widget _trackerNode(String label, bool isReached) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isReached
              ? AppTheme.primaryColor
              : AppTheme.surfaceContainerHighest,
          child: Icon(
            isReached ? Icons.check : Icons.radio_button_unchecked,
            size: 14,
            color: isReached ? Colors.white : AppTheme.outlineColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
            color: isReached
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _trackerConnector(bool isFilled) {
    return Expanded(
      child: Container(
        height: 3,
        color: isFilled
            ? AppTheme.primaryColor
            : AppTheme.surfaceContainerHighest,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isLoading = state.reportsLoading;
    final error = state.reportsError;
    final reports = _filteredReports(state.myReports);
    final totalReports = state.myReports.length;
    final completedWithPhoto = state.completedReportsWithPhotos.length;
    final processedReports = state.myReports
        .where((report) => report.status == ReportStatus.processed)
        .length;
    final resolvedReports = state.myReports
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 86,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Riwayat Laporan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pantau status laporan Anda.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: const [NotificationBellButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari judul atau lokasi laporan...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppTheme.outlineColor,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Bersihkan pencarian',
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _searchController.clear();
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.outlineColor,
                        ),
                      ),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.outlineVariantColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.outlineVariantColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildStatsCard(
              totalReports,
              processedReports,
              resolvedReports,
              completedWithPhoto,
            ),
            const SizedBox(height: 14),
            if (isLoading && reports.isEmpty)
              _buildLoadingState()
            else if (error != null && reports.isEmpty)
              _buildErrorState(error, () => state.refreshMyReports())
            else if (reports.isEmpty)
              _buildEmptyState()
            else
              ...reports.map(
                (report) => ReportCard(
                  report: report,
                  onTap: () => _showReportDetail(context, report),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    int totalReports,
    int processedReports,
    int resolvedReports,
    int completedWithPhoto,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainerColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalReports Laporan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$processedReports Diproses • $resolvedReports Selesai',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bukti foto RT: $completedWithPhoto',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.secondaryColor,
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

  Widget _buildStatusBadge(ReportStatus status) {
    Color baseColor;
    String text;

    switch (status) {
      case ReportStatus.submitted:
        baseColor = AppTheme.statusMedium;
        text = 'Diajukan';
        break;
      case ReportStatus.processed:
        baseColor = const Color(0xFF005BC1);
        text = 'Diproses';
        break;
      case ReportStatus.resolved:
        baseColor = AppTheme.statusLow;
        text = 'Selesai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: baseColor.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: baseColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoFrame({
    required String photoUrl,
    required String emptyLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildReportImageWidget(photoUrl),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Perbesar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorImagePlaceholder(),
      );
    } else if (path.startsWith('data:image/')) {
      final commaIndex = path.indexOf(',');
      if (commaIndex == -1) {
        return _buildErrorImagePlaceholder();
      }

      final base64Part = path.substring(commaIndex + 1);
      try {
        return Image.memory(
          base64Decode(base64Part),
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorImagePlaceholder(),
        );
      } catch (_) {
        return _buildErrorImagePlaceholder();
      }
    } else {
      return _buildErrorImagePlaceholder();
    }
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.35),
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            'Memuat laporan dari Supabase...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: AppTheme.statusHigh,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildErrorImagePlaceholder() {
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
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainerColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 38,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada laporan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Laporan yang Anda kirim akan muncul di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailLaporanScreen extends StatelessWidget {
  final Report report;

  const DetailLaporanScreen({super.key, required this.report});

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
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${_formatDate(dateTime)}, $hour:$minute WIB';
  }

  bool get _hasCompletionPhoto =>
      report.status == ReportStatus.resolved &&
      report.completionPhotoUrl != null &&
      report.completionPhotoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Detail Laporan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        actions: const [NotificationBellButton()],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildDescriptionCard(context),
            if (report.reportPhotoUrl != null &&
                report.reportPhotoUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPhotoSection(
                context,
                title: 'Foto Laporan',
                icon: Icons.photo_camera_outlined,
                imageUrl: report.reportPhotoUrl!,
                height: 220,
                previewUrl: report.reportPhotoUrl!,
              ),
            ],
            if (_hasCompletionPhoto) ...[
              const SizedBox(height: 16),
              _buildPhotoSection(
                context,
                title: 'Bukti Penyelesaian RT',
                icon: Icons.verified_outlined,
                imageUrl: report.completionPhotoUrl!,
                height: 250,
                previewUrl: report.completionPhotoUrl!,
                footer:
                    'Diselesaikan oleh ${report.completedBy ?? 'RT'}'
                    '${report.completedAt == null ? '' : ' pada ${_formatDate(report.completedAt!)}'}',
              ),
            ],
            const SizedBox(height: 16),
            _buildTimelineCard(context),
            const SizedBox(height: 16),
            _buildCurrentStatusCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            PriorityBadge(priority: report.priority),
            StatusBadge(status: report.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          report.title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildCategoryChip(context),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 13,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            report.category,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return _detailCard(
      context,
      child: Column(
        children: [
          _detailRow(
            context,
            Icons.person_outline,
            'Pelapor',
            report.citizenName,
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.schedule_outlined,
            'Tanggal',
            _formatDateTime(report.createdAt),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.location_on_outlined,
            'Lokasi',
            report.locationLabel ?? 'Lokasi belum ditentukan',
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.category_outlined,
            'Kategori',
            report.category,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return _detailCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deskripsi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String imageUrl,
    required double height,
    required String previewUrl,
    String? footer,
  }) {
    return _detailCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showPhotoPreview(context, previewUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildReportImageWidget(imageUrl),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Perbesar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
          ),
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(
              footer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return _detailCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Pengerjaan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildProgressTracker(context, report.status),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Status Saat Ini',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Laporan telah selesai ditangani oleh Ketua RT. Terima kasih atas partisipasi Anda dalam menjaga lingkungan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker(BuildContext context, ReportStatus status) {
    final stepProcessed =
        status == ReportStatus.processed || status == ReportStatus.resolved;
    final stepResolved = status == ReportStatus.resolved;

    return Row(
      children: [
        _trackerNode(context, 'Diajukan', true),
        _trackerConnector(stepProcessed),
        _trackerNode(context, 'Diproses', stepProcessed),
        _trackerConnector(stepResolved),
        _trackerNode(context, 'Selesai', stepResolved),
      ],
    );
  }

  Widget _trackerNode(BuildContext context, String label, bool isReached) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isReached
              ? AppTheme.primaryColor
              : AppTheme.surfaceContainerHighest,
          child: Icon(
            isReached ? Icons.check : Icons.radio_button_unchecked,
            size: 14,
            color: isReached ? Colors.white : AppTheme.outlineColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isReached ? FontWeight.bold : FontWeight.w500,
            color: isReached
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _trackerConnector(bool isFilled) {
    return Expanded(
      child: Container(
        height: 3,
        color: isFilled
            ? AppTheme.primaryColor
            : AppTheme.surfaceContainerHighest,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _buildReportImageWidget(photoUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorImagePlaceholder(),
      );
    } else if (path.startsWith('data:image/')) {
      final commaIndex = path.indexOf(',');
      if (commaIndex == -1) {
        return _buildErrorImagePlaceholder();
      }

      final base64Part = path.substring(commaIndex + 1);
      try {
        return Image.memory(
          base64Decode(base64Part),
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorImagePlaceholder(),
        );
      } catch (_) {
        return _buildErrorImagePlaceholder();
      }
    } else {
      return _buildErrorImagePlaceholder();
    }
  }

  Widget _buildErrorImagePlaceholder() {
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
  }
}
