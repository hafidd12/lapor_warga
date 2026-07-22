import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/custom_image.dart';

class ProfilWargaScreen extends StatefulWidget {
  const ProfilWargaScreen({super.key, required this.onGoToAktivitas});

  final VoidCallback onGoToAktivitas;

  @override
  State<ProfilWargaScreen> createState() => _ProfilWargaScreenState();
}

class _ProfilWargaScreenState extends State<ProfilWargaScreen> {
  String _editingField = '';
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null || !mounted) return;

    final croppedFile = await _cropAvatarImage(pickedFile);
    if (croppedFile == null || !mounted) return;

    final state = Provider.of<AppState>(context, listen: false);
    try {
      final imageBytes = await croppedFile.readAsBytes();
      await state.saveCurrentUserProfile(
        avatarBytes: imageBytes,
        avatarSourceName: pickedFile.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui'),
          backgroundColor: AppTheme.statusLow,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui foto profil: $error'),
          backgroundColor: AppTheme.statusHigh,
        ),
      );
    }
  }

  Future<CroppedFile?> _cropAvatarImage(XFile pickedFile) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Foto',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Foto',
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
          ),
        ],
      );
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memotong foto: $error'),
          backgroundColor: AppTheme.statusHigh,
        ),
      );
      return null;
    }
  }

  Future<void> _showAvatarPreview(String avatarUrl) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        final hasAvatar = avatarUrl.trim().isNotEmpty;
        final imageProvider = hasAvatar
            ? CustomImageProvider.get(avatarUrl)
            : null;

        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: hasAvatar
                        ? InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image(
                              image: imageProvider!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 120,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(AppState state) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      state.logout();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil',
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 16),
            _buildQuickLinkCard(context, widget.onGoToAktivitas),
            const SizedBox(height: 16),
            _buildDataDiriSection(user),
            const SizedBox(height: 16),
            _buildSecurityInfoCard(),
            const SizedBox(height: 24),
            _buildLogoutButton(context, state),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    final avatarUrl = user?.avatarUrl?.trim() ?? '';
    final userName = user?.name?.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Nama Pengguna';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryContainerColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => _showAvatarPreview(avatarUrl),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CustomImageProvider.get(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Ambil Foto'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Pilih dari Galeri'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 18, color: Color(0xFF166534)),
              const SizedBox(width: 6),
              Text(
                'Warga Terverifikasi RT ${user?.rtRw?.split('/').first.replaceAll(RegExp(r'^0+'), '') ?? '05'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkCard(
    BuildContext context,
    VoidCallback onGoToAktivitas,
  ) {
    return GestureDetector(
      onTap: () {
        onGoToAktivitas();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariantColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: AppTheme.onPrimaryContainerColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Laporan Saya',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat status & tanggapan laporan Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDiriSection(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Data Diri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditableRow(
            label: 'NAMA LENGKAP',
            value: user?.name ?? 'Nama Pengguna',
            icon: Icons.person_outline,
            fieldKey: 'name',
            onSave: (newValue) async {
              await Provider.of<AppState>(
                context,
                listen: false,
              ).saveCurrentUserProfile(name: newValue);
            },
          ),
          _buildDivider(),
          _buildEditableRow(
            label: 'NO. RUMAH / BLOK',
            value: user?.address ?? 'Belum diisi',
            icon: Icons.home_outlined,
            fieldKey: 'address',
            onSave: (newValue) async {
              await Provider.of<AppState>(
                context,
                listen: false,
              ).saveCurrentUserProfile(address: newValue);
            },
          ),
          _buildDivider(),
          _buildEditableRow(
            label: 'NOMOR WHATSAPP',
            value: user?.phone ?? 'Belum diisi',
            icon: Icons.phone_outlined,
            fieldKey: 'phone',
            onSave: (newValue) async {
              await Provider.of<AppState>(
                context,
                listen: false,
              ).saveCurrentUserProfile(phone: newValue);
            },
          ),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required String label,
    required String value,
    required IconData icon,
    required String fieldKey,
    required Future<void> Function(String) onSave,
  }) {
    final isEditing = _editingField == fieldKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (isEditing) {
              setState(() => _editingField = '');
            } else {
              setState(() {
                _editingField = fieldKey;
                _editController.text = value == 'Belum diisi' ? '' : value;
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(icon, size: 22, color: AppTheme.outlineColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Icon(
                      isEditing ? Icons.expand_less : Icons.edit,
                      size: 16,
                      color: AppTheme.outlineColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.outlineVariantColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UBAH $label',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _editController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan ${label.toLowerCase()} baru',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.outlineVariantColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.outlineVariantColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final newValue = _editController.text.trim();
                          if (newValue.isEmpty) {
                            setState(() {
                              _editingField = '';
                              _editController.clear();
                            });
                            return;
                          }

                          try {
                            await onSave(newValue);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$label berhasil diperbarui.'),
                                backgroundColor: AppTheme.statusLow,
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal memperbarui $label: $error',
                                ),
                                backgroundColor: AppTheme.statusHigh,
                              ),
                            );
                          }

                          if (!mounted) return;
                          setState(() {
                            _editingField = '';
                            _editController.clear();
                          });
                        },
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                          side: BorderSide(
                            color: AppTheme.outlineVariantColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _editingField = '';
                            _editController.clear();
                          });
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          crossFadeState: isEditing
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildSecurityInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryContainerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Akun Anda telah diverifikasi oleh Ketua RT dan siap digunakan untuk mengirim serta memantau laporan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppState state) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.statusHigh,
          side: BorderSide(
            color: AppTheme.statusHigh.withValues(alpha: 0.2),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _confirmLogout(state),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      color: AppTheme.outlineVariantColor.withValues(alpha: 0.3),
    );
  }
}
