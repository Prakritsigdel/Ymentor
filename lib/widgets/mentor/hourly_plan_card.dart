import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/currency_formatter.dart';

class HourlyPlanCard extends StatelessWidget {
  final double hourlyRate;
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onBook;

  const HourlyPlanCard({
    super.key,
    required this.hourlyRate,
    required this.selectedDuration,
    required this.onDurationChanged,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.cyan),
              const SizedBox(height: 10),
              const Text('Hourly Micro-Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 6),
              Text('${CurrencyUtils.formatNPR(hourlyRate)} / hour',
                  style: const TextStyle(
                      color: AppColors.mint,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Flexible 1, 2, or 3-hour sessions for code reviews, resume checks, and targeted Q&A.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 60, label: Text('1 hr')),
                  ButtonSegment(value: 120, label: Text('2 hr')),
                  ButtonSegment(value: 180, label: Text('3 hr')),
                ],
                selected: {selectedDuration},
                onSelectionChanged: (selection) =>
                    onDurationChanged(selection.first),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onBook,
                  child: const Text('Book Micro-Session'),
                ),
              ),
            ],
          ),
        ),
      );
}
