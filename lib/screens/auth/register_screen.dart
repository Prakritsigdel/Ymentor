import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'login_screen.dart';
import 'mentor_onboarding_wizard.dart';
import 'mentee_onboarding_wizard.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Choose your Ymentor role')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Build your mentorship profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose how you want to take part in the community.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _RoleCard(
              title: 'Mentee (Student)',
              description: 'Set learning goals and find the right expert.',
              icon: Icons.school_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MenteeOnboardingWizard(),
              )),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              title: 'Mentor (Expert)',
              description:
                  'Share your expertise through hourly or monthly plans.',
              icon: Icons.psychology_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MentorOnboardingWizard(),
              )),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              title: 'Admin',
              description:
                  'Administrator access is provisioned by platform operations.',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ),
      );
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.mint, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 6),
                      Text(description,
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      );
}
