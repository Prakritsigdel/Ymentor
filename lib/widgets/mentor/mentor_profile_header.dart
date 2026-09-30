import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../common/app_logo_avatar.dart';

class MentorProfileHeader extends StatelessWidget {
  final AppUser mentor;
  final VoidCallback? onGitHub;
  final VoidCallback? onLinkedIn;

  const MentorProfileHeader({
    super.key,
    required this.mentor,
    this.onGitHub,
    this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    final headline = mentor.headline.isNotEmpty
        ? mentor.headline
        : (mentor.title.isNotEmpty ? mentor.title : mentor.faculty);
    final skills = mentor.skillsOrInterests.isNotEmpty
        ? mentor.skillsOrInterests
        : mentor.qualifications.skills;
    final verified = mentor.isIdentityVerified || mentor.isSkillVerified;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLogoAvatar(
                size: 76,
                imageUrl: mentor.avatarUrl,
                fallbackText:
                    mentor.name.isEmpty ? 'Ym' : mentor.name[0].toUpperCase(),
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(headline,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '★ ${mentor.ratingAvg.toStringAsFixed(1)} · ${mentor.totalSessions} completed sessions',
                      style: const TextStyle(color: AppColors.star),
                    ),
                    if (verified) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Verified Industry Professional',
                        style: TextStyle(
                            color: AppColors.mint,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (mentor.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(mentor.bio,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.45)),
          ],
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.surface,
                      ))
                  .toList(),
            ),
          ],
          if (onGitHub != null || onLinkedIn != null) ...[
            Row(
              children: [
                if (onGitHub != null)
                  TextButton.icon(
                    onPressed: onGitHub,
                    icon: const Icon(Icons.code, size: 18),
                    label: const Text('GitHub'),
                  ),
                if (onLinkedIn != null)
                  TextButton.icon(
                    onPressed: onLinkedIn,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('LinkedIn'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
