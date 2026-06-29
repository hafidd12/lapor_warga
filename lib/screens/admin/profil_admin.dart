import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';

class ProfilAdminScreen extends StatelessWidget {
  const ProfilAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final user = state.currentUser;

    // Stats
    final totalResolved = state.reports.where((r) => r.status == ReportStatus.resolved).length;
    final totalPending = state.reports.where((r) => r.status == ReportStatus.submitted).length;
    final totalProcessed = state.reports.where((r) => r.status == ReportStatus.processed).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Admin'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar and name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl) : null,
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.admin_panel_settings, size: 50, color: AppTheme.primaryColor)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Admin Lapor Warga',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'admin@email.com',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats row
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Masuk', totalPending.toString(), AppTheme.statusMedium, theme),
                  _statItem('Proses', totalProcessed.toString(), Colors.indigo, theme),
                  _statItem('Selesai', totalResolved.toString(), AppTheme.statusLow, theme),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Admin features list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _menuItem(Icons.vpn_key_outlined, 'Kelola Kode Registrasi', () {
                    _showRegistrationCodeSheet(context);
                  }, theme, badge: state.myRegistrationCodes.where((c) => c.isActive).length),
                  const Divider(height: 1),
                  _menuItem(Icons.people_outline, 'Daftar Warga Terdaftar', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menampilkan data warga: 48 warga terdaftar.')),
                    );
                  }, theme),
                  const Divider(height: 1),
                  _menuItem(Icons.settings_outlined, 'Pengaturan Sistem RT', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pengaturan batas wilayah: RT 05 / RW 02.')),
                    );
                  }, theme),
                  const Divider(height: 1),
                  _menuItem(Icons.analytics_outlined, 'Unduh Laporan Bulanan (PDF)', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mengekspor laporan bulanan... PDF berhasil diunduh.')),
                    );
                  }, theme),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await state.logoutFromSupabase();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Keluar Sebagai Admin', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
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

  Widget _statItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, ThemeData theme, {int? badge}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondaryColor),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null && badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge aktif',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondaryColor),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RegistrationCodeBottomSheet extends StatefulWidget {
  const _RegistrationCodeBottomSheet();

  @override
  State<_RegistrationCodeBottomSheet> createState() => _RegistrationCodeBottomSheetState();
}

class _RegistrationCodeBottomSheetState extends State<_RegistrationCodeBottomSheet> {
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
                    color: AppTheme.primaryFixed.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryColor, size: 22),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                top: BorderSide(color: AppTheme.outlineVariantColor.withOpacity(0.5)),
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
                  icon: Icon(_showNewCodeForm ? Icons.close : Icons.add_rounded, size: 20),
                  label: Text(
                    _showNewCodeForm ? 'Batal' : 'Buat Kode Baru',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              color: AppTheme.primaryFixed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key_off_rounded, size: 40, color: AppTheme.primaryColor),
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
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
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
            ? AppTheme.primaryFixed.withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Code display
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key_rounded,
                      size: 16,
                      color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      code.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                        decoration: isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.statusLow.withOpacity(0.1)
                      : AppTheme.statusHigh.withOpacity(0.1),
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
              Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                'RT/RW: ${code.rtRw}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 12, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                _formatDate(code.createdAt),
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Copy button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kode "${code.code}" disalin ke clipboard'),
                        backgroundColor: AppTheme.primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Salin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              // Toggle active/inactive
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? AppTheme.statusMedium : AppTheme.statusLow,
                    side: BorderSide(
                      color: isActive
                          ? AppTheme.statusMedium.withOpacity(0.3)
                          : AppTheme.statusLow.withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    state.toggleRegistrationCodeActive(code.id);
                  },
                  icon: Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 14),
                  label: Text(
                    isActive ? 'Nonaktifkan' : 'Aktifkan',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              SizedBox(
                height: 36,
                width: 36,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.statusHigh.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _showDeleteConfirmation(context, state, code);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.statusHigh),
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
        color: AppTheme.primaryFixed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
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
                    hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.4)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.outlineColor),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.outlineVariantColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final rtRw = user?.rtRw ?? '001/001';
                    final code = state.generateRegistrationCode(rtRw);
                    _newCodeController.text = code;
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final code = _newCodeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan atau generate kode terlebih dahulu'),
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
              label: const Text('Simpan Kode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppState state, RegistrationCode code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kode Registrasi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Kode "${code.code}" akan dihapus permanen. Warga yang belum mendaftar dengan kode ini tidak akan bisa menggunakannya lagi.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
