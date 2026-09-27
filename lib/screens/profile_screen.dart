import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_logo_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();
  final _meetingUrlCtrl = TextEditingController();
  final _newSkillCtrl = TextEditingController();
  List<String> _skills = [];

  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _titleCtrl.text = user.title;
      _bioCtrl.text = user.bio;
      _facultyCtrl.text = user.faculty;
      _hourlyRateCtrl.text = user.hourlyRate.toStringAsFixed(0);
      _meetingUrlCtrl.text = user.meetingUrl;
      _skills = List<String>.from(user.skillsOrInterests);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _facultyCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _meetingUrlCtrl.dispose();
    _newSkillCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final isMentor = auth.isMentor;
      final rate =
          isMentor ? double.tryParse(_hourlyRateCtrl.text.trim()) : null;

      await auth.updateProfile(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        faculty: _facultyCtrl.text.trim(),
        skillsOrInterests: _skills,
        hourlyRate: rate,
        meetingUrl: isMentor ? _meetingUrlCtrl.text.trim() : null,
      );

      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSkill() {
    final s = _newSkillCtrl.text.trim();
    if (s.isNotEmpty && !_skills.contains(s)) {
      setState(() {
        _skills.add(s);
        _newSkillCtrl.clear();
      });
    }
  }

  void _removeSkill(String s) {
    setState(() => _skills.remove(s));
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.star;
      case 'mentor':
        return AppColors.mint;
      case 'mentee':
      default:
        return AppColors.cyan;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.verified;
      case 'pending_approval':
        return AppColors.star;
      case 'suspended':
        return Colors.redAccent;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Not logged in.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          if (!_editing)
            IconButton(
              tooltip: 'Edit Profile',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            )
          else
            IconButton(
              tooltip: 'Cancel Editing',
              icon: const Icon(Icons.close),
              onPressed: () {
                _hydrate();
                setState(() => _editing = false);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar and Identity Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppLogoAvatar(
                      size: 84,
                      imageUrl: user.avatarUrl,
                      fallbackText: _getInitials(user.name),
                      backgroundColor:
                          _roleColor(user.role).withValues(alpha: 0.2),
                      foregroundColor: _roleColor(user.role),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Badges Row: Role Badge & Status Badge
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _badge(
                          label: user.roleBadgeLabel,
                          color: _roleColor(user.role),
                        ),
                        _badge(
                          label: user.statusBadgeLabel,
                          color: _statusColor(user.status),
                        ),
                        if (user.isSkillVerified)
                          _badge(
                            label: '[VERIFIED EXPERT]',
                            color: AppColors.verified,
                          ),
                      ],
                    ),

                    if (user.title.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        user.title,
                        style: const TextStyle(
                            color: AppColors.mint, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const Divider(height: 28, color: AppColors.border),

                    // Wallet & Escrow Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat(
                            'Wallet Balance',
                            '\$${user.walletBalance.toStringAsFixed(2)}',
                            AppColors.mint),
                        if (user.isMentor)
                          _stat(
                              'Pending Escrow',
                              '\$${user.pendingEscrow.toStringAsFixed(2)}',
                              AppColors.star)
                        else
                          _stat('Sessions Completed', '${user.totalSessions}',
                              AppColors.cyan),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Details Section (Editable)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personal & Academic Info',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (_editing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.mint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Editing',
                                style: TextStyle(
                                    color: AppColors.mint, fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_editing) ...[
                      TextField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Full Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Professional Title / Academic Degree'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _facultyCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Faculty / Department'),
                      ),
                      const SizedBox(height: 12),
                      if (user.isMentor) ...[
                        TextField(
                          controller: _hourlyRateCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Hourly Rate (USD \$)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _meetingUrlCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Video Meeting Link'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _bioCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Bio & Experience'),
                        maxLines: 3,
                      ),
                    ] else ...[
                      _infoRow(
                          'Faculty / Department',
                          user.faculty.isNotEmpty
                              ? user.faculty
                              : 'Not specified'),
                      const SizedBox(height: 10),
                      _infoRow('Title / Role',
                          user.title.isNotEmpty ? user.title : 'Not specified'),
                      const SizedBox(height: 10),
                      if (user.isMentor) ...[
                        _infoRow('Base Hourly Rate',
                            '\$${user.hourlyRate.toStringAsFixed(2)}/hr'),
                        const SizedBox(height: 10),
                        _infoRow('Meeting Link', user.meetingUrl),
                        const SizedBox(height: 10),
                      ],
                      _infoRow('Bio',
                          user.bio.isNotEmpty ? user.bio : 'No bio added yet.'),
                    ],
                    const SizedBox(height: 18),
                    const Text('Skills & Learning Interests',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.map((s) {
                        return Chip(
                          label: Text(s),
                          backgroundColor: AppColors.background,
                          deleteIcon: _editing
                              ? const Icon(Icons.close, size: 16)
                              : null,
                          onDeleted: _editing ? () => _removeSkill(s) : null,
                        );
                      }).toList(),
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newSkillCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Add skill tag (e.g. Flutter, AI)...',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                              ),
                              onSubmitted: (_) => _addSkill(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addSkill,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13)),
                    ],
                    if (_editing) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Changes'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Explicit Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Log Out'),
                    content: const Text(
                        'Are you sure you want to log out of Ymentor?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Log Out',
                  style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _badge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
