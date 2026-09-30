import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import 'app_logo_widget.dart';

class BrandFooter extends StatelessWidget {
  const BrandFooter({super.key});

  static const _faqs = <(String, String)>[
    (
      'How does escrow protection work?',
      'Your session payment is held securely until the session is complete.',
    ),
    (
      'How are mentors verified?',
      'Mentors are reviewed for identity and professional expertise before verification.',
    ),
    (
      'How can I get support?',
      'Email our support team and we will help with your account or session.',
    ),
  ];

  Future<void> _emailSupport() async {
    final uri = Uri(scheme: 'mailto', path: 'support@ymentor.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogoWidget(height: 36),
              const SizedBox(width: 10),
              Text(
                'Ymentor',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your trusted source to find highly vetted mentors...',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          ..._faqs.map(
            (faq) => Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                iconColor: AppColors.mint,
                collapsedIconColor: AppColors.textSecondary,
                title: Text(faq.$1,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.$2,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 20),
          TextButton.icon(
            onPressed: _emailSupport,
            icon: const Icon(Icons.mail_outline, size: 18),
            label: const Text('support@ymentor.com'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 15, color: AppColors.mint),
                SizedBox(width: 7),
                Text(
                  '100% Escrow Guarantee',
                  style: TextStyle(
                      color: AppColors.mint,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
