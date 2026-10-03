import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/auth_required_sheet.dart';
import '../widgets/mentor/hourly_booking_tab_content.dart';
import '../widgets/mentor/mentor_profile_header.dart';
import '../widgets/mentor/monthly_booking_tab_content.dart';
import 'checkout_screen.dart';

class MentorProfileScreen extends StatefulWidget {
  final String mentorId;

  const MentorProfileScreen({super.key, required this.mentorId});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen>
    with SingleTickerProviderStateMixin {
  AppUser? _mentor;
  List<dynamic> _slots = [];
  bool _loading = true;
  int _selectedDuration = 60;
  String? _selectedSlotId;
  int _selectedPlan = 0;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getMentorProfile(widget.mentorId);
      if (!mounted) return;
      setState(() {
        _mentor = AppUser.fromJson(data['mentor']);
        _slots = data['availableSlots'] ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _slotsNeeded => _selectedDuration ~/ 30;

  List<dynamic> get _bookableSlots {
    final slots = List<dynamic>.from(_slots)
      ..sort((a, b) =>
          (a['startMinutes'] as num).compareTo(b['startMinutes'] as num));
    return slots.where((slot) {
      final start = (slot['startMinutes'] as num).toInt();
      return List<int>.generate(_slotsNeeded, (index) => start + index * 30)
          .every((minute) => slots.any(
                (candidate) =>
                    (candidate['startMinutes'] as num).toInt() == minute &&
                    candidate['isBooked'] != true,
              ));
    }).toList();
  }

  DateTime? get _selectedTime {
    final slot = _bookableSlots.cast<dynamic>().where(
          (item) => item['id'] == _selectedSlotId,
        );
    if (slot.isEmpty) return null;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final start = (slot.first['startMinutes'] as num).toInt();
    return DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day, start ~/ 60, start % 60);
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _book({required bool monthly}) async {
    final mentor = _mentor;
    if (mentor == null) return;
    final monthlyRate =
        (mentor.mentorProfile['monthlyRate'] as num?)?.toDouble() ?? 0;
    if (!monthly && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an available time slot.')),
      );
      return;
    }
    final hourlyRate = mentor.hourlyRate >= 500 ? mentor.hourlyRate : 1000.0;
    final hours = _selectedDuration / 60.0;
    final price = monthly ? monthlyRate : (hourlyRate * hours);
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await auth.savePendingBooking(PendingBooking(
        mentorId: mentor.id,
        durationMinutes: _selectedDuration,
        price: price,
        slotId: _selectedSlotId,
        monthlyPlan: monthly,
        scheduledTime: _selectedTime,
      ));
      if (!mounted) return;
      await showAuthRequiredSheet(
        context,
        action: monthly
            ? 'start a monthly mentorship plan'
            : 'book an hourly session',
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          mentorId: mentor.id,
          durationMinutes: monthly ? 0 : _selectedDuration,
          price: price,
          planType: monthly ? 'monthly' : 'hourly',
          monthlyPrice: monthlyRate,
          scheduledTime: _selectedTime,
          mentorHourlyRate: monthly ? 0 : hourlyRate,
          mentor: mentor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mentor = _mentor;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (mentor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Mentor not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(mentor.name),
        actions: [
          if (mentor.isIdentityVerified || mentor.isSkillVerified)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.verified, color: AppColors.mint),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MentorProfileHeader(
              mentor: mentor,
              onGitHub: mentor.qualifications.githubUrl.isEmpty
                  ? null
                  : () => _openLink(mentor.qualifications.githubUrl),
              onLinkedIn: mentor.qualifications.linkedinUrl.isEmpty
                  ? null
                  : () => _openLink(mentor.qualifications.linkedinUrl),
            ),
            TabBar(
              controller: _tabs,
              onTap: (index) => setState(() => _selectedPlan = index),
              labelColor: AppColors.mint,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.mint,
              tabs: const [
                Tab(text: 'Hourly Micro-Sessions'),
                Tab(text: 'Monthly Mentorship'),
              ],
            ),
            if (_selectedPlan == 0)
              HourlyBookingTabContent(
                hourlyRate: mentor.hourlyRate,
                selectedDuration: _selectedDuration,
                selectedSlotId: _selectedSlotId,
                slots: _bookableSlots,
                onDurationChanged: (duration) => setState(() {
                  _selectedDuration = duration;
                  _selectedSlotId = null;
                }),
                onSlotSelected: (slotId) =>
                    setState(() => _selectedSlotId = slotId),
                onBook: () => _book(monthly: false),
              )
            else
              MonthlyBookingTabContent(
                monthlyRate:
                    (mentor.mentorProfile['monthlyRate'] as num?)?.toDouble() ??
                        0,
                activeMentees:
                    (mentor.mentorProfile['activeMentees'] as num?)?.toInt() ??
                        0,
                maxMentees:
                    (mentor.mentorProfile['maxMentees'] as num?)?.toInt() ?? 0,
                onEnroll: () => _book(monthly: true),
              ),
          ],
        ),
      ),
    );
  }
}
