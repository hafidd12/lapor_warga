import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'warga_verification_detail_screen.dart';

class DaftarWargaAdminScreen extends StatefulWidget {
  const DaftarWargaAdminScreen({Key? key}) : super(key: key);

  @override
  State<DaftarWargaAdminScreen> createState() => _DaftarWargaAdminScreenState();
}

class _DaftarWargaAdminScreenState extends State<DaftarWargaAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await context.read<AppState>().refreshVerificationUsers();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  bool _matchesSearch(AppUser user) {
    if (_searchQuery.trim().isEmpty) return true;
    final query = _searchQuery.toLowerCase().trim();
    return [
      user.name,
      user.email,
      user.registrationCode,
      user.rtRw,
      user.ktpNumber,
    ].whereType<String>().any((value) => value.toLowerCase().contains(query));
  }

  Color _statusColor(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => AppTheme.statusMedium,
      VerificationStatus.verified => AppTheme.primaryColor,
      VerificationStatus.rejected => AppTheme.statusHigh,
    };
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final d = dateTime;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _openDetail(AppUser user) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WargaVerificationDetailScreen(userId: user.id),
      ),
    );

    if (changed == true) {
      await _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.pendingWarga.where(_matchesSearch).toList();
    final verified = state.verifiedWarga.where(_matchesSearch).toList();
    final rejected = state.rejectedWarga.where(_matchesSearch).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Verifikasi Warga',
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
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Disetujui (${verified.length})'),
            Tab(text: 'Ditolak (${rejected.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, email, KTP, atau RT/RW',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondaryColor.withOpacity(0.55),
                      ),
                      fillColor: AppTheme.surfaceContainerLow,
                      filled: true,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.outlineColor,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SummaryChip(
                        label: 'Pending',
                        value: pending.length.toString(),
                        color: AppTheme.statusMedium,
                      ),
                      const SizedBox(width: 10),
                      _SummaryChip(
                        label: 'Disetujui',
                        value: verified.length.toString(),
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      _SummaryChip(
                        label: 'Ditolak',
                        value: rejected.length.toString(),
                        color: AppTheme.statusHigh,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isRefreshing)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _WargaListTab(
                    title: 'Tidak ada warga pending',
                    subtitle:
                        'Semua pendaftar sudah diproses atau belum ada data baru.',
                    icon: Icons.hourglass_top_rounded,
                    items: pending,
                    statusLabel: VerificationStatus.pending,
                    statusColor: _statusColor(VerificationStatus.pending),
                    formatDate: _formatDate,
                    onTap: _openDetail,
                  ),
                  _WargaListTab(
                    title: 'Belum ada warga disetujui',
                    subtitle:
                        'Warga yang telah diverifikasi RT/Admin akan tampil di sini.',
                    icon: Icons.verified_rounded,
                    items: verified,
                    statusLabel: VerificationStatus.verified,
                    statusColor: _statusColor(VerificationStatus.verified),
                    formatDate: _formatDate,
                    onTap: _openDetail,
                  ),
                  _WargaListTab(
                    title: 'Belum ada warga ditolak',
                    subtitle:
                        'Warga yang ditolak verifikasinya akan tampil di sini.',
                    icon: Icons.block_rounded,
                    items: rejected,
                    statusLabel: VerificationStatus.rejected,
                    statusColor: _statusColor(VerificationStatus.rejected),
                    formatDate: _formatDate,
                    onTap: _openDetail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WargaListTab extends StatelessWidget {
  const _WargaListTab({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.statusLabel,
    required this.statusColor,
    required this.formatDate,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<AppUser> items;
  final VerificationStatus statusLabel;
  final Color statusColor;
  final String Function(DateTime?) formatDate;
  final Future<void> Function(AppUser user) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          _EmptyState(icon: icon, title: title, subtitle: subtitle),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = items[index];
        return _WargaCard(
          user: user,
          statusColor: statusColor,
          statusText: _statusText(statusLabel),
          formatDate: formatDate,
          onTap: () => onTap(user),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }

  String _statusText(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'PENDING',
      VerificationStatus.verified => 'APPROVED',
      VerificationStatus.rejected => 'REJECTED',
    };
  }
}

class _WargaCard extends StatelessWidget {
  const _WargaCard({
    required this.user,
    required this.statusColor,
    required this.statusText,
    required this.formatDate,
    required this.onTap,
  });

  final AppUser user;
  final Color statusColor;
  final String statusText;
  final String Function(DateTime?) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withOpacity(0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                          user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(label: 'Kode', value: user.registrationCode ?? '-'),
              const SizedBox(height: 6),
              _InfoRow(label: 'RT/RW', value: user.rtRw ?? '-'),
              const SizedBox(height: 6),
              _InfoRow(label: 'KTP', value: user.ktpNumber ?? '-'),
              const SizedBox(height: 6),
              _InfoRow(label: 'Terdaftar', value: formatDate(user.registeredAt)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(': ',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
            )),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.outlineVariantColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.circle, color: color, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariantColor.withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
