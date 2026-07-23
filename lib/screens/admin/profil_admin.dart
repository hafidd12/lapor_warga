import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/custom_image.dart';
import '../../widgets/notification_bell_button.dart';

class ProfilAdminScreen extends StatefulWidget {
  const ProfilAdminScreen({super.key, this.onGoToApprovedWarga});

  final VoidCallback? onGoToApprovedWarga;

  @override
  State<ProfilAdminScreen> createState() => _ProfilAdminScreenState();
}

class _ProfilAdminScreenState extends State<ProfilAdminScreen> {
  bool _showPasswordForm = false;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _editingField = '';
  final _editController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
    final transformationController = TransformationController();
    var isZoomed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      builder: (context) {
        final hasAvatar = avatarUrl.trim().isNotEmpty;
        final imageProvider = hasAvatar
            ? CustomImageProvider.get(avatarUrl)
            : null;

        void toggleZoom() {
          if (!hasAvatar) return;
          isZoomed = !isZoomed;
          final matrix = Matrix4.identity();
          if (isZoomed) {
            matrix.scale(2.5);
          }
          transformationController.value = matrix;
        }

        return Material(
          color: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: hasAvatar
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            onDoubleTap: toggleZoom,
                            child: InteractiveViewer(
                              transformationController:
                                  transformationController,
                              minScale: 1,
                              maxScale: 4,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Image(
                                image: imageProvider!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.admin_panel_settings,
                            size: 120,
                            color: Colors.white70,
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Log Out'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusHigh,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log Out'),
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Profil RT',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.2,
          ),
        ),
        actions: const [NotificationBellButton()],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 16),
            _buildInfoFields(user),
            const SizedBox(height: 32),
            _buildManagementSection(context, state),
            const SizedBox(height: 12),
            Text(
              'Terakhir diperbarui: ${_formatDate(DateTime.now())}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
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
        : 'Nama belum tersedia';
    final rtRwLabel = _formatRtRwLabel(user?.rtRw);
    final jabatan = rtRwLabel.isNotEmpty
        ? 'Ketua $rtRwLabel'
        : user?.jabatan?.trim().isNotEmpty == true
        ? user!.jabatan!.trim()
        : 'Jabatan belum tersedia';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
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
        children: [
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: avatarUrl.isEmpty
                      ? null
                      : () => _showAvatarPreview(avatarUrl),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? CustomImageProvider.get(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
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
                      size: 16,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            jabatan,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRtRwLabel(String? rtRw) {
    final raw = rtRw?.trim() ?? '';
    if (raw.isEmpty) return '';

    final parts = raw.split('/');
    if (parts.length < 2) return '';

    final rt = _normalizeRtRwPart(parts[0]);
    final rw = _normalizeRtRwPart(parts[1]);
    if (rt.isEmpty || rw.isEmpty) return '';

    return 'RT $rt / RW $rw';
  }

  String _normalizeRtRwPart(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return digits.padLeft(2, '0').substring(digits.padLeft(2, '0').length - 2);
  }

  Widget _buildInfoFields(dynamic user) {
    return Column(
      children: [
        // Editable Name
        _buildEditableCard(
          label: 'Nama Lengkap',
          value: user?.name ?? 'Admin Lapor Warga',
          icon: Icons.person_outline,
          fieldKey: 'name',
          onSave: (newValue) async {
            await Provider.of<AppState>(
              context,
              listen: false,
            ).saveCurrentUserProfile(name: newValue);
          },
        ),
        const SizedBox(height: 10),

        // Static Location (Wilayah Tugas)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wilayah Tugas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 22,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'RT ${user?.rtRw?.split("/").first.replaceAll(RegExp(r"^0+"), "") ?? "05"} / RW ${user?.rtRw?.split("/").last.replaceAll(RegExp(r"^0+"), "") ?? "02"}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Editable WhatsApp
        _buildEditableCard(
          label: 'Nomor WhatsApp Layanan',
          value: user?.phone ?? '+62 812-3456-7890',
          icon: Icons.chat_outlined,
          fieldKey: 'phone',
          onSave: (newValue) async {
            await Provider.of<AppState>(
              context,
              listen: false,
            ).saveCurrentUserProfile(phone: newValue);
          },
        ),
      ],
    );
  }

  Widget _buildEditableCard({
    required String label,
    required String value,
    required IconData icon,
    required String fieldKey,
    required Future<void> Function(String) onSave,
  }) {
    final isEditing = _editingField == fieldKey;

    return Container(
      width: double.infinity,
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (isEditing) {
                setState(() => _editingField = '');
              } else {
                setState(() {
                  _editingField = fieldKey;
                  _editController.text = value;
                  _showPasswordForm = false; // close password form if open
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isEditing
                  ? AppTheme.surfaceContainerLow
                  : Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(icon, size: 22, color: AppTheme.textSecondaryColor),
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
                        color: AppTheme.textSecondaryColor.withValues(
                          alpha: 0.6,
                        ),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.outlineVariantColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Ubah $label',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _editController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan ${label.toLowerCase()} baru',
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondaryColor,
                            side: const BorderSide(
                              color: AppTheme.outlineColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                              fontSize: 14,
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
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      width: double.infinity,
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Password tap header
          GestureDetector(
            onTap: () {
              setState(() {
                _showPasswordForm = !_showPasswordForm;
                _editingField = ''; // close other forms
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _showPasswordForm
                  ? AppTheme.surfaceContainerLow
                  : Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kata Sandi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 22,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '•••••••••',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Icon(
                        _showPasswordForm ? Icons.expand_less : Icons.edit,
                        size: 16,
                        color: AppTheme.textSecondaryColor.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expandable password form
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.outlineVariantColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Masukkan Sandi Baru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
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
                  const SizedBox(height: 12),
                  const Text(
                    'Ulangi Sandi Baru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final newPassword = _newPasswordController.text
                                .trim();
                            final confirmPassword = _confirmPasswordController
                                .text
                                .trim();

                            if (newPassword.isEmpty ||
                                confirmPassword.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password baru wajib diisi.'),
                                  backgroundColor: AppTheme.statusHigh,
                                ),
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sandi baru dan ulangi sandi tidak cocok.',
                                  ),
                                  backgroundColor: AppTheme.statusHigh,
                                ),
                              );
                              return;
                            }
                            try {
                              await Provider.of<AppState>(
                                context,
                                listen: false,
                              ).updateCurrentUserPassword(newPassword);
                            } catch (error) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal memperbarui Kata Sandi: $error',
                                  ),
                                  backgroundColor: AppTheme.statusHigh,
                                ),
                              );
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Kata sandi berhasil diperbarui.',
                                ),
                                backgroundColor: AppTheme.statusLow,
                              ),
                            );
                            setState(() {
                              _showPasswordForm = false;
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                          child: const Text(
                            'Simpan Sandi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondaryColor,
                            side: const BorderSide(
                              color: AppTheme.outlineColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showPasswordForm = false;
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _showPasswordForm
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'MANAJEMEN RT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // Daftar & Data Warga RT
        _buildManagementItem(
          icon: Icons.group_outlined,
          title: 'Daftar & Data Warga RT',
          onTap: widget.onGoToApprovedWarga ?? () {},
        ),
        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
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
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementItem({
    required IconData icon,
    required String title,
    int? badgeCount,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppTheme.statusHigh),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: (badgeColor ?? AppTheme.statusHigh).withValues(
                        alpha: 0.2,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeText != null ? '$badgeCount $badgeText' : '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
