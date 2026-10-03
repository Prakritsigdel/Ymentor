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
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_none, color: AppColors.star),
                  const SizedBox(width: 8),
                  Text('Session updates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Session booked for ${TimeOfDay.fromDateTime(scheduledTime).format(context)}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Text(
                'Session active. Access your workspace notes, files, and chat below. · $durationMinutes minutes',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Text(
                'Please upload workspace code before the call.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Text(
                '15 minutes remaining reminder will appear during the session.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
}
