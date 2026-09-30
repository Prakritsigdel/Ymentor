import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../utils/currency_formatter.dart';

class ProfileRoleDetails extends StatelessWidget {
  final AppUser user;
  final int activeMonthlyPlans;
  const ProfileRoleDetails(
      {super.key, required this.user, required this.activeMonthlyPlans});

  @override
  Widget build(BuildContext context) {
    if (user.isMentor) {
      final profile = user.mentorProfile;
      final monthly = (profile['monthlyRate'] as num?)?.toDouble() ?? 0;
      final qualification = user.qualifications;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mentor profile',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ListTile(
                  title: const Text('Headline'),
                  subtitle:
                      Text(user.headline.isEmpty ? user.title : user.headline)),
              ListTile(
                  title: const Text('Verification'),
                  subtitle: Text(user.verificationStatus.replaceAll('_', ' '))),
              ListTile(
                  title: const Text('Qualification'),
                  subtitle: Text(qualification.degree.isEmpty
                      ? 'Not provided'
                      : qualification.degree)),
              ListTile(
                  title: const Text('Hourly rate'),
                  subtitle: Text(
                      '${CurrencyUtils.formatNPR(user.hourlyRate)} / hour')),
              ListTile(
                  title: const Text('Monthly plan'),
                  subtitle: Text(monthly > 0
                      ? '${CurrencyUtils.formatNPR(monthly)} / month'
                      : 'Not offered')),
              ListTile(
                  title: const Text('Monthly capacity'),
                  subtitle: Text('${profile['maxMentees'] ?? 0} mentees')),
              if (user.bio.isNotEmpty)
                ListTile(title: const Text('About'), subtitle: Text(user.bio)),
              Wrap(
                children: [
                  if (qualification.linkedinUrl.isNotEmpty)
                    TextButton(
                        onPressed: () => _open(qualification.linkedinUrl),
                        child: const Text('LinkedIn')),
                  if (qualification.githubUrl.isNotEmpty)
                    TextButton(
                        onPressed: () => _open(qualification.githubUrl),
                        child: const Text('Portfolio / GitHub')),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final profile = user.menteeProfile;
    final skills = profile['targetSkills'] is List
        ? (profile['targetSkills'] as List)
            .map((item) => item.toString())
            .toList()
        : const <String>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Learning profile',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ListTile(
                title: const Text('Academic status'),
                subtitle: Text(
                    profile['academicStatus']?.toString() ?? 'Not provided')),
            ListTile(
                title: const Text('Learning goal'),
                subtitle:
                    Text(profile['primaryGoal']?.toString() ?? 'Not provided')),
            ListTile(
                title: const Text('Competency'),
                subtitle: Text(
                    profile['competencyLevel']?.toString() ?? 'Not assessed')),
            ListTile(
                title: const Text('Preferred mentorship'),
                subtitle: Text(
                    profile['preferredMode']?.toString() ?? 'Not specified')),
            ListTile(
                title: const Text('Active monthly plans'),
                subtitle: Text('$activeMonthlyPlans')),
            Wrap(
                spacing: 6,
                children:
                    skills.map((skill) => Chip(label: Text(skill))).toList()),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
