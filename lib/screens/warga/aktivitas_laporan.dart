import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/report_card.dart';
import '../../widgets/status_badge.dart';

class AktivitasLaporanScreen extends StatefulWidget {
  const AktivitasLaporanScreen({Key? key}) : super(key: key);

  @override
  State<AktivitasLaporanScreen> createState() => _AktivitasLaporanScreenState();
}

class _AktivitasLaporanScreenState extends State<AktivitasLaporanScreen> {
  String _selectedFilter = 'Semua';
  String _query = '';

  final List<String> _filters = const [
    'Semua',
    'Diajukan',
    'Diproses',
    'Selesai',
  ];

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final hasCompletionPhoto =
            report.status == ReportStatus.resolved &&
            report.completionPhotoUrl != null &&
            report.completionPhotoUrl!.trim().isNotEmpty;

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.52,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.outlineVariantColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PriorityBadge(priority: report.priority),
                        StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      report.title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 24,
                        letterSpacing: 0,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _metadataRow(
                      Icons.person_outline,
                      'Pelapor: ${report.citizenName}',
                    ),
                    const SizedBox(height: 8),
                    _metadataRow(
                      Icons.schedule_outlined,
                      'Dilaporkan pada: ${_formatDateTime(report.createdAt)}',
                    ),
                    const SizedBox(height: 8),
                    _metadataRow(Icons.category_outlined, report.category),
                    if (report.locationLabel != null) ...[
                      const SizedBox(height: 8),
                      _metadataRow(
                        Icons.location_on_outlined,
                        report.locationLabel!,
                      ),
                    ],
                    if (report.reportPhotoUrl != null) ...[
                      const SizedBox(height: 8),
                      _metadataRow(
                        Icons.photo_camera_outlined,
                        'Foto kejadian terlampir',
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Deskripsi Laporan',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (hasCompletionPhoto) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 20,
                            color: AppTheme.statusLow,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bukti Penyelesaian RT',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showPhotoPreview(
                          context,
                          report.completionPhotoUrl!,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 240,
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
                                        child: Text(
                                          'Foto bukti tidak dapat dimuat',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 16,
                                        ),
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
                      const SizedBox(height: 10),
                      Text(
                        'Diselesaikan oleh ${report.completedBy ?? 'RT'}'
                        '${report.completedAt == null ? '' : ' pada ${_formatDate(report.completedAt!)}'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Status Pengerjaan',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressTracker(report.status),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(
                            color: AppTheme.outlineVariantColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Tutup Detail',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                  child: Image.network(photoUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.6),
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
    final reports = _filteredReports(state.reports);
    final completedWithPhoto = state.completedReportsWithPhotos.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lapor Warga',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text(
            'History Laporan',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 24,
              letterSpacing: 0,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Cari laporan...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.outlineColor,
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.outlineVariantColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                    onSelected: (_) => setState(() => _selectedFilter = filter),
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
          const SizedBox(height: 18),
          _buildStatsCard(state.reports.length, completedWithPhoto),
          const SizedBox(height: 18),
          if (reports.isEmpty)
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
    );
  }

  Widget _buildStatsCard(int totalReports, int completedWithPhoto) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppTheme.onPrimaryContainerColor,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalReports laporan tercatat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$completedWithPhoto laporan selesai punya bukti foto RT',
                  style: const TextStyle(
                    color: AppTheme.onPrimaryContainerColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: const [
          Icon(Icons.history_outlined, size: 44, color: AppTheme.outlineColor),
          SizedBox(height: 12),
          Text(
            'Tidak ada laporan yang cocok',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
