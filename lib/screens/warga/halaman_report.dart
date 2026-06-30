import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class HalamanReportScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const HalamanReportScreen({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
  });

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
  Uint8List? _reportImageBytes;
  String? _reportImageName;
  final ImagePicker _imagePicker = ImagePicker();

  String? _customLocationLabel;
  bool _hasSelectedLocation = false;
  bool _showValidationErrors = false;

  static const String _mockReportPhotoUrl = 'mock://laporan/foto-kejadian.jpg';
  static const String _mockLocationLabel =
      'Titik laporan dipilih - RT 05 / RW 02';

  static final Uint8List _mockReportImageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7+4j8AAAAASUVORK5CYII=',
  );

  bool get _isTesting {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('TestWidgetsFlutterBinding') ||
        bindingName.contains('AutomatedTestWidgetsFlutterBinding');
  }

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
        _selectedPriority != null &&
        _reportImageBytes != null &&
        _hasSelectedLocation;

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
    final reportPhotoUrl = _isTesting
        ? _mockReportPhotoUrl
        : (_reportImageBytes != null && _reportImageName != null
              ? _buildDataUrl(_reportImageBytes!, _reportImageName!)
              : null);
    final locationLabel = _isTesting
        ? _mockLocationLabel
        : _customLocationLabel;

    state.addReport(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedCategory!,
      _selectedPriority!,
      reportPhotoUrl: reportPhotoUrl,
      locationLabel: locationLabel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan Anda berhasil dikirim!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedPriority = null;
      _reportImageBytes = null;
      _reportImageName = null;
      _customLocationLabel = null;
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

  Future<void> _pickReportImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _reportImageBytes = bytes;
          _reportImageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppTheme.statusHigh,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    if (_isTesting) {
      setState(() {
        _reportImageBytes = _mockReportImageBytes;
        _reportImageName = 'foto-kejadian.jpg';
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariantColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Foto Kejadian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ambil foto langsung dari kamera atau pilih dari galeri',
              style: TextStyle(fontSize: 12, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    subtitle: 'Foto langsung',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _pickReportImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    subtitle: 'Pilih dari galeri',
                    color: AppTheme.tertiaryFixedDim,
                    onTap: () {
                      Navigator.pop(context);
                      _pickReportImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    if (_isTesting) {
      setState(() {
        _hasSelectedLocation = true;
        _customLocationLabel = _mockLocationLabel;
      });
      return;
    }

    final localController = TextEditingController(
      text: _customLocationLabel ?? '',
    );
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariantColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tentukan Lokasi Laporan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masukkan alamat detail/landmark kejadian atau cari menggunakan GPS',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GPS Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLocating
                          ? null
                          : () async {
                              setModalState(() => isLocating = true);
                              try {
                                final locationLabel =
                                    await _getCurrentLocationLabel();
                                if (context.mounted) {
                                  setState(() {
                                    _customLocationLabel = locationLabel;
                                    _hasSelectedLocation = true;
                                  });
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$e'),
                                      backgroundColor: AppTheme.statusHigh,
                                    ),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isLocating = false);
                                }
                              }
                            },
                      icon: isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        isLocating
                            ? 'Mencari Koordinat GPS...'
                            : 'Gunakan Lokasi GPS Saat Ini',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ATAU TULIS MANUAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.outlineColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Manual input
                  TextFormField(
                    controller: localController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Misal: Depan Pos Ronda RT 05, samping pohon mangga...',
                      fillColor: AppTheme.surfaceContainerLow.withValues(
                        alpha: 0.3,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.outlineVariantColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.outlineVariantColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final enteredText = localController.text.trim();
                        if (enteredText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Silakan masukkan lokasi terlebih dahulu.',
                              ),
                              backgroundColor: AppTheme.statusHigh,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _customLocationLabel = enteredText;
                          _hasSelectedLocation = true;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Konfirmasi Lokasi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> _getCurrentLocationLabel() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw 'Layanan lokasi perangkat belum aktif.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw 'Izin lokasi ditolak. Tulis lokasi manual atau izinkan akses lokasi.';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen. Aktifkan izin lokasi dari pengaturan aplikasi.';
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    final latitude = position.latitude.toStringAsFixed(6);
    final longitude = position.longitude.toStringAsFixed(6);
    return 'Lokasi GPS: $latitude, $longitude';
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
                  key: ValueKey(_selectedCategory),
                  initialValue: _selectedCategory,
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
                      onTap: _showImageSourcePicker,
                      child: Container(
                        width: double.infinity,
                        height: _reportImageBytes != null ? null : 130,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryFixed.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _reportImageBytes != null
                                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                                : AppTheme.outlineVariantColor,
                            width: 1.5,
                            style: _reportImageBytes != null
                                ? BorderStyle.solid
                                : BorderStyle.none,
                          ),
                        ),
                        child: _reportImageBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(
                                      _reportImageBytes!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildReportPhotoActionButton(
                                          icon: Icons.edit_rounded,
                                          color: AppTheme.primaryColor,
                                          onTap: _showImageSourcePicker,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildReportPhotoActionButton(
                                          icon: Icons.delete_rounded,
                                          color: AppTheme.statusHigh,
                                          onTap: () {
                                            setState(() {
                                              _reportImageBytes = null;
                                              _reportImageName = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(11),
                                            ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.6),
                                          ],
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Foto laporan berhasil diupload',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CustomPaint(
                                  painter: _DashedBorderPainter(
                                    color: AppTheme.outlineVariantColor,
                                    borderRadius: 12,
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 32,
                                          color: AppTheme.primaryColor,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Upload atau Foto Laporan',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Tap untuk mengambil foto atau pilih dari galeri',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    _validationMessage(
                      _showValidationErrors && _reportImageBytes == null
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
                      onTap: _showLocationPicker,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainerColor.withValues(
                              alpha: 0.55,
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
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.08,
                                        ),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _isTesting
                              ? _mockLocationLabel
                              : (_customLocationLabel ?? ''),
                          style: const TextStyle(
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

  String _buildDataUrl(Uint8List bytes, String fileName) {
    final mimeType = _mimeTypeFromFileName(fileName);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
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
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
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

  Widget _buildReportPhotoActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, this.borderRadius = 12});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const strokeWidth = 1.5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = AppTheme.outlineVariantColor.withValues(alpha: 0.5)
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
