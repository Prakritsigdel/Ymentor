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
import '../widgets/common/app_logo_widget.dart';

const List<String> kSkillFilters = [
  'UI/UX',
  'Flutter',
  'Backend',
  'AI',
];

class DiscoveryScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const DiscoveryScreen({super.key, this.onProfileTap});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String? _selectedSkill;
  String? _selectedPlanFilter;
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
            const AppLogoWidget(height: 34),
            const SizedBox(width: 8),
            Text('Ymentor',
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
              onPressed: widget.onProfileTap ??
                  () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
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
    final studentInterests = currentUser?.skillsOrInterests ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _DiscoveryHeader(
              controller: _searchCtrl,
              currentUser: currentUser,
              studentInterests: studentInterests,
              selectedSkill: _selectedSkill,
              selectedPlanFilter: _selectedPlanFilter,
              initials: _initials,
              onSearch: _load,
              onClearSearch: () {
                _searchCtrl.clear();
                _load();
              },
              onSkillChanged: (skill) {
                setState(() => _selectedSkill = skill);
                _load();
              },
              onPlanChanged: (plan) =>
                  setState(() => _selectedPlanFilter = plan),
            ),
          ),
          ..._mentorSlivers(_mentors),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _mentorSlivers(_leaderboard, showRank: true),
      ),
    );
  }

  List<Widget> _mentorSlivers(List<AppUser> mentors, {bool showRank = false}) {
    if (_loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _DiscoveryMessage(
            icon: Icons.cloud_off,
            message: _error!,
            actionLabel: 'Retry',
            onAction: _load,
          ),
        ),
      ];
    }

    final filteredMentors = mentors.where((mentor) {
      if (_selectedPlanFilter == 'Offers Monthly Plans') {
        return ((mentor.mentorProfile['monthlyRate'] as num?)?.toDouble() ??
                0) >
            0;
      }
      if (_selectedPlanFilter == 'Hourly Micro-Sessions')
        return mentor.hourlyRate > 0;
      return true;
    }).toList();

    if (filteredMentors.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _DiscoveryMessage(
            icon: Icons.search_off,
            message: 'No mentors found matching your filters.',
            actionLabel: 'Clear Filters',
            onAction: () {
              setState(() {
                _selectedSkill = null;
                _selectedPlanFilter = null;
                _searchCtrl.clear();
              });
              _load();
            },
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final mentor = filteredMentors[index];
              return MentorCard(
                mentor: mentor,
                rank: showRank ? index + 1 : null,
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
            },
            childCount: filteredMentors.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: BrandFooter()),
    ];
  }

  void _openMentor(String mentorId) {
    showMentorProfileSheet(context, mentorId);
  }
}

class _DiscoveryHeader extends StatelessWidget {
  final TextEditingController controller;
  final AppUser? currentUser;
  final List<String> studentInterests;
  final String? selectedSkill;
  final String? selectedPlanFilter;
  final String Function(String) initials;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onSkillChanged;
  final ValueChanged<String?> onPlanChanged;

  const _DiscoveryHeader({
    required this.controller,
    required this.currentUser,
    required this.studentInterests,
    required this.selectedSkill,
    required this.selectedPlanFilter,
    required this.initials,
    required this.onSearch,
    required this.onClearSearch,
    required this.onSkillChanged,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search mentors, skills, or expertise',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            _FilterRow(
              values: kSkillFilters,
              selected: selectedSkill,
              leadingStarValues: studentInterests,
              onChanged: onSkillChanged,
            ),
            _FilterRow(
              values: const ['Offers Monthly Plans', 'Hourly Micro-Sessions'],
              selected: selectedPlanFilter,
              onChanged: onPlanChanged,
            ),
            if (studentInterests.isNotEmpty && selectedSkill == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.mint, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Recommended for your interests: ${studentInterests.join(', ')}',
                        style: const TextStyle(
                            color: AppColors.mint,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      currentUser == null
                          ? 'Find your next mentor'
                          : 'Good to see you, ${currentUser!.name.split(' ').first}',
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w700),
                    ),
                  ),
                  AppLogoAvatar(
                    size: 36,
                    imageUrl: currentUser?.avatarUrl,
                    fallbackText: currentUser == null
                        ? null
                        : initials(currentUser!.name),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FilterRow extends StatelessWidget {
  final List<String> values;
  final List<String> leadingStarValues;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterRow({
    required this.values,
    this.leadingStarValues = const [],
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: values
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    avatar:
                        leadingStarValues.contains(value) && selected != value
                            ? const Icon(Icons.star,
                                size: 14, color: AppColors.star)
                            : null,
                    label: Text(value),
                    selected: selected == value,
                    selectedColor: AppColors.primary,
                    onSelected: (isSelected) =>
                        onChanged(isSelected ? value : null),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

class _DiscoveryMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _DiscoveryMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          const BrandFooter(),
        ],
      );
}
