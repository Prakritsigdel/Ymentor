import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'checkout_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/common/app_logo_avatar.dart';

class MentorProfileScreen extends StatefulWidget {
  final String mentorId;
  const MentorProfileScreen({super.key, required this.mentorId});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  AppUser? _mentor;
  List<dynamic> _slots = [];
  bool _loading = true;
  int _selectedDuration = 30; // 30, 60, 120
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMentorProfile(widget.mentorId);
      setState(() {
        _mentor = AppUser.fromJson(data['mentor']);
        _slots = data['availableSlots'] ?? [];
      });
    } catch (_) {
      // ignore, handled by null check in build
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _slotsNeeded => _selectedDuration ~/ 30;

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onBookCall() async {
    final mentor = _mentor;
    if (mentor == null) return;
    final price = mentor.pricingTiers.priceFor(_selectedDuration);
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      await auth.savePendingBooking(PendingBooking(
        mentorId: mentor.id,
        durationMinutes: _selectedDuration,
        price: price,
        slotId: _selectedSlotId,
      ));
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckoutScreen(
          mentorId: mentor.id,
          durationMinutes: _selectedDuration,
          price: price),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mentor = _mentor;
    if (mentor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
            child: Text('Mentor not found.',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final headlineDisplay = mentor.headline.isNotEmpty
        ? mentor.headline
        : (mentor.title.isNotEmpty ? mentor.title : mentor.faculty);

    final allSkills = mentor.skillsOrInterests.isNotEmpty
        ? mentor.skillsOrInterests
        : mentor.qualifications.skills;

    return Scaffold(
      appBar: AppBar(
        title: Text(mentor.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (mentor.isIdentityVerified || mentor.isSkillVerified)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.verified, color: AppColors.mint),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              AppLogoAvatar(
                size: 72,
                imageUrl: mentor.avatarUrl,
                fallbackText:
                    mentor.name.isEmpty ? 'Ym' : mentor.name[0].toUpperCase(),
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(mentor.name,
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      if (mentor.isSkillVerified ||
                          mentor.isIdentityVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: AppColors.verified, size: 18),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    if (headlineDisplay.isNotEmpty)
                      Text(headlineDisplay,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star, color: AppColors.star, size: 16),
                      const SizedBox(width: 4),
                      Text(
                          '${mentor.ratingAvg.toStringAsFixed(1)} · ${mentor.totalSessions} completed sessions'),
                    ]),
                    if (mentor.isSkillVerified ||
                        mentor.isIdentityVerified) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Verified Industry Professionals',
                        style: TextStyle(
                            color: AppColors.mint,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (mentor.bio.isNotEmpty) ...[
            Text(mentor.bio, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (allSkills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allSkills
                  .map((s) =>
                      Chip(label: Text(s), backgroundColor: AppColors.surface))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (mentor.faculty.isNotEmpty ||
              mentor.qualifications.degree.isNotEmpty) ...[
            Text(
              '${mentor.qualifications.degree.isNotEmpty ? mentor.qualifications.degree : mentor.title} · ${mentor.faculty.isNotEmpty ? mentor.faculty : mentor.qualifications.faculty}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (mentor.qualifications.githubUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openLink(mentor.qualifications.githubUrl),
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('GitHub'),
                ),
              if (mentor.qualifications.linkedinUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openLink(mentor.qualifications.linkedinUrl),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('LinkedIn'),
                ),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          const Text('Mentor track record',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.star, size: 22),
                const SizedBox(width: 8),
                Text(mentor.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'from ${mentor.totalSessions} completed sessions',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Choose a session length',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _durationOption(30, '30 Mins', mentor.pricingTiers.tier30m),
              const SizedBox(width: 8),
              _durationOption(60, '1 Hour', mentor.pricingTiers.tier60m),
              const SizedBox(width: 8),
              _durationOption(120, '2 Hours', mentor.pricingTiers.tier120m),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Available slots (need $_slotsNeeded contiguous)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
            ),
            itemCount: _slots.length,
            itemBuilder: (context, i) {
              final slot = _slots[i];
              final selected = _selectedSlotId == slot['id'];
              return OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selected ? AppColors.mint.withValues(alpha: 0.15) : null,
                  side: BorderSide(
                      color: selected ? AppColors.mint : AppColors.border),
                ),
                onPressed: () => setState(() => _selectedSlotId = slot['id']),
                child: Text(slot['time'],
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${mentor.pricingTiers.priceFor(_selectedDuration).toStringAsFixed(2)} / $_selectedDuration min',
                style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Bank-Grade Escrow Protection    • 100% Escrow Guarantee',
                style: TextStyle(color: AppColors.surfaceRaised, fontSize: 11),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onBookCall,
                  child: const Text('BOOK SESSION NOW'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationOption(int minutes, String label, double price) {
    final selected = _selectedDuration == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = minutes),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.mint.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: selected ? AppColors.mint : AppColors.border),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppColors.mint : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('\$${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
