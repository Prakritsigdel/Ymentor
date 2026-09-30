import 'package:flutter/material.dart';

class OnboardingProgressHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;

  const OnboardingProgressHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${step + 1} of $totalSteps',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '${((step + 1) / totalSteps * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (step + 1) / totalSteps,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
}
