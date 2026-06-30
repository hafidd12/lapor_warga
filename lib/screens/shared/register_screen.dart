import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class RegisterScreen extends StatefulWidget {
  final bool isWarga;
  const RegisterScreen({super.key, required this.isWarga});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Warga-specific
  final _registrationCodeController = TextEditingController();
  final _rtRwController = TextEditingController();
  final _addressController = TextEditingController();

  // KTP Image
  File? _ktpImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  // RT-specific
  final _jabatanController = TextEditingController();
  final _wilayahController = TextEditingController();
  final _rtRegistrationCodeController = TextEditingController();

  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  // Warga: code lookup status
  bool _codeFound = false;
  bool _codeLookupAttempted = false;
  String? _foundRtRw;

  Future<void> _pickKtpImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _ktpImageFile = File(pickedFile.path);
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

  void _showKtpImageSourcePicker() {
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
              'Upload Foto KTP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih sumber foto KTP Anda',
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
                      _pickKtpImage(ImageSource.camera);
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
                      _pickKtpImage(ImageSource.gallery);
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

  @override
  void initState() {
    super.initState();
    // For warga: listen to registration code changes and auto-fill RT/RW
    if (widget.isWarga) {
      _registrationCodeController.addListener(_onRegistrationCodeChanged);
    }
  }

  void _onRegistrationCodeChanged() {
    final code = _registrationCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _codeFound = false;
        _codeLookupAttempted = false;
        _foundRtRw = null;
        _rtRwController.text = '';
      });
      return;
    }

    final state = Provider.of<AppState>(context, listen: false);
    final rtRw = state.lookupRegistrationCode(code);

    setState(() {
      _codeLookupAttempted =
          code.length >= 4; // Only show feedback after 4+ chars
      if (rtRw != null) {
        _codeFound = true;
        _foundRtRw = rtRw;
        _rtRwController.text = rtRw;
      } else {
        _codeFound = false;
        _foundRtRw = null;
        _rtRwController.text = '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registrationCodeController.dispose();
    _rtRwController.dispose();
    _addressController.dispose();
    _jabatanController.dispose();
    _wilayahController.dispose();
    _rtRegistrationCodeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan.'),
          backgroundColor: AppTheme.statusHigh,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;

        final state = Provider.of<AppState>(context, listen: false);

        if (widget.isWarga) {
          state.registerWarga(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            registrationCode: _registrationCodeController.text,
            phone: _phoneController.text,
            rtRw: _rtRwController.text,
            address: _addressController.text,
            ktpImagePath: _ktpImageFile?.path,
          );
          // Warga goes to waiting verification
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/waiting-verification', (route) => false);
        } else {
          state.registerRT(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            jabatan: _jabatanController.text,
            rtRw: _wilayahController.text,
          );
          // Save registration code if provided
          final regCode = _rtRegistrationCodeController.text.trim();
          if (regCode.isNotEmpty) {
            state.addRegistrationCode(
              code: regCode,
              rtRw: _wilayahController.text,
            );
          }
          // RT goes directly to home
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        }

        setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Radial Mesh Background elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryFixedDim.withValues(alpha: 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Brand Logo & Header
                    Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainerColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isWarga
                                ? Icons.person_add
                                : Icons.admin_panel_settings,
                            size: 36,
                            color: AppTheme.primaryFixedDim,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isWarga
                              ? 'Daftar Sebagai Warga'
                              : 'Daftar Sebagai RT/RW',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 22,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.isWarga
                                ? 'Lengkapi data diri Anda untuk mendaftar sebagai warga. Akun akan diverifikasi oleh RT.'
                                : 'Lengkapi data diri Anda untuk mendaftar sebagai pengurus RT/RW.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isWarga
                            ? AppTheme.primaryFixed.withValues(alpha: 0.3)
                            : AppTheme.tertiaryFixed.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isWarga
                                ? Icons.people
                                : Icons.admin_panel_settings,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isWarga
                                ? 'PENDAFTARAN WARGA'
                                : 'PENDAFTARAN RT/RW',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.outlineVariantColor.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.03,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name field
                            _buildInputLabel('NAMA LENGKAP'),
                            const SizedBox(height: 4),
                            _buildTextFormField(
                              controller: _nameController,
                              hintText: 'Budi Santoso',
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email field
                            _buildInputLabel('EMAIL'),
                            const SizedBox(height: 4),
                            _buildTextFormField(
                              controller: _emailController,
                              hintText: 'budi@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.contains('@')) {
                                  return 'Format email salah';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Phone
                            _buildInputLabel('NOMOR TELEPON'),
                            const SizedBox(height: 4),
                            _buildTextFormField(
                              controller: _phoneController,
                              hintText: '0812xxxxxxxx',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nomor telepon wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Role-specific fields
                            if (widget.isWarga) ...[
                              // Kode Registrasi RT
                              _buildInputLabel('KODE REGISTRASI RT'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _registrationCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                decoration: _buildInputDecoration(
                                  hintText:
                                      'Masukkan kode dari RT (misal: RT05-XY7K)',
                                  prefixIcon: Icons.vpn_key_outlined,
                                  suffixIcon: _codeLookupAttempted
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Icon(
                                            _codeFound
                                                ? Icons.check_circle_rounded
                                                : Icons.error_outline_rounded,
                                            color: _codeFound
                                                ? AppTheme.statusLow
                                                : AppTheme.statusHigh,
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kode registrasi wajib diisi';
                                  }
                                  if (!_codeFound) {
                                    return 'Kode registrasi tidak ditemukan';
                                  }
                                  return null;
                                },
                              ),
                              if (_codeLookupAttempted) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _codeFound
                                        ? AppTheme.statusLow.withValues(
                                            alpha: 0.08,
                                          )
                                        : AppTheme.statusHigh.withValues(
                                            alpha: 0.08,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _codeFound
                                          ? AppTheme.statusLow.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppTheme.statusHigh.withValues(
                                              alpha: 0.2,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _codeFound
                                            ? Icons.check_circle_outline
                                            : Icons.warning_amber_rounded,
                                        size: 14,
                                        color: _codeFound
                                            ? AppTheme.statusLow
                                            : AppTheme.statusHigh,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _codeFound
                                              ? 'Kode valid! RT/RW: $_foundRtRw — terisi otomatis'
                                              : 'Kode registrasi tidak ditemukan. Pastikan kode dari RT Anda benar.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _codeFound
                                                ? AppTheme.statusLow
                                                : AppTheme.statusHigh,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Upload Foto KTP
                              _buildInputLabel('FOTO KTP'),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _showKtpImageSourcePicker,
                                child: Container(
                                  width: double.infinity,
                                  height: _ktpImageFile != null ? null : 130,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _ktpImageFile != null
                                          ? AppTheme.primaryColor.withValues(
                                              alpha: 0.4,
                                            )
                                          : AppTheme.outlineVariantColor,
                                      width: 1.5,
                                      style: _ktpImageFile != null
                                          ? BorderStyle.solid
                                          : BorderStyle.none,
                                    ),
                                  ),
                                  child: _ktpImageFile != null
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              child: Image.file(
                                                _ktpImageFile!,
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
                                                  _buildKtpActionButton(
                                                    icon: Icons.edit_rounded,
                                                    color:
                                                        AppTheme.primaryColor,
                                                    onTap:
                                                        _showKtpImageSourcePicker,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _buildKtpActionButton(
                                                    icon: Icons.delete_rounded,
                                                    color: AppTheme.statusHigh,
                                                    onTap: () {
                                                      setState(() {
                                                        _ktpImageFile = null;
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        bottom: Radius.circular(
                                                          11,
                                                        ),
                                                      ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withValues(
                                                        alpha: 0.6,
                                                      ),
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
                                                      'Foto KTP berhasil diupload',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter: _DashedBorderPainter(
                                              color:
                                                  AppTheme.outlineVariantColor,
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
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Upload atau Foto KTP',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Tap untuk mengambil foto atau pilih dari galeri',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme
                                                          .secondaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // RT/RW & Alamat
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('RT/RW'),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _rtRwController,
                                          readOnly: _codeFound,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _codeFound
                                                ? AppTheme.primaryColor
                                                : AppTheme.textPrimaryColor,
                                            fontWeight: _codeFound
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          decoration: _buildInputDecoration(
                                            hintText: _codeFound
                                                ? ''
                                                : '005/002',
                                            prefixIcon:
                                                Icons.location_on_outlined,
                                            suffixIcon: _codeFound
                                                ? const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8,
                                                    ),
                                                    child: Icon(
                                                      Icons.lock_rounded,
                                                      size: 16,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Wajib diisi';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('ALAMAT'),
                                        const SizedBox(height: 4),
                                        _buildTextFormField(
                                          controller: _addressController,
                                          hintText: 'Jl. Mawar No. 10',
                                          prefixIcon: Icons.home_outlined,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Wajib diisi';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ] else ...[
                              // Jabatan
                              _buildInputLabel('JABATAN'),
                              const SizedBox(height: 4),
                              _buildTextFormField(
                                controller: _jabatanController,
                                hintText: 'Ketua RT 05',
                                prefixIcon: Icons.admin_panel_settings_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Jabatan wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Wilayah RT/RW
                              _buildInputLabel('NOMOR RT/RW'),
                              const SizedBox(height: 4),
                              _buildTextFormField(
                                controller: _wilayahController,
                                hintText: '005/002',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nomor RT/RW wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Kode Registrasi Warga
                              _buildInputLabel('KODE REGISTRASI UNTUK WARGA'),
                              const SizedBox(height: 4),
                              const Text(
                                'Buat kode registrasi yang akan digunakan warga untuk mendaftar ke RT Anda. Anda bisa mengisi sendiri atau generate otomatis.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.secondaryColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _rtRegistrationCodeController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimaryColor,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                      decoration: _buildInputDecoration(
                                        hintText: 'RT05-XXXX',
                                        prefixIcon: Icons.vpn_key_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryFixed,
                                        foregroundColor: AppTheme.primaryColor,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        final rtRw = _wilayahController.text
                                            .trim();
                                        if (rtRw.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Isi Nomor RT/RW terlebih dahulu',
                                              ),
                                              backgroundColor:
                                                  AppTheme.statusMedium,
                                            ),
                                          );
                                          return;
                                        }
                                        final state = Provider.of<AppState>(
                                          context,
                                          listen: false,
                                        );
                                        final code = state
                                            .generateRegistrationCode(rtRw);
                                        _rtRegistrationCodeController.text =
                                            code;
                                      },
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Generate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryFixed.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Bagikan kode ini ke warga agar mereka bisa mendaftar ke RT Anda. Opsional — bisa juga dibuat nanti dari Profil.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primaryColor,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Password Field
                            _buildInputLabel('PASSWORD'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                              decoration: _buildInputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.outlineColor,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password wajib diisi';
                                }
                                if (value.length < 6) {
                                  return 'Minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Confirm Password
                            _buildInputLabel('KONFIRMASI PASSWORD'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                              decoration: _buildInputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmText
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.outlineColor,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmText =
                                          !_obscureConfirmText;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password wajib diisi';
                                }
                                if (value != _passwordController.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Terms checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (val) {
                                      setState(() {
                                        _agreeToTerms = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Saya setuju dengan Syarat & Ketentuan serta Kebijakan Privasi yang berlaku.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondaryColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.primaryContainerColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _handleRegister,
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.person_add, size: 18),
                                label: _isLoading
                                    ? const SizedBox()
                                    : const Text(
                                        'Daftar Sekarang',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),

                            if (widget.isWarga) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusMedium.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.statusMedium.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppTheme.statusMedium,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Setelah mendaftar, akun Anda akan menunggu verifikasi dari RT setempat.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.statusMedium,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back to Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryContainerColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: AppTheme.secondaryColor,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
      decoration: _buildInputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
      ),
      fillColor: Colors.white,
      filled: true,
      prefixIcon: Icon(prefixIcon, color: AppTheme.outlineColor, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppTheme.outlineVariantColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.statusHigh, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.statusHigh, width: 1.5),
      ),
    );
  }

  Widget _buildKtpActionButton({
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
  final double dashWidth = 6.0;
  final double dashSpace = 4.0;
  final double strokeWidth = 1.5;

  _DashedBorderPainter({required this.color, this.borderRadius = 12});

  @override
  void paint(Canvas canvas, Size size) {
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
