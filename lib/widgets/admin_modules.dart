import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';

List<dynamic> _listOf(dynamic response) => response is List
    ? response
    : response is Map
        ? (response['data'] as List? ?? [])
        : [];

String _idOf(dynamic value) =>
    value is Map ? (value['_id'] ?? value['id'] ?? '').toString() : '';

class AdminKycModule extends StatefulWidget {
  const AdminKycModule({super.key});

  @override
  State<AdminKycModule> createState() => _AdminKycModuleState();
}

class _AdminKycModuleState extends State<AdminKycModule> {
  late Future<dynamic> _queue;

  @override
  void initState() {
    super.initState();
    _queue = ApiService.adminGet('kyc');
  }

  void _reload() => setState(() => _queue = ApiService.adminGet('kyc'));

  Future<void> _decide(Map<String, dynamic> user, String decision) async {
    var reason = '';
    if (decision == 'REJECTED') {
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Reason for rejection'),
            content: TextField(controller: controller, maxLines: 3),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Reject')),
            ],
          );
        },
      );
      if (result == null || result.isEmpty) return;
      reason = result;
    }
    await ApiService.adminPut(
        'kyc/${_idOf(user)}', {'decision': decision, 'reason': reason});
    if (mounted) _reload();
  }

  Future<void> _openDocument(String path) async {
    final uri = Uri.tryParse(
        path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _queue,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: TextButton(
                    onPressed: _reload,
                    child: const Text('Could not load KYC queue · Retry')));
          }
          final users = _listOf(snapshot.data);
          if (users.isEmpty)
            return const Center(
                child: Text('No mentor applications awaiting review.'));
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: users.whereType<Map>().map((raw) {
                final user = Map<String, dynamic>.from(raw);
                final profile = user['mentorProfile'] is Map
                    ? Map<String, dynamic>.from(user['mentorProfile'] as Map)
                    : <String, dynamic>{};
                final identityDocs =
                    (profile['identityDocUrl']?.toString() ?? '').split('|');
                final docs = [
                  (
                    'Qualification proof',
                    profile['qualificationDocUrl']?.toString() ?? ''
                  ),
                  (
                    'Government ID · front',
                    identityDocs.isNotEmpty ? identityDocs.first : ''
                  ),
                  (
                    'Government ID · back',
                    identityDocs.length > 1 ? identityDocs[1] : ''
                  ),
                ];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(user['name']?.toString() ?? 'Mentor',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                            '${user['email'] ?? ''} · ${user['headline'] ?? ''}'),
                        const Divider(),
                        Wrap(
                          spacing: 8,
                          children: docs
                              .where((item) => item.$2.isNotEmpty)
                              .map((item) => OutlinedButton.icon(
                                    onPressed: () =>
                                        _openDocument(item.$2.split('|').first),
                                    icon:
                                        const Icon(Icons.description_outlined),
                                    label: Text(item.$1),
                                  ))
                              .toList(),
                        ),
                        Row(children: [
                          Expanded(
                              child: FilledButton(
                                  onPressed: () => _decide(user, 'APPROVED'),
                                  child: const Text('Approve'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => _decide(user, 'REJECTED'),
                                  child: const Text('Reject'))),
                        ]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
}

class AdminLedgerModule extends StatefulWidget {
  const AdminLedgerModule({super.key});

  @override
  State<AdminLedgerModule> createState() => _AdminLedgerModuleState();
}

class _AdminLedgerModuleState extends State<AdminLedgerModule> {
  late Future<Map<String, dynamic>> _ledger;

  @override
  void initState() {
    super.initState();
    _ledger = ApiService.getEscrowTransactions();
  }

  void _reload() =>
      setState(() => _ledger = ApiService.getEscrowTransactions());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _ledger,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: TextButton(
                    onPressed: _reload,
                    child: const Text('Could not load ledger · Retry')));
          final data = snapshot.data!;
          final totals = data['totals'] is Map
              ? Map<String, dynamic>.from(data['totals'] as Map)
              : <String, dynamic>{};
          final transactions = data['transactions'] as List? ?? [];
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 10,
                  children: [
                    _Metric(
                        label: 'GMV',
                        value: totals['totalGross'],
                        currency: true),
                    _Metric(
                        label: 'Fees',
                        value: totals['totalPlatformFees'],
                        currency: true),
                    _Metric(
                        label: 'Held',
                        value: totals['totalHeldInEscrow'],
                        currency: true),
                    _Metric(
                        label: 'Released',
                        value: totals['totalReleased'],
                        currency: true),
                  ],
                ),
                ...transactions.whereType<Map>().map((item) {
                  final id = _idOf(item);
                  final financials = item['financials'] is Map
                      ? item['financials'] as Map
                      : const {};
                  final held = item['escrowStatus'] == 'held_in_escrow';
                  return Card(
                    child: ListTile(
                      title: Text(
                          '${item['planType'] ?? 'hourly'} · ${CurrencyUtils.formatNPR((financials['grossAmount'] ?? 0) as num)}'),
                      subtitle: Text(
                          'Platform ${CurrencyUtils.formatNPR((item['platformFee'] ?? 0) as num)} · payout ${CurrencyUtils.formatNPR((financials['mentorNetPayout80Percent'] ?? 0) as num)} · ${item['escrowStatus'] ?? ''}'),
                      trailing: held
                          ? IconButton(
                              tooltip: 'Release payout',
                              icon: const Icon(Icons.lock_open,
                                  color: AppColors.mint),
                              onPressed: () async {
                                await ApiService.releaseEscrowAdmin(id);
                                if (mounted) _reload();
                              },
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
}

class AdminDisputesModule extends StatefulWidget {
  const AdminDisputesModule({super.key});

  @override
  State<AdminDisputesModule> createState() => _AdminDisputesModuleState();
}

class _AdminDisputesModuleState extends State<AdminDisputesModule> {
  late Future<dynamic> _disputes;

  @override
  void initState() {
    super.initState();
    _disputes = ApiService.adminGet('disputes');
  }

  void _reload() => setState(() => _disputes = ApiService.adminGet('disputes'));

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _disputes,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: TextButton(
                    onPressed: _reload,
                    child: const Text('Could not load disputes · Retry')));
          final items = _listOf(snapshot.data);
          if (items.isEmpty)
            return const Center(child: Text('No open disputes.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.whereType<Map>().map((raw) {
              final item = Map<String, dynamic>.from(raw);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(item['reason']?.toString() ?? 'Issue reported'),
                      Text('Booking ${item['bookingId'] ?? ''}',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final choice in [
                            ('Refund Mentee', 'refund_mentee'),
                            ('Release to Mentor', 'release_mentor'),
                            ('Split 50/50', 'split')
                          ])
                            TextButton(
                              onPressed: () async {
                                await ApiService.adminPut(
                                    'disputes/${_idOf(item)}/resolve',
                                    {'resolution': choice.$2});
                                if (mounted) _reload();
                              },
                              child: Text(choice.$1),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
}

class AdminUsersModule extends StatefulWidget {
  const AdminUsersModule({super.key});

  @override
  State<AdminUsersModule> createState() => _AdminUsersModuleState();
}

class _AdminUsersModuleState extends State<AdminUsersModule> {
  final _search = TextEditingController();
  late Future<List<AppUser>> _users;

  @override
  void initState() {
    super.initState();
    _users = ApiService.getAllUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _users = ApiService.getAllUsers());

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AppUser>>(
        future: _users,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: TextButton(
                    onPressed: _reload,
                    child: const Text('Could not load users · Retry')));
          final query = _search.text.toLowerCase();
          final users = snapshot.data!.where((user) =>
              '${user.name} ${user.email} ${user.role}'
                  .toLowerCase()
                  .contains(query));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search users')),
              ),
              Expanded(
                child: ListView(
                  children: users
                      .map((user) => SwitchListTile(
                            title: Text(user.name),
                            subtitle: Text(
                                '${user.roleDisplayName} · ${user.email} · ${user.status}'),
                            value: !user.isSuspended,
                            onChanged: user.isAdmin || user.isPendingApproval
                                ? null
                                : (active) async {
                                    await ApiService.toggleUserStatus(user.id,
                                        status:
                                            active ? 'active' : 'suspended');
                                    if (mounted) _reload();
                                  },
                          ))
                      .toList(),
                ),
              ),
            ],
          );
        },
      );
}

class AdminReviewsModule extends StatefulWidget {
  const AdminReviewsModule({super.key});

  @override
  State<AdminReviewsModule> createState() => _AdminReviewsModuleState();
}

class _AdminReviewsModuleState extends State<AdminReviewsModule> {
  late Future<dynamic> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = ApiService.adminGet('reviews');
  }

  void _reload() => setState(() => _reviews = ApiService.adminGet('reviews'));

  Future<void> _edit(Map<String, dynamic> review) async {
    final controller =
        TextEditingController(text: review['text']?.toString() ?? '');
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit review'),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save edit')),
        ],
      ),
    );
    controller.dispose();
    if (edited == null) return;
    await ApiService.adminPut(
        'reviews/${_idOf(review)}', {'status': 'pending', 'text': edited});
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _reviews,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: TextButton(
                    onPressed: _reload,
                    child: const Text('Could not load reviews · Retry')));
          final reviews = _listOf(snapshot.data);
          if (reviews.isEmpty)
            return const Center(
                child: Text('No reviews are awaiting moderation.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: reviews.whereType<Map>().map((raw) {
              final review = Map<String, dynamic>.from(raw);
              return Card(
                child: ListTile(
                  title: Text(
                      '${review['rating'] ?? 0} stars · ${review['text'] ?? ''}'),
                  subtitle: Text('Review ${_idOf(review)}'),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(review),
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(Icons.check_circle,
                            color: AppColors.mint),
                        onPressed: () async {
                          await ApiService.adminPut('reviews/${_idOf(review)}',
                              {'status': 'approved'});
                          if (mounted) _reload();
                        },
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.terracotta),
                        onPressed: () async {
                          await ApiService.adminPut('reviews/${_idOf(review)}',
                              {'status': 'removed'});
                          if (mounted) _reload();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
}

class AdminAnalyticsModule extends StatefulWidget {
  const AdminAnalyticsModule({super.key});

  @override
  State<AdminAnalyticsModule> createState() => _AdminAnalyticsModuleState();
}

class _AdminAnalyticsModuleState extends State<AdminAnalyticsModule> {
  late Future<dynamic> _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = ApiService.adminGet('analytics');
  }

  void _reload() =>
      setState(() => _analytics = ApiService.adminGet('analytics'));

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _analytics,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: TextButton(
                    onPressed: _reload,
                    child: const Text('Could not load analytics · Retry')));
          final result = snapshot.data is Map
              ? Map<String, dynamic>.from(snapshot.data as Map)
              : <String, dynamic>{};
          final skills = result['topSkills'] as List? ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Metric(label: 'Daily active users', value: result['dau']),
              _Metric(
                  label: 'Registrations · 30 days',
                  value: result['registrationsLast30Days']),
              _Metric(
                  label: 'Active bookings', value: result['activeBookings']),
              const SizedBox(height: 12),
              const Text('Top searched skills',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...skills.map((skill) => ListTile(
                  title: Text(skill is Map ? '${skill['_id']}' : '$skill'),
                  trailing: Text(skill is Map ? '${skill['count']}' : ''))),
            ],
          );
        },
      );
}

