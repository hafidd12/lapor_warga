import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'warga_verification_detail_screen.dart';

class DaftarWargaAdminScreen extends StatefulWidget {
  final int initialTab;

  const DaftarWargaAdminScreen({super.key, this.initialTab = 0});

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
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2).toInt(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void didUpdateWidget(covariant DaftarWargaAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 2).toInt());
    }
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
    debugPrint(
      '[DaftarWargaAdminScreen] UI data currentUser.rtRw=${state.currentUser?.rtRw ?? "null"} pending=${pending.length} verified=${verified.length} rejected=${rejected.length} pendingRtRws=${pending.map((u) => u.rtRw ?? "-").toList()} verifiedRtRws=${verified.map((u) => u.rtRw ?? "-").toList()} rejectedRtRws=${rejected.map((u) => u.rtRw ?? "-").toList()}',
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        toolbarHeight: 78,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const _AdminHeaderTitle(
          title: 'Verifikasi Warga',
          subtitle: 'Kelola verifikasi akun warga',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'Disetujui (${verified.length})'),
                Tab(text: 'Ditolak (${rejected.length})'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outlineVariantColor.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, email, KTP, atau RT/RW',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondaryColor.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.outlineColor,
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.clear, size: 18),
                                splashRadius: 18,
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
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

class _AdminHeaderTitle extends StatelessWidget {
  const _AdminHeaderTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.secondaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
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
          const SizedBox(height: 48),
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
          statusLabel: statusLabel,
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
    required this.statusLabel,
    required this.statusColor,
    required this.statusText,
    required this.formatDate,
    required this.onTap,
  });

  final AppUser user;
  final VerificationStatus statusLabel;
  final Color statusColor;
  final String statusText;
  final String Function(DateTime?) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = switch (statusLabel) {
      VerificationStatus.pending => 'Pending',
      VerificationStatus.verified => 'Disetujui',
      VerificationStatus.rejected => 'Ditolak',
    };
    final badgeTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: statusColor,
      fontWeight: FontWeight.bold,
      fontSize: 10,
      letterSpacing: 0.2,
    );
    final ktpValue = _maskKtpNumber(user.ktpNumber);
    final codeLabel = 'Kode Warga';
    final ktpLabel = 'Nomor KTP';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                    radius: 23,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondaryColor,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(badgeText, style: badgeTextStyle),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(label: codeLabel, value: user.registrationCode ?? '-'),
              const SizedBox(height: 8),
              _InfoRow(label: 'RT/RW', value: user.rtRw ?? '-'),
              const SizedBox(height: 8),
              _InfoRow(label: ktpLabel, value: ktpValue),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Terdaftar',
                value: formatDate(user.registeredAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskKtpNumber(String? value) {
    final raw = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (raw.isEmpty) return '-';
    if (raw.length <= 4) return '****';
    if (raw.length <= 8) {
      return '${raw.substring(0, 2)}****${raw.substring(raw.length - 2)}';
    }
    return '${raw.substring(0, 4)} **** **** ${raw.substring(raw.length - 4)}';
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
              fontSize: 11.5,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(22),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
