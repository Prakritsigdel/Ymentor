import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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
    final controller = TextEditingController(text: 'Outstanding mentorship session!');

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
                    icon: Icon(filled ? Icons.star : Icons.star_border, color: AppColors.star, size: 28),
                    onPressed: () => setDialogState(() => rating = (i + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Review & Feedback Note'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
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
      await ApiService.completeBooking(booking.id, rating: rating, reviewNote: controller.text);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session completed! Escrow funds released to mentor.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (!auth.isLoggedIn || user == null) {
      return const Center(
        child: Text('Log in to see your scheduled sessions.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.video_camera_front_outlined, size: 54, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No sessions booked yet.\nDiscover mentors and book a 1-on-1 call to start learning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final isMentee = user.role == 'mentee';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, i) {
          final b = _bookings[i];
          final isHeld = b.isHeld;
          final otherPartyName = isMentee ? (b.mentorName ?? 'Mentor') : (b.menteeName ?? 'Mentee');

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
                      Text(otherPartyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (b.status == 'COMPLETED' ? AppColors.mint : AppColors.cyan).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          b.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: b.status == 'COMPLETED' ? AppColors.mint : AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${b.durationMinutes} min · ${DateFormat('EEE, MMM d · h:mm a').format(b.scheduledTime)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(isHeld ? Icons.lock_clock : Icons.lock_open,
                          size: 16, color: isHeld ? AppColors.star : AppColors.mint),
                      const SizedBox(width: 6),
                      Text(
                        'Escrow: ${b.escrowStatus.toUpperCase()} · \$${b.financials.grossAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _joinCall(b),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Join Call'),
                        ),
                      ),
                      if (isHeld && isMentee) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
                            onPressed: () => _markComplete(b),
                            icon: const Icon(Icons.check_circle, size: 18),
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
        },
      ),
    );
  }
}
