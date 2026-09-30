import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/currency_formatter.dart';

class MonthlyBookingTabContent extends StatelessWidget {
  final double monthlyRate;
  final int activeMentees;
  final int maxMentees;
  final VoidCallback onEnroll;

  const MonthlyBookingTabContent({
    super.key,
    required this.monthlyRate,
    required this.activeMentees,
    required this.maxMentees,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = maxMentees > 0 ? maxMentees - activeMentees : 0;
    final capacity = maxMentees > 0
        ? '$remaining of $maxMentees seats available'
        : 'Availability confirmed at checkout';
    final unavailable = maxMentees > 0 && remaining <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            monthlyRate > 0
                ? '${CurrencyUtils.formatNPR(monthlyRate)} / month'
                : 'Pricing confirmed at checkout',
            style: const TextStyle(
                color: AppColors.mint,
                fontSize: 24,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Chip(
            avatar: const Icon(Icons.circle, color: AppColors.mint, size: 12),
            label: Text(capacity),
            backgroundColor: AppColors.surface,
          ),
          const SizedBox(height: 16),
          const _MonthlyFeature(
            icon: Icons.chat_bubble_outline,
            text: 'Unlimited 24/7 Local Wi-Fi Chat & File Sharing',
          ),
          const _MonthlyFeature(
            icon: Icons.event_outlined,
            text: 'Weekly 1-on-1 Strategy Calls',
          ),
          const _MonthlyFeature(
            icon: Icons.folder_open_outlined,
            text: 'Shared Project Workspace Access',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: monthlyRate > 0 && !unavailable ? onEnroll : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Enroll in Monthly Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MonthlyFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.surface,
        child: ListTile(
          leading: Icon(icon, color: AppColors.mint),
          title: Text(text),
        ),
      );
}
