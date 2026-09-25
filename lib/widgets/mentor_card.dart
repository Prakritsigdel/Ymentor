import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/user_model.dart';

class MentorCard extends StatelessWidget {
  final AppUser mentor;
  final VoidCallback onTap;
  final int? rank;

  const MentorCard({super.key, required this.mentor, required this.onTap, this.rank});

  @override
  Widget build(BuildContext context) {
    final displayHeadline = mentor.headline.isNotEmpty
        ? mentor.headline
        : (mentor.title.isNotEmpty
            ? mentor.title
            : (mentor.faculty.isNotEmpty ? mentor.faculty : mentor.bio));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank != null) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: rank! <= 3 ? AppColors.star : AppColors.border,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rank! <= 3 ? AppColors.background : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.mint.withValues(alpha: 0.18),
                backgroundImage: mentor.avatarUrl.isNotEmpty ? NetworkImage(mentor.avatarUrl) : null,
                child: mentor.avatarUrl.isEmpty
                    ? Text(
                        mentor.name.isNotEmpty ? mentor.name[0] : 'M',
                        style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.bold, fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mentor.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mentor.isSkillVerified || mentor.isIdentityVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 16, color: AppColors.verified),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (displayHeadline.isNotEmpty)
                      Text(
                        displayHeadline,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(Icons.star, mentor.ratingAvg.toStringAsFixed(2), AppColors.star),
                        _pill(Icons.people, '${mentor.totalSessions} sessions', AppColors.cyan),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'From \$${mentor.pricingTiers.tier30m.toStringAsFixed(0)}/session',
                            style: const TextStyle(color: AppColors.mint, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
