import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class HalamanReportScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const HalamanReportScreen({
    Key? key,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  State<HalamanReportScreen> createState() => _HalamanReportScreenState();
}

class _HalamanReportScreenState extends State<HalamanReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Infrastruktur';
  ReportPriority _selectedPriority = ReportPriority.low;
  bool _hasMockImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppState>(context, listen: false);
    state.addReport(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedCategory,
      _selectedPriority,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan Anda berhasil dikirim!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = 'Infrastruktur';
      _selectedPriority = ReportPriority.low;
      _hasMockImage = false;
    });

    if (widget.showBackButton && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    widget.onBackPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80,
        leadingWidth: 64,
        title: const Text(
          'Report',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formSection(
                label: 'Judul Laporan',
                child: TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    'Tuliskan judul laporan singkat atau subjek laporan...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul laporan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),
              _formSection(
                label: 'Detail Laporan',
                child: TextFormField(
                  controller: _descriptionController,
                  minLines: 5,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    'Ceritakan detail kejadian atau masalah yang Anda temukan...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Detail laporan tidak boleh kosong';
                    }
                    if (value.trim().length < 10) {
                      return 'Berikan detail minimal 10 karakter';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),
              _formSection(
                label: 'Prioritas',
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _prioritySegment(ReportPriority.low, 'Rendah'),
                      _prioritySegment(ReportPriority.medium, 'Sedang'),
                      _prioritySegment(ReportPriority.high, 'Tinggi'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _formSection(
                label: 'Unggah Foto',
                child: GestureDetector(
                  onTap: () => setState(() => _hasMockImage = !_hasMockImage),
                  child: AspectRatio(
                    aspectRatio: 1.98,
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: _hasMockImage
                            ? AppTheme.primaryColor
                            : AppTheme.outlineVariantColor,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _hasMockImage
                            ? Stack(
                                children: [
                                  const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: AppTheme.primaryColor,
                                          size: 42,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Foto kejadian sudah dipilih',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.statusHigh
                                          .withOpacity(0.9),
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppTheme.outlineColor,
                                    size: 44,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Pilih Foto Kejadian',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _formSection(
                label: 'Pilih Lokasi',
                child: AspectRatio(
                  aspectRatio: 1.78,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.outlineVariantColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LocationPreviewPainter(),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppTheme.outlineColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.16),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Tentukan Titik Lokasi',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.24),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.send_outlined, size: 24),
                  label: const Text(
                    'Kirim Laporan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      fillColor: Colors.white,
      filled: true,
      hintStyle: const TextStyle(
        color: Color(0xFFB7BFB9),
        fontSize: 16,
        height: 1.45,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.outlineVariantColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.outlineVariantColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _formSection({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _prioritySegment(ReportPriority priority, String label) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(14);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(1), radius);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 7.0;
      const gap = 6.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LocationPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sidePaint = Paint()..color = const Color(0xFF0B3D31);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.28, size.height),
      sidePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.72, 0, size.width * 0.28, size.height),
      sidePaint,
    );

    final mapRect = Rect.fromLTWH(
      size.width * 0.30,
      -size.height * 0.08,
      size.width * 0.40,
      size.height * 1.18,
    );
    final mapPaint = Paint()..color = const Color(0xFFD8DDD8);
    canvas.drawRect(mapRect, mapPaint);

    final waterPaint = Paint()..color = const Color(0xFF438A85);
    canvas.drawPath(
      Path()
        ..moveTo(mapRect.left, size.height * 0.82)
        ..cubicTo(
          mapRect.left + 26,
          size.height * 0.68,
          mapRect.left + 64,
          size.height * 0.82,
          mapRect.right,
          size.height * 0.70,
        )
        ..lineTo(mapRect.right, size.height)
        ..lineTo(mapRect.left, size.height)
        ..close(),
      waterPaint,
    );

    final parkPaint = Paint()..color = const Color(0xFF8EC39B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mapRect.left + 12, size.height * 0.58, 42, 34),
        const Radius.circular(6),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mapRect.right - 48, size.height * 0.10, 44, 40),
        const Radius.circular(6),
      ),
      parkPaint,
    );

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.78)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = const Color(0xFFAEB7B0)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final y = size.height * (i + 1) / 9;
      canvas.drawLine(
        Offset(mapRect.left, y),
        Offset(mapRect.right, y + 10),
        minorPaint,
      );
    }
    for (var i = 0; i < 6; i++) {
      final x = mapRect.left + mapRect.width * (i + 1) / 7;
      canvas.drawLine(Offset(x, 0), Offset(x - 8, size.height), minorPaint);
    }

    canvas.drawLine(
      Offset(mapRect.left + 4, size.height * 0.28),
      Offset(mapRect.right - 4, size.height * 0.50),
      roadPaint,
    );
    canvas.drawLine(
      Offset(mapRect.left + mapRect.width * 0.72, 0),
      Offset(mapRect.left + mapRect.width * 0.36, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(mapRect.left + 10, size.height * 0.72),
      Offset(mapRect.right - 6, size.height * 0.36),
      roadPaint,
    );

    final pinOffset = Offset(size.width * 0.545, size.height * 0.34);
    final pinPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(pinOffset, 7, pinPaint);
    canvas.drawCircle(pinOffset, 3, Paint()..color = Colors.white);
    canvas.drawPath(
      Path()
        ..moveTo(pinOffset.dx - 5, pinOffset.dy + 5)
        ..lineTo(pinOffset.dx + 5, pinOffset.dy + 5)
        ..lineTo(pinOffset.dx, pinOffset.dy + 17)
        ..close(),
      pinPaint,
    );

    final phonePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(mapRect.inflate(7), const Radius.circular(16)),
      phonePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
