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

  String? _selectedCategory;
  final List<String> _categories = const [
    'Infrastruktur',
    'Kebersihan',
    'Keamanan',
    'Penerangan Jalan',
    'Sosial & Tetangga',
    'Lainnya',
  ];

  ReportPriority? _selectedPriority;
  bool _hasMockImage = false;
  bool _hasSelectedLocation = false;
  bool _showValidationErrors = false;

  static const String _mockReportPhotoUrl = 'mock://laporan/foto-kejadian.jpg';
  static const String _mockLocationLabel =
      'Titik laporan dipilih - RT 05 / RW 02';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _showValidationErrors = true);

    final isFormValid = _formKey.currentState!.validate();
    final isAttachmentValid =
        _selectedPriority != null && _hasMockImage && _hasSelectedLocation;

    if (!isFormValid || !isAttachmentValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data laporan terlebih dahulu.'),
          backgroundColor: AppTheme.statusHigh,
        ),
      );
      return;
    }

    final state = Provider.of<AppState>(context, listen: false);
    state.addReport(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedCategory!,
      _selectedPriority!,
      reportPhotoUrl: _mockReportPhotoUrl,
      locationLabel: _mockLocationLabel,
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
      _selectedCategory = null;
      _selectedPriority = null;
      _hasMockImage = false;
      _hasSelectedLocation = false;
      _showValidationErrors = false;
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
        centerTitle: false,
        titleSpacing: 0,
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidationErrors
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
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
                    if (value.trim().length < 5) {
                      return 'Judul laporan minimal 5 karakter';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _formSection(
                label: 'Kategori',
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Pilih kategori laporan'),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                  ),
                  decoration: _inputDecoration('Pilih kategori laporan'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kategori laporan wajib dipilih';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _formSection(
                label: 'Detail Laporan',
                child: TextFormField(
                  controller: _descriptionController,
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
              const SizedBox(height: 16),
              _formSection(
                label: 'Prioritas',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
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
                    _validationMessage(
                      _showValidationErrors && _selectedPriority == null
                          ? 'Prioritas laporan wajib dipilih'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _formSection(
                label: 'Unggah Foto',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _hasMockImage = true),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow.withOpacity(
                              0.35,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _hasMockImage
                                  ? AppTheme.primaryColor
                                  : AppTheme.outlineVariantColor,
                              width: _hasMockImage ? 2 : 1.5,
                            ),
                          ),
                          child: _hasMockImage
                              ? Stack(
                                  children: [
                                    const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: AppTheme.statusLow,
                                            size: 42,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Foto kejadian sudah dipilih',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'foto-kejadian.jpg',
                                            style: TextStyle(
                                              color:
                                                  AppTheme.textSecondaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _hasMockImage = false,
                                        ),
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
                                    SizedBox(height: 8),
                                    Text(
                                      'Pilih Foto Kejadian',
                                      style: TextStyle(
                                        color: AppTheme.outlineColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    _validationMessage(
                      _showValidationErrors && !_hasMockImage
                          ? 'Foto kejadian wajib dipilih'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _formSection(
                label: 'Pilih Lokasi',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _hasSelectedLocation = true),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainerColor.withOpacity(
                              0.55,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _hasSelectedLocation
                                  ? AppTheme.primaryColor
                                  : AppTheme.outlineVariantColor,
                              width: _hasSelectedLocation ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: _MapGridPainter()),
                              ),
                              if (_hasSelectedLocation)
                                const Positioned(
                                  right: 12,
                                  top: 12,
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: AppTheme.statusLow,
                                    child: Icon(
                                      Icons.check,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: _hasSelectedLocation
                                          ? AppTheme.primaryColor
                                          : AppTheme.outlineVariantColor,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.08),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _hasSelectedLocation
                                            ? 'Lokasi Dipilih'
                                            : 'Tentukan Titik Lokasi',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
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
                    if (_hasSelectedLocation)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _mockLocationLabel,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _validationMessage(
                      _showValidationErrors && !_hasSelectedLocation
                          ? 'Lokasi laporan wajib ditentukan'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text(
                    'Kirim Laporan',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _validationMessage(String? message) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.statusHigh,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = AppTheme.outlineVariantColor.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), minorPaint);
    }
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), minorPaint);
    }

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.72),
      Offset(size.width * 0.9, size.height * 0.28),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.1),
      Offset(size.width * 0.74, size.height * 0.9),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
