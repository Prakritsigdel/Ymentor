import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/currency_formatter.dart';

class MonthlyPlanCard extends StatelessWidget {
  final double monthlyRate;
  final int activeMentees;
  final int maxMentees;
  final VoidCallback onEnroll;

  const MonthlyPlanCard({
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
        ? (remaining > 0
            ? '$remaining of $maxMentees seats left'
            : 'At capacity')
        : 'Availability confirmed at checkout';

    return Card(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.calendar_month_outlined, color: AppColors.surface),
            const SizedBox(height: 10),
            const Text('Monthly Dedicated Mentorship',
                style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            const SizedBox(height: 6),
            Text(
              monthlyRate > 0
                  ? '${CurrencyUtils.formatNPR(monthlyRate)} / month'
                  : 'Pricing confirmed at checkout',
              style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(capacity,
                style: const TextStyle(
                    color: AppColors.surfaceRaised,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              '30-day mentorship with async local Wi-Fi chat, weekly calls, and shared workspace access.',
              style: TextStyle(color: AppColors.surfaceRaised, height: 1.35),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: monthlyRate > 0 && remaining != 0 ? onEnroll : null,
                child: const Text('Enroll Monthly Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
