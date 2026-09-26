import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/mentor_card.dart';
import 'mentor_profile_screen.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';

const List<String> kSkillFilters = [
  'Python',
  'Flutter',
  'AI',
  'System Design',
  'Node.js',
  'MongoDB',
  'Kubernetes',
];

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String? _selectedSkill;

  List<AppUser> _mentors = [];
  List<AppUser> _leaderboard = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getMentors(skill: _selectedSkill, q: _searchCtrl.text.trim()),
        ApiService.getLeaderboard(limit: 10),
      ]);

      if (!mounted) return;

      setState(() {
        _mentors = results[0];
        _leaderboard = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not reach Ymentor server at ${ApiConfig.baseUrl}. Is the backend running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Ymentor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            if (user != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _roleColor(user.role).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _roleColor(user.role).withValues(alpha: 0.6)),
                ),
                child: Text(
                  user.roleBadgeLabel,
                  style: TextStyle(
                    color: _roleColor(user.role),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (auth.isLoggedIn && user != null) ...[
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              icon: const Icon(Icons.account_circle, color: AppColors.mint, size: 20),
              label: Text(
                user.name.split(' ').first,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Log In'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.mint,
          labelColor: AppColors.mint,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Discover Mentors'),
            Tab(text: 'Top 10 Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(user),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(AppUser? currentUser) {
    // If student has interests, suggest matching tags
    final studentInterests = currentUser?.skillsOrInterests ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search mentors by name, headline, skill...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),

          // Tag Chips row
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: kSkillFilters.map((skill) {
                final selected = _selectedSkill == skill;
                final isStudentTarget = studentInterests.contains(skill);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    avatar: isStudentTarget && !selected
                        ? const Icon(Icons.star, size: 14, color: AppColors.star)
                        : null,
                    label: Text(skill),
                    selected: selected,
                    selectedColor: AppColors.mint,
                    checkmarkColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.background : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedSkill = val ? skill : null);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          if (studentInterests.isNotEmpty && _selectedSkill == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.mint, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Recommended for your interests: ${studentInterests.join(', ')}',
                      style: const TextStyle(color: AppColors.mint, fontSize: 11, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Expanded(child: _buildMentorList(_mentors)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _buildMentorList(_leaderboard, showRank: true),
    );
  }

  Widget _buildMentorList(List<AppUser> mentors, {bool showRank = false}) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }

    if (mentors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            const Text('No mentors found matching your filters.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedSkill = null;
                  _searchCtrl.clear();
                });
                _load();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: mentors.length,
      itemBuilder: (context, i) {
        return MentorCard(
          mentor: mentors[i],
          rank: showRank ? i + 1 : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MentorProfileScreen(mentorId: mentors[i].id)),
          ),
        );
      },
    );
  }
}
