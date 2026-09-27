import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/mentor_card.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/common/brand_footer.dart';
import 'mentor_profile_sheet.dart';
import '../widgets/common/app_logo_avatar.dart';

const List<String> kSkillFilters = [
  'UI/UX',
  'Flutter',
  'Backend',
  'AI',
];

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String? _selectedSkill;
  final Set<String> _savedMentorIds = {};

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
        ApiService.getMentors(
            skill: _selectedSkill, q: _searchCtrl.text.trim()),
        ApiService.getLeaderboard(limit: 10),
      ]);

      if (!mounted) return;

      setState(() {
        _mentors = results[0];
        _leaderboard = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return 'Ym';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
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
            const AppLogoAvatar(size: 34, assetPath: 'assets/images/logo.png'),
            const SizedBox(width: 8),
            Text('YMentor',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold, fontSize: 22)),
            if (user != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _roleColor(user.role).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _roleColor(user.role).withValues(alpha: 0.6)),
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
              icon: AppLogoAvatar(
                size: 30,
                imageUrl: user.avatarUrl,
                fallbackText: _initials(user.name),
              ),
              label: Text(
                user.name.split(' ').first,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
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
                hintText: 'Search mentors, skills, or expertise',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
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
                        ? const Icon(Icons.star,
                            size: 14, color: AppColors.star)
                        : null,
                    label: Text(skill),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
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
                  const Icon(Icons.auto_awesome,
                      color: AppColors.mint, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Recommended for your interests: ${studentInterests.join(', ')}',
                      style: const TextStyle(
                          color: AppColors.mint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentUser == null
                        ? 'Find your next mentor'
                        : 'Good to see you, ${currentUser.name.split(' ').first}',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                ),
                Stack(
                  children: [
                    AppLogoAvatar(
                      size: 36,
                      imageUrl: currentUser?.avatarUrl,
                      fallbackText: currentUser == null
                          ? null
                          : _initials(currentUser.name),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.background, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          Icon(Icons.cloud_off,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child:
                  OutlinedButton(onPressed: _load, child: const Text('Retry'))),
          const BrandFooter(),
        ],
      );
    }

    if (mentors.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 80),
        children: [
          const Icon(Icons.search_off,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          const Center(
            child: Text('No mentors found matching your filters.',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedSkill = null;
                  _searchCtrl.clear();
                });
                _load();
              },
              child: const Text('Clear Filters'),
            ),
          ),
          const BrandFooter(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        ...mentors.asMap().entries.map((entry) {
          final mentor = entry.value;
          return MentorCard(
            mentor: mentor,
            rank: showRank ? entry.key + 1 : null,
            onTap: () => _openMentor(mentor.id),
            isSaved: _savedMentorIds.contains(mentor.id),
            onSaveChanged: (saved) => setState(() {
              if (saved) {
                _savedMentorIds.add(mentor.id);
              } else {
                _savedMentorIds.remove(mentor.id);
              }
            }),
          );
        }),
        const BrandFooter(),
      ],
    );
  }

  void _openMentor(String mentorId) {
    showMentorProfileSheet(context, mentorId);
  }
}
