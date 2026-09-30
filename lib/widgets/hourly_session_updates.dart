import 'package:flutter/material.dart';
import '../config/theme.dart';

class HourlySessionUpdates extends StatelessWidget {
  final DateTime scheduledTime;
  final int durationMinutes;

  const HourlySessionUpdates({
    super.key,
    required this.scheduledTime,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_none, color: AppColors.star),
                  SizedBox(width: 8),
                  Text('Session updates',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Session booked for ${TimeOfDay.fromDateTime(scheduledTime).format(context)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                'Google Meet link generated · $durationMinutes minutes',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Text(
                'Please upload workspace code before the call.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Text(
                '15 minutes remaining reminder will appear during the session.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}
