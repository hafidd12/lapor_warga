import 'package:flutter/material.dart';
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
                onPressed: () {
                  state.logout();
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

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondaryColor),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondaryColor),
      onTap: onTap,
    );
  }
}
