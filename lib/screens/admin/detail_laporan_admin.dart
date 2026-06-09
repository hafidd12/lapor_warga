import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../widgets/status_badge.dart';

class DetailLaporanAdminScreen extends StatefulWidget {
  final String reportId;

  const DetailLaporanAdminScreen({Key? key, required this.reportId})
      : super(key: key);

  @override
  State<DetailLaporanAdminScreen> createState() =>
      _DetailLaporanAdminScreenState();
}

class _DetailLaporanAdminScreenState extends State<DetailLaporanAdminScreen> {
  bool _showPhotoInput = false;
  final _photoUrlController = TextEditingController(
      text: 'https://picsum.photos/seed/bukti/400/300');

  @override
  void dispose() {
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    final reportIndex =
        state.reports.indexWhere((r) => r.id == widget.reportId);
    if (reportIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(child: Text('Laporan tidak ditemukan.')),
      );
    }
    final report = state.reports[reportIndex];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tindak Lanjut Laporan'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PriorityBadge(priority: report.priority),
                    const SizedBox(width: 8),
                    Text(
                      report.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 20),

            // Card details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 18,
                          color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Pelapor: ${report.citizenName}',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 18,
                          color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Diajukan: ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year} - ${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Detail Kejadian / Masalah:',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Completion photo (if resolved with photo)
            if (report.status == ReportStatus.resolved &&
                report.completionPhotoUrl != null) ...[
              Text(
                'Bukti Penyelesaian',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: AppTheme.surfaceContainerHigh,
                        child: Image.network(
                          report.completionPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.photo,
                                      size: 40,
                                      color: AppTheme.outlineColor),
                                  SizedBox(height: 4),
                                  Text('Bukti Foto Penyelesaian',
                                      style: TextStyle(
                                          color: AppTheme
                                              .textSecondaryColor)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16,
                                  color: AppTheme.statusLow),
                              const SizedBox(width: 6),
                              const Text(
                                'Tugas telah diselesaikan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.statusLow,
                                ),
                              ),
                            ],
                          ),
                          if (report.completedBy != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Diselesaikan oleh: ${report.completedBy}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                          if (report.completedAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Pada: ${report.completedAt!.day}/${report.completedAt!.month}/${report.completedAt!.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Actions panel
            Text(
              'Aksi Pengurus / Admin',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Action 1: Mark as Processed
                  if (report.status == ReportStatus.submitted)
                    _actionButton(
                      context,
                      'Mulai Proses Penanganan',
                      Icons.play_arrow_outlined,
                      Colors.indigo,
                      () {
                        state.updateReportStatus(
                            report.id, ReportStatus.processed);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Status laporan: Diproses')),
                        );
                      },
                    ),

                  // Action 2: Complete with photo
                  if (report.status != ReportStatus.resolved) ...[
                    if (report.status == ReportStatus.submitted)
                      const SizedBox(height: 12),

                    if (!_showPhotoInput)
                      _actionButton(
                        context,
                        'Selesaikan dengan Bukti Foto',
                        Icons.camera_alt_outlined,
                        AppTheme.tertiaryContainerColor,
                        () {
                          setState(() => _showPhotoInput = true);
                        },
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.tertiaryContainerColor
                                  .withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LAMPIRKAN BUKTI FOTO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _photoUrlController,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor),
                              decoration: InputDecoration(
                                hintText: 'URL foto bukti...',
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.link,
                                    size: 18,
                                    color: AppTheme.outlineColor),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppTheme
                                          .outlineVariantColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppTheme
                                          .tertiaryContainerColor,
                                      width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Masukkan URL foto sebagai bukti penyelesaian tugas.',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          AppTheme.secondaryColor,
                                      side: const BorderSide(
                                          color:
                                              AppTheme.outlineColor),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8)),
                                    ),
                                    onPressed: () => setState(
                                        () => _showPhotoInput = false),
                                    child: const Text('Batal',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme
                                          .tertiaryContainerColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8)),
                                    ),
                                    onPressed: () {
                                      final url =
                                          _photoUrlController.text
                                              .trim();
                                      if (url.isNotEmpty) {
                                        state.completeReport(
                                            report.id, url);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Laporan selesai dengan bukti foto!'),
                                            backgroundColor:
                                                AppTheme.statusLow,
                                          ),
                                        );
                                        setState(() =>
                                            _showPhotoInput = false);
                                      }
                                    },
                                    icon: const Icon(
                                        Icons.check_circle,
                                        size: 16),
                                    label: const Text('Selesaikan',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // If resolved
                  if (report.status == ReportStatus.resolved)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle,
                            color: AppTheme.statusLow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Laporan ini telah selesai ditangani.',
                          style: TextStyle(
                            color: AppTheme.statusLow,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
