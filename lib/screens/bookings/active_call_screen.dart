import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/brand_footer.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final bookings = await ApiService.getUserBookings(user.id);
      bookings.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      if (!mounted) return;
      setState(() => _bookings = bookings);
    } catch (_) {
      // keep prior state on failure
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinCall(Booking booking) async {
    final uri = Uri.tryParse(booking.meetingUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video call: $e')),
        );
      }
    }
  }

  Future<void> _markComplete(Booking booking) async {
    double rating = 5.0;
    final controller =
        TextEditingController(text: 'Outstanding mentorship session!');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Complete Session & Release Escrow'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate your mentor to release the 80% payout from escrow:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < rating;
                  return IconButton(
                    icon: Icon(filled ? Icons.star : Icons.star_border,
                        color: AppColors.star, size: 28),
                    onPressed: () =>
                        setDialogState(() => rating = (i + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration:
                    const InputDecoration(labelText: 'Review & Feedback Note'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Release Escrow Funds'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.completeBooking(booking.id,
          rating: rating, reviewNote: controller.text);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Session completed! Escrow funds released to mentor.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final isMentee = user?.role == 'mentee';
    final isLoggedIn = auth.isLoggedIn && user != null;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Sessions',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (!isLoggedIn)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Log in to see your scheduled sessions.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_bookings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.video_camera_front_outlined,
                            size: 54, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No sessions booked yet.\nDiscover mentors and book a 1-on-1 call to start learning.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  ..._bookings.map((b) {
                    final isHeld = b.isHeld;
                    final otherPartyName = isMentee
                        ? (b.mentorName ?? 'Mentor')
                        : (b.menteeName ?? 'Mentee');

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
                                Text(otherPartyName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (b.status == 'CONFIRMED'
                                            ? AppColors.mint
                                            : AppColors.primary)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    b.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: b.status == 'CONFIRMED'
                                          ? AppColors.mint
                                          : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${b.durationMinutes} min · ${DateFormat('EEE, MMM d · h:mm a').format(b.scheduledTime)}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                    isHeld ? Icons.lock_clock : Icons.lock_open,
                                    size: 16,
                                    color: isHeld
                                        ? AppColors.star
                                        : AppColors.mint),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.star.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isHeld
                                        ? 'HELD IN ESCROW'
                                        : b.escrowStatus
                                            .toUpperCase()
                                            .replaceAll('_', ' '),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.star,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _financialRow(
                                'Mentor net payout',
                                b.financials.mentorNetPayout80Percent,
                                AppColors.mint),
                            const SizedBox(height: 5),
                            _financialRow(
                                'Platform protection fee',
                                b.financials.platformCommission20Percent,
                                AppColors.textSecondary),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: b.meetingUrl.trim().isEmpty
                                        ? null
                                        : () => _joinCall(b),
                                    icon: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _LiveDot(),
                                        SizedBox(width: 8),
                                        Icon(Icons.videocam, size: 18),
                                      ],
                                    ),
                                    label: Text(
                                      b.meetingUrl.trim().isEmpty
                                          ? 'MEETING LINK UNAVAILABLE'
                                          : Uri.tryParse(b.meetingUrl)
                                                      ?.host
                                                      .contains(
                                                          'meet.google.com') ==
                                                  true
                                              ? 'JOIN GOOGLE MEET CALL'
                                              : 'JOIN VIDEO CALL',
                                    ),
                                  ),
                                ),
                                if (isHeld && isMentee) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.mint,
                                          foregroundColor:
                                              AppColors.background),
                                      onPressed: () => _markComplete(b),
                                      icon: const Icon(Icons.check_circle,
                                          size: 18),
                                      label: const Text('Complete & Pay'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const BrandFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _financialRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text('\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: const Icon(Icons.circle, color: Colors.white, size: 8),
    );
  }
}
