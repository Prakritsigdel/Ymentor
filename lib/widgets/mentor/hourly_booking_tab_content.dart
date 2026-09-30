import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/currency_formatter.dart';

class HourlyBookingTabContent extends StatelessWidget {
  final double hourlyRate;
  final int selectedDuration;
  final String? selectedSlotId;
  final List<dynamic> slots;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<String> onSlotSelected;
  final VoidCallback onBook;

  const HourlyBookingTabContent({
    super.key,
    required this.hourlyRate,
    required this.selectedDuration,
    required this.selectedSlotId,
    required this.slots,
    required this.onDurationChanged,
    required this.onSlotSelected,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${CurrencyUtils.formatNPR(hourlyRate)} / hour',
                style: const TextStyle(
                    color: AppColors.mint,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Flexible sessions for code reviews, resume checks, and targeted Q&A.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            const Text('Session duration',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [60, 120, 180]
                  .map((minutes) => ChoiceChip(
                        label: Text(
                            '${minutes ~/ 60} hour${minutes == 60 ? '' : 's'}'),
                        selected: selectedDuration == minutes,
                        onSelected: (_) => onDurationChanged(minutes),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 22),
            Text('Available time slots (${slots.length})',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No matching slots are available.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              SizedBox(
                height: ((slots.length + 1) ~/ 2) * 68,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 58,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final id = slot['id']?.toString() ?? '';
                    final selected = id == selectedSlotId;
                    return OutlinedButton(
                      onPressed: id.isEmpty ? null : () => onSlotSelected(id),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? AppColors.mint.withValues(alpha: 0.15)
                            : null,
                        side: BorderSide(
                            color:
                                selected ? AppColors.mint : AppColors.border),
                      ),
                      child: Text(slot['time']?.toString() ?? 'Available',
                          textAlign: TextAlign.center),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Book Hourly Session'),
              ),
            ),
          ],
        ),
      );
}
