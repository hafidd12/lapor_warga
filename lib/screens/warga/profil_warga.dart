import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class ProfilWargaScreen extends StatelessWidget {
  const ProfilWargaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final user = state.currentUser;

    // Count user stats
    final myReportsCount = state.reports.where((r) => r.citizenName == user?.name).length;
    final totalUpvotes = state.reports.fold<int>(0, (sum, r) => sum + (r.upvotedByUserIds.contains(user?.id) ? 1 : 0));
    final pollsVotedCount = state.polls.where((p) => p.userVotes.containsKey(user?.id)).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Profile Card Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl) : null,
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Nama Pengguna',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'warga@email.com',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Grid Card
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
                  _statItem('Laporan', myReportsCount.toString(), theme),
                  _statItem('Upvote', totalUpvotes.toString(), theme),
                  _statItem('Voting', pollsVotedCount.toString(), theme),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions Menu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _menuItem(Icons.person_outline, 'Sunting Profil', () {}, theme),
                  const Divider(height: 1),
                  _menuItem(Icons.security_outlined, 'Keamanan Akun', () {}, theme),
                  const Divider(height: 1),
                  _menuItem(Icons.help_outline, 'Syarat & Ketentuan', () {}, theme),
                  const Divider(height: 1),
                  _menuItem(Icons.phone_outlined, 'Hubungi Pengurus RT', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menghubungi Ketua RT 05: +62 812-3456-7890')),
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
                child: const Text('Keluar dari Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
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
