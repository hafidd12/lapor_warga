import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class RegisterScreen extends StatefulWidget {
  final bool isWarga;
  const RegisterScreen({Key? key, required this.isWarga}) : super(key: key);

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
  final _ktpController = TextEditingController();
  final _rtRwController = TextEditingController();
  final _addressController = TextEditingController();

  // RT-specific
  final _jabatanController = TextEditingController();
  final _wilayahController = TextEditingController();

  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ktpController.dispose();
    _rtRwController.dispose();
    _addressController.dispose();
    _jabatanController.dispose();
    _wilayahController.dispose();
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
            ktpNumber: _ktpController.text,
            phone: _phoneController.text,
            rtRw: _rtRwController.text,
            address: _addressController.text,
          );
          // Warga goes to waiting verification
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/waiting-verification', (route) => false);
        } else {
          state.registerRT(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            jabatan: _jabatanController.text,
            rtRw: _wilayahController.text,
          );
          // RT goes directly to home
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
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
                color: AppTheme.primaryFixed.withOpacity(0.15),
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
                color: AppTheme.tertiaryFixedDim.withOpacity(0.12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                                color:
                                    AppTheme.primaryColor.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
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
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isWarga
                            ? AppTheme.primaryFixed.withOpacity(0.3)
                            : AppTheme.tertiaryFixed.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.outlineVariantColor
                              .withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primaryColor.withOpacity(0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
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
                              _buildInputLabel('NIK / NOMOR KTP'),
                              const SizedBox(height: 4),
                              _buildTextFormField(
                                controller: _ktpController,
                                hintText: '320123456789xxxx',
                                prefixIcon: Icons.credit_card_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'NIK wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // RT/RW & Alamat
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('RT/RW'),
                                        const SizedBox(height: 4),
                                        _buildTextFormField(
                                          controller: _rtRwController,
                                          hintText: '005/002',
                                          prefixIcon:
                                              Icons.location_on_outlined,
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
                                prefixIcon:
                                    Icons.admin_panel_settings_outlined,
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
                            ],

                            // Password Field
                            _buildInputLabel('PASSWORD'),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor),
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
                                  color: AppTheme.textPrimaryColor),
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
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed:
                                    _isLoading ? null : _handleRegister,
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.person_add,
                                        size: 18),
                                label: _isLoading
                                    ? const SizedBox()
                                    : const Text(
                                        'Daftar Sekarang',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                              ),
                            ),

                            if (widget.isWarga) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusMedium
                                      .withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.statusMedium
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.info_outline,
                                        size: 16,
                                        color: AppTheme.statusMedium),
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
                              color: AppTheme.secondaryColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login', (route) => false);
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
      style:
          const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
      decoration: _buildInputDecoration(
          hintText: hintText, prefixIcon: prefixIcon),
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
      hintStyle:
          TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.5)),
      fillColor: Colors.white,
      filled: true,
      prefixIcon:
          Icon(prefixIcon, color: AppTheme.outlineColor, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: AppTheme.outlineVariantColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.statusHigh, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.statusHigh, width: 1.5),
      ),
    );
  }
}
