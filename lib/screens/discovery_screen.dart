import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/mentor_card.dart';
import 'mentor_profile_screen.dart';
import 'auth/login_screen.dart';

const List<String> kSkillFilters = [
  'Flutter',
  'Python',
  'System Design',
  'Node.js',
  'MongoDB',
  'AI/ML',
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getMentors(skill: _selectedSkill, q: _searchCtrl.text.trim()),
        ApiService.getLeaderboard(limit: 50),
      ]);
      setState(() {
        _mentors = results[0];
        _leaderboard = results[1];
      });
    } catch (e) {
      setState(() => _error = 'Could not reach the Ymentor server. Is it running on localhost:3000?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ymentor', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!auth.isLoggedIn)
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
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
            Tab(text: 'Discover'),
            Tab(text: 'Top Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search mentors, skills, headlines...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: kSkillFilters.map((skill) {
                final selected = _selectedSkill == skill;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(skill),
                    selected: selected,
                    onSelected: (val) {
                      setState(() => _selectedSkill = val ? skill : null);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
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
          Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary.withOpacity(0.6)),
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
      return const Center(child: Text('No mentors found.', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: mentors.length,
      itemBuilder: (context, i) {
        return MentorCard(
          mentor: mentors[i],
          rank: showRank ? i + 1 : null,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => MentorProfileScreen(mentorId: mentors[i].id))),
        );
      },
    );
  }
}
