import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import '../../theme.dart';
import 'ktp_image_preview.dart';

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
  final _ktpNumberController = TextEditingController();

  // KTP Image
  KtpImagePreview? _ktpImage;
  final ImagePicker _imagePicker = ImagePicker();

  // RT-specific
  final _jabatanController = TextEditingController();
  final _rtRegistrationCodeController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _wargaRegistrationCodeController = TextEditingController();

  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  // Warga: code lookup status
  bool _codeFound = false;
  bool _codeLookupAttempted = false;
  String? _foundRtRw;
  int _registrationLookupToken = 0;
  String? _rtRegistrationCodeErrorText;
  int _rtRegistrationLookupToken = 0;
  bool _isGeneratingWargaCode = false;
  static final RegExp _rtRegistrationCodePattern = RegExp(
    r'^RT(\d{2})-(\d{2})$',
    caseSensitive: false,
  );

  Future<void> _pickKtpImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final preview = await createKtpImagePreviewFromXFile(pickedFile);
        if (!mounted) return;
        setState(() {
          _ktpImage = preview;
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
    if (widget.isWarga) {
      _registrationCodeController.addListener(_onRegistrationCodeChanged);
    }
  }

  void _clearRtRegistrationLookup() {
    _rtRegistrationLookupToken++;
    _rtRegistrationCodeErrorText = null;
    _rtController.text = '';
    _rwController.text = '';
    _wargaRegistrationCodeController.text = '';
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

    final lookupToken = ++_registrationLookupToken;
    final state = Provider.of<AppState>(context, listen: false);
    final useRemoteLookup = SupabaseService.isInitialized;

    Future<String?> lookup() async {
      if (useRemoteLookup) {
        return state.lookupRegistrationCodeRemote(code);
      }
      return state.lookupRegistrationCode(code);
    }

    lookup().then((rtRw) {
      if (!mounted || lookupToken != _registrationLookupToken) return;

      setState(() {
        _codeLookupAttempted = code.length >= 4;
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
    });
  }

  Future<void> _onRtRegistrationCodeChanged(String value) async {
    final code = value.trim();
    debugPrint('TEXTFIELD onChanged value="$code"');

    if (code.isEmpty) {
      if (!mounted) return;
      setState(_clearRtRegistrationLookup);
      return;
    }

    if (!_rtRegistrationCodePattern.hasMatch(code)) {
      if (!mounted) return;
      setState(() {
        _rtRegistrationCodeErrorText = code.length >= 7
            ? 'Kode registrasi RT tidak valid, tidak aktif, atau sudah digunakan.'
            : null;
        _rtController.text = '';
        _rwController.text = '';
        _wargaRegistrationCodeController.text = '';
      });
      return;
    }

    final lookupToken = ++_rtRegistrationLookupToken;
    final state = Provider.of<AppState>(context, listen: false);
    final useRemoteLookup = SupabaseService.isInitialized;

    if (!useRemoteLookup) {
      if (!mounted || lookupToken != _rtRegistrationLookupToken) return;
      setState(() {
        _rtRegistrationCodeErrorText =
            'Konfigurasi Supabase belum aktif untuk memvalidasi kode RT.';
        _rtController.text = '';
        _rwController.text = '';
        _wargaRegistrationCodeController.text = '';
      });
      return;
    }

    debugPrint('CALL AppState lookup code="$code"');
    final lookup = await state.lookupRtRegistrationCodeRemote(code);
    if (!mounted || lookupToken != _rtRegistrationLookupToken) return;

    setState(() {
      if (lookup != null) {
        _rtRegistrationCodeErrorText = null;
        _rtController.text = lookup.rt;
        _rwController.text = lookup.rw;
        _wargaRegistrationCodeController.text = '';
      } else {
        _rtRegistrationCodeErrorText =
            'Kode registrasi RT tidak valid, tidak aktif, atau sudah digunakan.';
        _rtController.text = '';
        _rwController.text = '';
        _wargaRegistrationCodeController.text = '';
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
    _ktpNumberController.dispose();
    _ktpImage = null;
    _jabatanController.dispose();
    _rtRegistrationCodeController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _wargaRegistrationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
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
      try {
        if (!mounted) return;

        final state = Provider.of<AppState>(context, listen: false);

        if (widget.isWarga && SupabaseService.isInitialized) {
          final ktpImage = _ktpImage;
          if (ktpImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto KTP wajib diunggah.'),
                backgroundColor: AppTheme.statusHigh,
              ),
            );
            return;
          }

          final result = await state.registerWargaWithSupabase(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            registrationCode: _registrationCodeController.text,
            ktpNumber: _ktpNumberController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            ktpImageBytes: ktpImage.bytes,
            ktpImageName: ktpImage.fileName,
          );

          if (!mounted) return;

          if (result['success'] == true) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/waiting-verification',
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message']?.toString() ??
                      'Registrasi warga gagal. Silakan coba lagi.',
                ),
                backgroundColor: AppTheme.statusHigh,
              ),
            );
          }
        } else if (widget.isWarga) {
          state.registerWarga(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            registrationCode: _registrationCodeController.text,
            phone: _phoneController.text,
            rtRw: _rtRwController.text,
            address: _addressController.text,
            ktpImagePath: _ktpImage?.localPath,
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/waiting-verification', (route) => false);
        } else {
          final rt = _rtController.text.trim();
          final rw = _rwController.text.trim();
          final rtRw = '$rt/$rw';

          if (SupabaseService.isInitialized) {
            final result = await state.registerRTWithSupabase(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              registrationCode: _rtRegistrationCodeController.text,
              phone: _phoneController.text,
              jabatan: _jabatanController.text,
            );

            if (!mounted) return;

            if (result['success'] == true) {
              final wargaCode = result['wargaRegistrationCode']?.toString();
              if (wargaCode != null && wargaCode.isNotEmpty) {
                setState(() {
                  _wargaRegistrationCodeController.text = wargaCode;
                });
              }
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message']?.toString() ??
                        'Registrasi RT gagal. Silakan coba lagi.',
                  ),
                  backgroundColor: AppTheme.statusHigh,
                ),
              );
            }
          } else {
            state.registerRT(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              phone: _phoneController.text,
              jabatan: _jabatanController.text,
              rtRw: rtRw,
            );
            final regCode = state.generateWargaRegistrationCode(rtRw);
            _wargaRegistrationCodeController.text = regCode;
            if (regCode.isNotEmpty) {
              state.addRegistrationCode(code: regCode, rtRw: rtRw);
            }
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainerColor,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isWarga
                                ? Icons.person_add
                                : Icons.admin_panel_settings,
                            size: 38,
                            color: AppTheme.primaryFixedDim,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isWarga
                              ? 'Daftar Sebagai Warga'
                              : 'Daftar Sebagai RT/RW',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 24,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            widget.isWarga
                                ? 'Lengkapi data diri Anda untuk mendaftar sebagai warga. Akun akan diverifikasi oleh RT.'
                                : 'Lengkapi data diri Anda untuk mendaftar sebagai pengurus RT/RW.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 13,
                              height: 1.4,
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
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isWarga
                            ? AppTheme.primaryFixed.withValues(alpha: 0.3)
                            : AppTheme.tertiaryFixed.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
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
                              fontWeight: FontWeight.w700,
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.outlineVariantColor.withValues(
                            alpha: 0.55,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
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
                              // KTP Number
                              _buildInputLabel('NOMOR KTP / NIK'),
                              const SizedBox(height: 4),
                              _buildTextFormField(
                                controller: _ktpNumberController,
                                hintText: '317xxxxxxxxxxxxx',
                                prefixIcon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nomor KTP / NIK wajib diisi';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Nomor KTP / NIK tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

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
                                  if (!SupabaseService.isInitialized &&
                                      !_codeFound) {
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
                                    borderRadius: BorderRadius.circular(12),
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

                              // Upload Foto KTP
                              _buildInputLabel('FOTO KTP'),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _showKtpImageSourcePicker,
                                child: Container(
                                  width: double.infinity,
                                  height: _ktpImage != null ? 220 : 130,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _ktpImage != null
                                          ? AppTheme.primaryColor.withValues(
                                              alpha: 0.4,
                                            )
                                          : AppTheme.outlineVariantColor,
                                      width: 1.5,
                                      style: _ktpImage != null
                                          ? BorderStyle.solid
                                          : BorderStyle.none,
                                    ),
                                  ),
                                  child: _ktpImage != null
                                      ? Stack(
                                          children: [
                                            Positioned.fill(
                                              child: _ktpImage!.buildPreview(
                                                borderRadius:
                                                    BorderRadius.circular(15),
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
                                                        _ktpImage = null;
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
                                              borderRadius: 16,
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

                              // Kode Registrasi RT
                              _buildInputLabel('KODE REGISTRASI RT'),
                              const SizedBox(height: 4),
                              const Text(
                                'Masukkan kode registrasi yang telah dibuat oleh admin desa.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.secondaryColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _rtRegistrationCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                onChanged: (value) {
                                  _onRtRegistrationCodeChanged(value);
                                },
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                                decoration:
                                    _buildInputDecoration(
                                      hintText: 'RT03-10',
                                      prefixIcon: Icons.vpn_key_outlined,
                                    ).copyWith(
                                      errorText: _rtRegistrationCodeErrorText,
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kode registrasi RT wajib diisi';
                                  }
                                  if (_rtRegistrationCodeErrorText != null) {
                                    return _rtRegistrationCodeErrorText;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('RT'),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _rtController,
                                          readOnly: true,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textPrimaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: _buildInputDecoration(
                                            hintText: '',
                                            prefixIcon: Icons.numbers_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('RW'),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _rwController,
                                          readOnly: true,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textPrimaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: _buildInputDecoration(
                                            hintText: '',
                                            prefixIcon: Icons.numbers_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _buildInputLabel('KODE DAFTAR WARGA'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _wargaRegistrationCodeController,
                                readOnly: true,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'WRG03-10',
                                  prefixIcon: Icons.badge_outlined,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: _buildSecondaryActionButtonStyle(),
                                  onPressed: _isGeneratingWargaCode
                                      ? null
                                      : () async {
                                          final rt = _rtController.text.trim();
                                          final rw = _rwController.text.trim();
                                          final rtRw = '$rt/$rw';

                                          if (rt.isEmpty || rw.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Kode registrasi RT harus valid terlebih dahulu.',
                                                ),
                                                backgroundColor:
                                                    AppTheme.statusMedium,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            _isGeneratingWargaCode = true;
                                          });

                                          try {
                                            final state = Provider.of<AppState>(
                                              context,
                                              listen: false,
                                            );
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final result = await state
                                                .generateWargaRegistrationCodeForRt(
                                                  rtRw,
                                                );

                                            if (!mounted) return;

                                            if (result['success'] == true) {
                                              setState(() {
                                                _wargaRegistrationCodeController
                                                        .text =
                                                    result['code']
                                                        ?.toString() ??
                                                    '';
                                              });
                                            } else {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    result['message']
                                                            ?.toString() ??
                                                        'Gagal membuat kode daftar warga.',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.statusHigh,
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _isGeneratingWargaCode = false;
                                              });
                                            }
                                          }
                                        },
                                  icon: _isGeneratingWargaCode
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppTheme.primaryColor,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.auto_awesome,
                                          size: 16,
                                        ),
                                  label: Text(
                                    _isGeneratingWargaCode
                                        ? 'Membuat...'
                                        : 'Generate Kode Daftar Warga',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                                    fillColor:
                                        MaterialStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            MaterialState.disabled,
                                          )) {
                                            return AppTheme.outlineVariantColor;
                                          }
                                          return states.contains(
                                                MaterialState.selected,
                                              )
                                              ? AppTheme.primaryColor
                                              : Colors.white;
                                        }),
                                    side: const BorderSide(
                                      color: AppTheme.outlineColor,
                                      width: 1.2,
                                    ),
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
                                style: _buildPrimaryActionButtonStyle(),
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
                                          fontWeight: FontWeight.w700,
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
                                  borderRadius: BorderRadius.circular(12),
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
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
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
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimaryColor),
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
        color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
      ),
      fillColor: Colors.white,
      filled: true,
      prefixIcon: Icon(prefixIcon, color: AppTheme.outlineColor, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(fontSize: 11.5, height: 1.2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppTheme.outlineVariantColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.statusHigh, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.statusHigh, width: 1.5),
      ),
    );
  }

  ButtonStyle _buildPrimaryActionButtonStyle() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppTheme.surfaceContainerHighest;
        }
        if (states.contains(MaterialState.pressed)) {
          return AppTheme.tertiaryColor;
        }
        if (states.contains(MaterialState.hovered)) {
          return AppTheme.primaryColor.withValues(alpha: 0.92);
        }
        return AppTheme.primaryColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppTheme.textSecondaryColor.withValues(alpha: 0.65);
        }
        return Colors.white;
      }),
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        if (states.contains(MaterialState.hovered)) {
          return Colors.white.withValues(alpha: 0.06);
        }
        return null;
      }),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
      elevation: MaterialStateProperty.all(0),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: MaterialStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(52)),
    );
  }

  ButtonStyle _buildSecondaryActionButtonStyle() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppTheme.surfaceContainerHighest;
        }
        if (states.contains(MaterialState.pressed)) {
          return AppTheme.primaryContainerColor;
        }
        if (states.contains(MaterialState.hovered)) {
          return AppTheme.primaryFixed.withValues(alpha: 0.22);
        }
        return Colors.white;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppTheme.textSecondaryColor.withValues(alpha: 0.65);
        }
        return AppTheme.primaryColor;
      }),
      side: MaterialStateProperty.resolveWith((states) {
        final color = states.contains(MaterialState.disabled)
            ? AppTheme.outlineVariantColor
            : AppTheme.primaryColor;
        return BorderSide(color: color, width: 1.2);
      }),
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return AppTheme.primaryColor.withValues(alpha: 0.08);
        }
        if (states.contains(MaterialState.hovered)) {
          return AppTheme.primaryColor.withValues(alpha: 0.05);
        }
        return null;
      }),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
      elevation: MaterialStateProperty.all(0),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: MaterialStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
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

  _DashedBorderPainter({required this.color, this.borderRadius = 16});

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
