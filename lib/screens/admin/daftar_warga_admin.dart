import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../models/models.dart';

class DaftarWargaAdminScreen extends StatefulWidget {
  const DaftarWargaAdminScreen({Key? key}) : super(key: key);

  @override
  State<DaftarWargaAdminScreen> createState() => _DaftarWargaAdminScreenState();
}

class _DaftarWargaAdminScreenState extends State<DaftarWargaAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    final verified = state.verifiedWarga
        .where((u) =>
            _searchQuery.isEmpty ||
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    final pending = state.pendingWarga
        .where((u) =>
            _searchQuery.isEmpty ||
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Kelola Warga',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(text: 'Terverifikasi (${verified.length})'),
            Tab(text: 'Menunggu (${pending.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Cari nama warga...',
                hintStyle: TextStyle(
                    color: AppTheme.textSecondaryColor.withOpacity(0.5)),
                fillColor: AppTheme.surfaceContainerLow,
                filled: true,
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.outlineColor, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Verified warga tab
                _buildWargaList(verified, isVerified: true),
                // Pending warga tab
                _buildWargaList(pending, isVerified: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWargaList(List<AppUser> wargaList,
      {required bool isVerified}) {
    if (wargaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.people_outline : Icons.hourglass_empty,
              size: 48,
              color: AppTheme.outlineVariantColor,
            ),
            const SizedBox(height: 12),
            Text(
              isVerified
                  ? 'Belum ada warga terverifikasi'
                  : 'Tidak ada warga menunggu verifikasi',
              style: const TextStyle(
                  color: AppTheme.textSecondaryColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wargaList.length,
      itemBuilder: (context, index) {
        final warga = wargaList[index];
        return _buildWargaCard(warga, isVerified: isVerified);
      },
    );
  }

  Widget _buildWargaCard(AppUser warga, {required bool isVerified}) {
    final state = Provider.of<AppState>(context, listen: false);

    String _formatDate(DateTime? date) {
      if (date == null) return '-';
      return '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.outlineVariantColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.secondaryContainerColor,
                child: Text(
                  warga.name.isNotEmpty ? warga.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warga.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      warga.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppTheme.statusLow.withOpacity(0.1)
                      : AppTheme.statusMedium.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isVerified ? 'VERIFIED' : 'PENDING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isVerified
                        ? AppTheme.statusLow
                        : AppTheme.statusMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info rows
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildInfoRow('Kode Reg.', warga.registrationCode ?? warga.ktpNumber ?? '-'),
                const SizedBox(height: 6),
                _buildInfoRow('No. HP', warga.phone ?? '-'),
                const SizedBox(height: 6),
                _buildInfoRow('RT/RW', warga.rtRw ?? '-'),
                const SizedBox(height: 6),
                _buildInfoRow('Alamat', warga.address ?? '-'),
                const SizedBox(height: 6),
                _buildInfoRow('Terdaftar', _formatDate(warga.registeredAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          if (isVerified)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusHigh,
                  side:
                      const BorderSide(color: AppTheme.statusHigh, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  _showConfirmDialog(
                    title: 'Keluarkan Warga',
                    message:
                        'Apakah Anda yakin ingin mengeluarkan ${warga.name} dari daftar warga?',
                    onConfirm: () {
                      state.removeWarga(warga.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${warga.name} telah dikeluarkan dari daftar warga.'),
                          backgroundColor: AppTheme.statusHigh,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.person_remove, size: 16),
                label: const Text('Keluarkan Warga',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statusHigh,
                      side: const BorderSide(
                          color: AppTheme.statusHigh, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      _showConfirmDialog(
                        title: 'Tolak Warga',
                        message:
                            'Apakah Anda yakin ingin menolak pendaftaran ${warga.name}?',
                        onConfirm: () {
                          state.rejectWarga(warga.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Pendaftaran ${warga.name} telah ditolak.'),
                              backgroundColor: AppTheme.statusHigh,
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Tolak',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      state.verifyWarga(warga.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${warga.name} telah berhasil diverifikasi!'),
                          backgroundColor: AppTheme.statusLow,
                        ),
                      );
                    },
                    icon:
                        const Icon(Icons.verified_user, size: 16),
                    label: const Text('Verifikasi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        const Text(': ',
            style: TextStyle(
                fontSize: 11, color: AppTheme.textSecondaryColor)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimaryColor)),
        content: Text(message,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.secondaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text('Ya, Lanjutkan',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
