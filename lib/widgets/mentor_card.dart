import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../utils/currency_formatter.dart';
import 'common/app_logo_avatar.dart';

class MentorCard extends StatelessWidget {
  final AppUser mentor;
  final VoidCallback onTap;
  final int? rank;
  final bool isSaved;
  final ValueChanged<bool>? onSaveChanged;

  const MentorCard({
    super.key,
    required this.mentor,
    required this.onTap,
    this.rank,
    this.isSaved = false,
    this.onSaveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayHeadline = mentor.headline.isNotEmpty
        ? mentor.headline
        : (mentor.title.isNotEmpty
            ? mentor.title
            : (mentor.faculty.isNotEmpty ? mentor.faculty : mentor.bio));

    final initials =
        mentor.name.trim().isEmpty ? 'Ym' : mentor.name.trim()[0].toUpperCase();

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rank != null) ...[
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 10, top: 3),
                      decoration: BoxDecoration(
                        color: rank! <= 3
                            ? AppColors.star.withValues(alpha: 0.15)
                            : AppColors.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank! <= 3
                              ? AppColors.star
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  AppLogoAvatar(
                    size: 60,
                    imageUrl: mentor.avatarUrl,
                    fallbackText: initials,
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.surface,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mentor.name.isNotEmpty ? mentor.name : 'Mentor',
                                style: GoogleFonts.playfairDisplay(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mentor.isSkillVerified ||
                                mentor.isIdentityVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  size: 18, color: AppColors.mint),
                            ],
                            if (onSaveChanged != null)
                              IconButton(
                                tooltip: isSaved
                                    ? 'Remove saved mentor'
                                    : 'Save mentor',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 38,
                                  height: 38,
                                ),
                                onPressed: () => onSaveChanged!(!isSaved),
                                icon: Icon(
                                  isSaved
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: AppColors.terracotta,
                                  size: 21,
                                ),
                              ),
                          ],
                        ),
                        if (displayHeadline.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            displayHeadline,
                            style: GoogleFonts.plusJakartaSans(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _pill(
                    Icons.star,
                    '★ ${mentor.ratingAvg.toStringAsFixed(2)}',
                    AppColors.star,
                  ),
                  _pill(
                    Icons.people_alt_outlined,
                    '${mentor.totalSessions} sessions',
                    AppColors.mint,
                  ),
                  _pricePill(
                      '${CurrencyUtils.formatCompactNPR(mentor.hourlyRate)} / hr'),
                  if (((mentor.mentorProfile['monthlyRate'] as num?)
                              ?.toDouble() ??
                          0) >
                      0)
                    _pricePill(
                      '${CurrencyUtils.formatCompactNPR((mentor.mentorProfile['monthlyRate'] as num?)?.toDouble() ?? 0)} / mo',
                    ),
                  if (mentor.isIdentityVerified)
                    _pill(Icons.verified, 'KYC verified', AppColors.mint),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onTap,
                  child: Text(
                    'Book Session',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pricePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.mint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