class AdminSystemModule extends StatefulWidget {
  const AdminSystemModule({super.key});

  @override
  State<AdminSystemModule> createState() => _AdminSystemModuleState();
}

class _AdminSystemModuleState extends State<AdminSystemModule> {
  final _flatFee = TextEditingController(text: '0');
  final _percentage = TextEditingController(text: '0');
  final _message = TextEditingController();
  late Future<dynamic> _config;
  String _segment = 'all';

  @override
  void initState() {
    super.initState();
    _config = ApiService.adminGet('config');
  }

  @override
  void dispose() {
    _flatFee.dispose();
    _percentage.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _config,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
                child: Text('Could not load platform settings.'));
          if (snapshot.hasData && !_initialized) {
            final config = snapshot.data is Map
                ? Map<String, dynamic>.from(snapshot.data as Map)
                : <String, dynamic>{};
            _flatFee.text = '${config['flatFee'] ?? 0}';
            _percentage.text = '${config['percentageFee'] ?? 0}';
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Platform fee policy',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _flatFee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Flat fee (NPR)',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _percentage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Percentage fee (0 to disable)',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        await ApiService.adminPut('config', {
                          'flatFee': int.tryParse(_flatFee.text) ?? -1,
                          'percentageFee': int.tryParse(_percentage.text) ?? -1,
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Fee settings saved.')));
                        }
                      },
                      child: const Text('Save fee settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Broadcast center',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 58,
                      child: DropdownButtonFormField<String>(
                        initialValue: _segment,
                        decoration: const InputDecoration(
                          labelText: 'Recipient segment',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        items: const ['all', 'mentees', 'mentors']
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _segment = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _message,
                      minLines: 4,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        await ApiService.adminPost('broadcasts',
                            {'message': _message.text, 'segment': _segment});
                        if (mounted) {
                          _message.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Broadcast saved.')));
                        }
                      },
                      child: const Text('Save broadcast'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
  bool _initialized = false;
}

class _Metric extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool currency;
  const _Metric(
      {required this.label, required this.value, this.currency = false});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                  value is num && currency
                      ? CurrencyUtils.formatNPR(value as num)
                      : '${value ?? 0}',
                  style: const TextStyle(
                      color: AppColors.mint, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
