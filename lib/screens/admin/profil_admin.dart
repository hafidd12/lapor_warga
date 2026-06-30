import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/custom_image.dart';
import '../../models/models.dart';
import 'daftar_warga_admin.dart';

class ProfilAdminScreen extends StatefulWidget {
  const ProfilAdminScreen({super.key});

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
    if (pickedFile != null) {
      if (mounted) {
        final state = Provider.of<AppState>(context, listen: false);
        state.updateCurrentUser(avatarUrl: pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: AppTheme.statusLow,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Resident Directory',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user),
            const SizedBox(height: 24),

            // Info Fields Section
            _buildInfoFields(user),
            const SizedBox(height: 32),

            // Management Section
            _buildManagementSection(context, state),
            const SizedBox(height: 12),

            // Last Updated
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
    return Column(
      children: [
        // Avatar with camera icon
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
              child: CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.surfaceContainerHigh,
                backgroundImage: user?.avatarUrl != null
                    ? CustomImageProvider.get(user!.avatarUrl)
                    : null,
                child: user?.avatarUrl == null
                    ? const Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: AppTheme.primaryColor,
                      )
                    : null,
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
        // Subtitle label
        Text(
          'INFORMASI KETUA RT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
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
          onSave: (newValue) {
            Provider.of<AppState>(
              context,
              listen: false,
            ).updateCurrentUser(name: newValue);
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
          onSave: (newValue) {
            Provider.of<AppState>(
              context,
              listen: false,
            ).updateCurrentUser(phone: newValue);
          },
        ),
        const SizedBox(height: 10),

        // Password with expandable form
        _buildPasswordCard(),
      ],
    );
  }

  Widget _buildEditableCard({
    required String label,
    required String value,
    required IconData icon,
    required String fieldKey,
    required void Function(String) onSave,
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
                          onPressed: () {
                            if (_editController.text.trim().isNotEmpty) {
                              onSave(_editController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$label berhasil diperbarui.'),
                                  backgroundColor: AppTheme.statusLow,
                                ),
                              );
                            }
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
                          onPressed: () {
                            if (_newPasswordController.text !=
                                _confirmPasswordController.text) {
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
                            if (_newPasswordController.text.isNotEmpty) {
                              Provider.of<AppState>(
                                context,
                                listen: false,
                              ).updateCurrentUser(
                                password: _newPasswordController.text,
                              );
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
    final pendingCount = state.pendingWarga.length;

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

        // Persetujuan Warga Baru
        _buildManagementItem(
          icon: Icons.person_add_outlined,
          title: 'Persetujuan Warga Baru',
          badgeCount: pendingCount,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const DaftarWargaAdminScreen(initialTab: 1),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Daftar & Data Warga RT
        _buildManagementItem(
          icon: Icons.group_outlined,
          title: 'Daftar & Data Warga RT',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const DaftarWargaAdminScreen(initialTab: 0),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Kelola Kode Registrasi
        _buildManagementItem(
          icon: Icons.vpn_key_outlined,
          title: 'Kelola Kode Registrasi',
          badgeCount: state.myRegistrationCodes.where((c) => c.isActive).length,
          badgeText: 'aktif',
          badgeColor: AppTheme.primaryColor,
          onTap: () {
            _showRegistrationCodeSheet(context);
          },
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
            onPressed: () {
              state.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'Keluar Sesi',
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

  void _showRegistrationCodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RegistrationCodeBottomSheet(),
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

class _RegistrationCodeBottomSheet extends StatefulWidget {
  const _RegistrationCodeBottomSheet();

  @override
  State<_RegistrationCodeBottomSheet> createState() =>
      _RegistrationCodeBottomSheetState();
}

class _RegistrationCodeBottomSheetState
    extends State<_RegistrationCodeBottomSheet> {
  final _newCodeController = TextEditingController();
  bool _showNewCodeForm = false;

  @override
  void dispose() {
    _newCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final myCodes = state.myRegistrationCodes;
    final user = state.currentUser;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariantColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kode Registrasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Bagikan kode ini ke warga untuk mendaftar',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Code list
          Flexible(
            child: myCodes.isEmpty && !_showNewCodeForm
                ? _buildEmptyState()
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: [
                      ...myCodes.map((code) => _buildCodeCard(code, state)),
                      if (_showNewCodeForm) _buildNewCodeForm(state, user),
                    ],
                  ),
          ),

          // Bottom action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppTheme.outlineVariantColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainerColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewCodeForm = !_showNewCodeForm;
                      _newCodeController.clear();
                    });
                  },
                  icon: Icon(
                    _showNewCodeForm ? Icons.close : Icons.add_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _showNewCodeForm ? 'Batal' : 'Buat Kode Baru',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryFixed.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.vpn_key_off_rounded,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada kode registrasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Buat kode registrasi agar warga bisa mendaftar ke RT Anda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(RegistrationCode code, AppState state) {
    final isActive = code.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryFixed.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key_rounded,
                      size: 16,
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      code.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isActive
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                        decoration: isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.statusLow.withValues(alpha: 0.1)
                      : AppTheme.statusHigh.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppTheme.statusLow : AppTheme.statusHigh,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'RT/RW: ${code.rtRw}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 12,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(code.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kode "${code.code}" disalin ke clipboard',
                        ),
                        backgroundColor: AppTheme.primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text(
                    'Salin',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive
                        ? AppTheme.statusMedium
                        : AppTheme.statusLow,
                    side: BorderSide(
                      color: isActive
                          ? AppTheme.statusMedium.withValues(alpha: 0.3)
                          : AppTheme.statusLow.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    state.toggleRegistrationCodeActive(code.id);
                  },
                  icon: Icon(
                    isActive ? Icons.block : Icons.check_circle_outline,
                    size: 14,
                  ),
                  label: Text(
                    isActive ? 'Nonaktifkan' : 'Aktifkan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                width: 36,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.statusHigh.withValues(
                      alpha: 0.08,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _showDeleteConfirmation(context, state, code);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppTheme.statusHigh,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewCodeForm(AppState state, AppUser? user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryFixed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUAT KODE BARU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Masukkan kode sendiri atau generate otomatis',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _newCodeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'RT05-XXXX',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.vpn_key_outlined,
                      size: 18,
                      color: AppTheme.outlineColor,
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
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryFixed,
                    foregroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final rtRw = user?.rtRw ?? '001/001';
                    final code = state.generateRegistrationCode(rtRw);
                    _newCodeController.text = code;
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    'Generate',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusLow,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final code = _newCodeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Masukkan atau generate kode terlebih dahulu',
                      ),
                      backgroundColor: AppTheme.statusMedium,
                    ),
                  );
                  return;
                }
                final rtRw = user?.rtRw ?? '001/001';
                state.addRegistrationCode(code: code, rtRw: rtRw);
                setState(() {
                  _showNewCodeForm = false;
                  _newCodeController.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kode "$code" berhasil dibuat!'),
                    backgroundColor: AppTheme.statusLow,
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Simpan Kode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AppState state,
    RegistrationCode code,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Kode Registrasi?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Kode "${code.code}" akan dihapus permanen. Warga yang belum mendaftar dengan kode ini tidak akan bisa menggunakannya lagi.',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () {
              state.deleteRegistrationCode(code.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kode "${code.code}" dihapus'),
                  backgroundColor: AppTheme.statusHigh,
                ),
              );
            },
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
