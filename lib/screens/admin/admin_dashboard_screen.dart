import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_logo_avatar.dart';
import '../profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data states
  List<AppUser> _pendingMentors = [];
  List<AppUser> _allUsers = [];
  Map<String, dynamic> _escrowSummary = {};
  List<dynamic> _escrowTransactions = [];
  List<dynamic> _auditLogs = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getPendingMentors(),
        ApiService.getAllUsers(),
        ApiService.getEscrowTransactions(),
        ApiService.getAuditLogs(),
      ]);

      if (!mounted) return;

      setState(() {
        _pendingMentors = results[0] as List<AppUser>;
        _allUsers = results[1] as List<AppUser>;
        final escrowData = results[2] as Map<String, dynamic>;
        _escrowSummary = escrowData['totals'] is Map
            ? escrowData['totals'] as Map<String, dynamic>
            : {};
        _escrowTransactions = escrowData['transactions'] as List? ?? [];
        _auditLogs = results[3] as List<dynamic>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveMentor(AppUser mentor) async {
    try {
      await ApiService.approveMentor(mentor.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mentor ${mentor.name} has been approved!')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    final newStatus = user.isSuspended ? 'active' : 'suspended';
    final actionWord = user.isSuspended ? 'Unban / Activate' : 'Suspend / Ban';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('$actionWord User?'),
        content: Text(
          'Are you sure you want to change ${user.name} (${user.email}) status to "$newStatus"?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user.isSuspended ? AppColors.mint : Colors.redAccent,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionWord),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.toggleUserStatus(user.id, status: newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to "$newStatus"')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status update error: ${e.toString()}')),
      );
    }
  }

  Future<void> _releaseEscrow(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Release Escrow Funds?'),
        content: const Text(
          'As an Administrator, releasing escrow will immediately credit the mentor net payout and conclude this transaction.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Release'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.releaseEscrowAdmin(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Escrow funds successfully released by administrator!')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escrow release failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoAvatar(
              size: 30,
              assetPath: 'assets/images/logo.png',
            ),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                'Admin Control Panel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.star.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.star.withValues(alpha: 0.6)),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                    color: AppColors.star,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Profile',
            icon: AppLogoAvatar(
              size: 30,
              imageUrl: auth.user?.avatarUrl,
              fallbackText: auth.user?.name.isNotEmpty == true
                  ? auth.user!.name[0].toUpperCase()
                  : 'Ym',
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.mint,
          labelColor: AppColors.mint,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Mentors & Users'),
            Tab(text: 'Escrow & Fees'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMentorsAndUsersTab(),
                    _buildEscrowTab(),
                    _buildAuditLogsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text(_error ?? 'An error occurred', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // ---------------- TAB 1: PENDING MENTORS & USER STATUS ----------------
  Widget _buildMentorsAndUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Pending Mentors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending Mentor Approvals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingMentors.length} Pending',
                  style: const TextStyle(
                      color: AppColors.star,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_pendingMentors.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.mint, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All mentor applications reviewed. No pending approvals!',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._pendingMentors.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppLogoAvatar(
                              size: 44,
                              imageUrl: m.avatarUrl,
                              fallbackText: m.name.isNotEmpty
                                  ? m.name[0].toUpperCase()
                                  : 'Ym',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text(m.email,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                  if (m.title.isNotEmpty)
                                    Text(m.title,
                                        style: const TextStyle(
                                            color: AppColors.mint,
                                            fontSize: 12)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _approveMentor(m),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        if (m.skillsOrInterests.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: m.skillsOrInterests
                                .map((s) => Chip(
                                      label: Text(s,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: AppColors.background,
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),

          const SizedBox(height: 24),

          // Section 2: All Users & Ban Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Registered Users Directory',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_allUsers.length} total',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),

          ..._allUsers.map((u) {
            final isBanned = u.isSuspended;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: AppLogoAvatar(
                  size: 44,
                  imageUrl: u.avatarUrl,
                  fallbackText:
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : 'Ym',
                  backgroundColor: isBanned
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : (u.isMentor ? AppColors.mint : AppColors.cyan)
                          .withValues(alpha: 0.2),
                  foregroundColor:
                      isBanned ? Colors.redAccent : AppColors.textPrimary,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(u.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration:
                                isBanned ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    _badgeSmall(
                        u.roleBadgeLabel,
                        u.isMentor
                            ? AppColors.mint
                            : (u.isAdmin ? AppColors.star : AppColors.cyan)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _statusDot(u.status),
                        const SizedBox(width: 4),
                        Text(u.status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isBanned
                                    ? Colors.redAccent
                                    : AppColors.verified)),
                      ],
                    ),
                  ],
                ),
                trailing: u.isAdmin
                    ? const SizedBox()
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color:
                                  isBanned ? AppColors.mint : Colors.redAccent),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _toggleUserStatus(u),
                        child: Text(
                          isBanned ? 'Unban' : 'Ban',
                          style: TextStyle(
                            color: isBanned ? AppColors.mint : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------- TAB 2: ESCROW RELEASES & FEE BREAKDOWN ----------------
  Widget _buildEscrowTab() {
    final totalGross =
        (_escrowSummary['totalGross'] as num?)?.toDouble() ?? 0.0;
    final totalFees =
        (_escrowSummary['totalPlatformFees'] as num?)?.toDouble() ?? 0.0;
    final totalHeld =
        (_escrowSummary['totalHeldInEscrow'] as num?)?.toDouble() ?? 0.0;
    final totalReleased =
        (_escrowSummary['totalReleased'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Platform Financial Summary Cards
          Row(
            children: [
              Expanded(
                  child: _metricCard('Gross Platform Volume',
                      '\$${totalGross.toStringAsFixed(2)}', AppColors.cyan)),
              const SizedBox(width: 10),
              Expanded(
                  child: _metricCard('Platform Fees (20% / \$4)',
                      '\$${totalFees.toStringAsFixed(2)}', AppColors.mint)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _metricCard('Currently in Escrow',
                      '\$${totalHeld.toStringAsFixed(2)}', AppColors.star)),
              const SizedBox(width: 10),
              Expanded(
                  child: _metricCard(
                      'Released to Mentors',
                      '\$${totalReleased.toStringAsFixed(2)}',
                      AppColors.verified)),
            ],
          ),

          const SizedBox(height: 24),
          const Text('All Escrow Bookings & Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_escrowTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No escrow transactions recorded yet.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ..._escrowTransactions.map((tx) {
              final id = tx['_id']?.toString() ?? tx['id']?.toString() ?? '-';
              final gross =
                  (tx['financials']?['grossAmount'] as num?)?.toDouble() ??
                      20.0;
              final fee = (tx['platformFee'] as num?)?.toDouble() ??
                  (tx['financials']?['platformCommission20Percent'] as num?)
                      ?.toDouble() ??
                  4.0;
              final net =
                  (tx['financials']?['mentorNetPayout80Percent'] as num?)
                          ?.toDouble() ??
                      (gross - fee);
              final escrowStatus = (tx['escrowStatus']?.toString() ??
                      tx['financials']?['escrowStatus']?.toString() ??
                      'held_in_escrow')
                  .toLowerCase();
              final isHeld =
                  escrowStatus == 'held_in_escrow' || escrowStatus == 'held';

              String menteeName = 'Mentee';
              if (tx['menteeId'] is Map) {
                menteeName = tx['menteeId']['name'] ?? 'Mentee';
              }
              String mentorName = 'Mentor';
              if (tx['mentorId'] is Map) {
                mentorName = tx['mentorId']['name'] ?? 'Mentor';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TX #$id',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  (isHeld ? AppColors.star : AppColors.verified)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: (isHeld
                                          ? AppColors.star
                                          : AppColors.verified)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              isHeld ? 'HELD IN ESCROW' : 'RELEASED',
                              style: TextStyle(
                                color: isHeld
                                    ? AppColors.star
                                    : AppColors.verified,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('$menteeName  →  $mentorName',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _feeColumn(
                              'Gross Total',
                              '\$${gross.toStringAsFixed(2)}',
                              AppColors.textPrimary),
                          _feeColumn(
                              'Platform Fee',
                              '-\$${fee.toStringAsFixed(2)}',
                              AppColors.textSecondary),
                          _feeColumn('Mentor Net Payout',
                              '\$${net.toStringAsFixed(2)}', AppColors.mint),
                        ],
                      ),
                      if (isHeld) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mint,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _releaseEscrow(id),
                            icon: const Icon(Icons.lock_open, size: 16),
                            label:
                                const Text('Release Escrow (Admin Override)'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------- TAB 3: SYSTEM AUDIT LOGS TIMELINE ----------------
  Widget _buildAuditLogsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: _auditLogs.isEmpty
          ? const Center(
              child: Text('No audit logs recorded yet.',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _auditLogs.length,
              itemBuilder: (context, i) {
                final log = _auditLogs[i];
                final action = log['action']?.toString() ?? 'SYSTEM_EVENT';
                final actorName = log['actorName']?.toString() ?? 'System';
                final actorRole = log['actorRole']?.toString() ?? 'system';
                final details = log['details'] is Map
                    ? log['details'] as Map<String, dynamic>
                    : {};
                final dateStr = log['timestamp']?.toString();
                DateTime? date;
                if (dateStr != null) date = DateTime.tryParse(dateStr);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _auditActionColor(action)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _auditActionColor(action)
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                action,
                                style: TextStyle(
                                  color: _auditActionColor(action),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (date != null)
                              Text(
                                DateFormat('MMM d, h:mm a').format(date),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Triggered by: $actorName ($actorRole)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              details.toString(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _auditActionColor(String action) {
    if (action.contains('RELEASE')) return AppColors.mint;
    if (action.contains('SUSPEND') || action.contains('BAN'))
      return Colors.redAccent;
    if (action.contains('APPROVE')) return AppColors.verified;
    if (action.contains('LOGIN')) return AppColors.cyan;
    if (action.contains('REGISTER') || action.contains('SEED'))
      return AppColors.star;
    return AppColors.mint;
  }

  Widget _metricCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _feeColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _badgeSmall(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusDot(String status) {
    final color = status.toLowerCase() == 'active'
        ? AppColors.verified
        : Colors.redAccent;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
