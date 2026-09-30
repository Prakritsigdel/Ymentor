import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/onboarding_draft.dart';
import 'auth/custom_dropdown_field.dart';
import 'auth/custom_input_field.dart';
import 'auth/dynamic_skill_chip_selector.dart';

class OnboardingFieldGroup extends StatelessWidget {
  final List<Widget> children;

  const OnboardingFieldGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 16),
            children[index],
          ],
        ],
      );
}

class UploadActionCard extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const UploadActionCard({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
}

class MentorIdentityFields extends StatelessWidget {
  final MentorOnboardingDraft draft;
  final VoidCallback onPickAvatar;
  final String? selectedAvatar;
  final ValueChanged<String> onHeadlineChanged;
  final VoidCallback onPickDate;

  const MentorIdentityFields({
    super.key,
    required this.draft,
    required this.onPickAvatar,
    required this.selectedAvatar,
    required this.onHeadlineChanged,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomInputField(controller: draft.legalName, label: 'Legal name'),
          CustomInputField(
              controller: draft.email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress),
          CustomInputField(
              controller: draft.password, label: 'Password', obscureText: true),
          CustomDropdownField(
            label: 'Display headline',
            value: draft.headlineSelection,
            items: const [
              'Lead Mobile Architect',
              'Senior Full-Stack Engineer',
              'Staff Backend Developer',
              'UI/UX Lead',
              'Other (Type custom)',
            ],
            onChanged: onHeadlineChanged,
          ),
          if (draft.headlineSelection == 'Other (Type custom)')
            CustomInputField(
                controller: draft.headline, label: 'Custom headline'),
          CustomInputField(
              controller: draft.dateOfBirth,
              label: 'Date of birth (YYYY-MM-DD)',
              keyboardType: TextInputType.datetime,
              readOnly: true,
              onTap: onPickDate),
          CustomInputField(controller: draft.location, label: 'Location'),
          CustomInputField(
              controller: draft.timezone,
              label: 'Timezone (e.g. Asia/Kathmandu)'),
          CustomInputField(
              controller: draft.avatarUrl,
              label: 'Avatar image URL (optional)'),
          UploadActionCard(
            onPressed: onPickAvatar,
            icon: Icons.account_circle_outlined,
            label: selectedAvatar ?? 'Upload profile avatar (optional)',
          ),
        ],
      );
}

class MentorExpertiseFields extends StatelessWidget {
  final MentorOnboardingDraft draft;
  final ValueChanged<String> onDomainChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<List<String>> onSkillsChanged;

  const MentorExpertiseFields({
    super.key,
    required this.draft,
    required this.onDomainChanged,
    required this.onRoleChanged,
    required this.onSkillsChanged,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomDropdownField(
            label: 'Primary domain',
            value: draft.primaryDomainSelection,
            items: const [
              'Mobile Development',
              'Backend Engineering',
              'Frontend & Web',
              'AI / Machine Learning',
              'DevOps & Cloud',
            ],
            onChanged: onDomainChanged,
          ),
          DynamicSkillChipSelector(
            label: 'Sub-skills',
            options: const [
              'Flutter',
              'Node.js',
              'Python',
              'System Design',
              'React',
              'SQL',
            ],
            selectedSkills: draft.selectedSubSkills,
            onChanged: onSkillsChanged,
          ),
          CustomInputField(
              controller: draft.yearsExperience,
              label: 'Years of experience',
              keyboardType: TextInputType.number),
          CustomDropdownField(
            label: 'Current role',
            value: draft.currentRoleSelection,
            items: const [
              'Software Engineer / Developer',
              'Senior / Staff Engineer',
              'Engineering Manager / Tech Lead',
              'Frontend / Web Developer',
              'Backend / Systems Engineer',
              'Mobile App Architect (Flutter / iOS / Android)',
              'AI / Machine Learning Engineer',
              'Data Scientist / Analyst',
              'DevOps / Cloud Engineer',
              'UI/UX & Product Designer',
              'Product Manager',
              'QA / Security Engineer',
              'Freelancer / Consultant',
              'Student / Academic Educator',
              'Other',
            ],
            onChanged: onRoleChanged,
          ),
          if (draft.currentRoleSelection == 'Other')
            CustomInputField(
              controller: draft.customRole,
              label: 'Specify your role',
            ),
          CustomInputField(
              controller: draft.organization, label: 'Organization'),
          CustomInputField(
              controller: draft.bio,
              label: 'Short professional bio',
              maxLines: 4),
        ],
      );
}

class MentorQualificationFields extends StatelessWidget {
  final MentorOnboardingDraft draft;
  final VoidCallback onPickProof;
  final String? selectedFile;

  const MentorQualificationFields({
    super.key,
    required this.draft,
    required this.onPickProof,
    required this.selectedFile,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomInputField(
              controller: draft.linkedinUrl,
              label: 'LinkedIn URL',
              keyboardType: TextInputType.url),
          CustomInputField(
              controller: draft.portfolioUrl,
              label: 'Portfolio or GitHub URL',
              keyboardType: TextInputType.url),
          CustomInputField(
              controller: draft.highestDegree, label: 'Highest degree'),
          UploadActionCard(
            onPressed: onPickProof,
            icon: Icons.upload_file,
            label: selectedFile ?? 'Upload degree or certificate PDF',
          ),
        ],
      );
}

class MentorIdentityProofFields extends StatelessWidget {
  final MentorOnboardingDraft draft;
  final ValueChanged<String> onIdTypeChanged;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;
  final String? frontFile;
  final String? backFile;

  const MentorIdentityProofFields({
    super.key,
    required this.draft,
    required this.onIdTypeChanged,
    required this.onPickFront,
    required this.onPickBack,
    required this.frontFile,
    required this.backFile,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomDropdownField(
            label: 'Government ID type',
            value: draft.governmentIdType,
            items: const ['Passport', 'National ID', 'Driver license'],
            onChanged: onIdTypeChanged,
          ),
          UploadActionCard(
            onPressed: onPickFront,
            icon: Icons.upload_file,
            label: frontFile ?? 'Upload government ID front',
          ),
          UploadActionCard(
            onPressed: onPickBack,
            icon: Icons.upload_file,
            label: backFile ?? 'Upload government ID back',
          ),
          const Text(
            'Identity files are used only for verification and must be stored securely.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      );
}

class MentorLogisticsFields extends StatelessWidget {
  final MentorOnboardingDraft draft;

  const MentorLogisticsFields({super.key, required this.draft});

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomDropdownField(
            label: 'Hourly rate (NPR per hour)',
            value: draft.hourlyRateTier,
            items: const [
              'NPR 500 – NPR 1,500 / hr',
              'NPR 1,500 – NPR 3,500 / hr',
              'NPR 3,500 – NPR 4,000 / hr',
              'NPR 5,000+ / hr',
              'Custom / Other',
            ],
            onChanged: (value) {
              draft.hourlyRateTier = value;
              draft.hourlyRate.text = {
                    'NPR 500 – NPR 1,500 / hr': '1500',
                    'NPR 1,500 – NPR 3,500 / hr': '3500',
                    'NPR 3,500 – NPR 4,000 / hr': '4000',
                    'NPR 5,000+ / hr': '5000',
                  }[value] ??
                  draft.hourlyRate.text;
            },
          ),
          CustomDropdownField(
            label: 'Monthly plan rate (NPR per month)',
            value: draft.monthlyRateTier,
            items: const [
              'Under NPR 6,000 / month',
              'NPR 6,000 – NPR 8,000 / month',
              'NPR 8,000 – NPR 15,000 / month',
              'NPR 15,000+ / month',
              'Custom / Other',
            ],
            onChanged: (value) {
              draft.monthlyRateTier = value;
              draft.monthlyRate.text = {
                    'Under NPR 6,000 / month': '5000',
                    'NPR 6,000 – NPR 8,000 / month': '7500',
                    'NPR 8,000 – NPR 15,000 / month': '12000',
                    'NPR 15,000+ / month': '15000',
                  }[value] ??
                  draft.monthlyRate.text;
            },
          ),
          CustomInputField(
              controller: draft.maxMentees,
              label: 'Maximum monthly mentees',
              keyboardType: TextInputType.number),
          CustomInputField(
              controller: draft.weeklyHours,
              label: 'Weekly available hours',
              keyboardType: TextInputType.number),
          CustomInputField(
              controller: draft.languages,
              label: 'Fluent languages (comma separated)'),
        ],
      );
}

class MenteeAcademicFields extends StatelessWidget {
  final MenteeOnboardingDraft draft;
  final ValueChanged<String> onChanged;

  const MenteeAcademicFields({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomDropdownField(
            label: 'Current status',
            value: draft.academicStatus,
            items: const [
              'High School',
              'Undergraduate (1st/2nd Year)',
              'Undergraduate (3rd/4th Year)',
              'Graduate / Post-Grad',
              'Career Switcher / Self-Taught',
            ],
            onChanged: onChanged,
          ),
          CustomInputField(
              controller: draft.fieldOfInterest,
              label: 'Field of interest or major'),
        ],
      );
}

class MenteeLearningFields extends StatelessWidget {
  final MenteeOnboardingDraft draft;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<List<String>> onSkillsChanged;

  const MenteeLearningFields({
    super.key,
    required this.draft,
    required this.onGoalChanged,
    required this.onSkillsChanged,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomDropdownField(
            label: 'Primary learning goal',
            value: draft.primaryGoalSelection,
            items: const [
              'Land First Tech Job',
              'Code Review & Debugging',
              'System Design & Architecture',
              'Resume & Interview Prep',
              'Long-term Career Guidance',
              'Other',
            ],
            onChanged: onGoalChanged,
          ),
          if (draft.primaryGoalSelection == 'Other')
            CustomInputField(
                controller: draft.primaryGoal, label: 'Custom learning goal'),
          DynamicSkillChipSelector(
            label: 'Targeted skills',
            options: const [
              'Flutter',
              'Node.js',
              'Python',
              'System Design',
              'React',
              'SQL',
            ],
            selectedSkills: draft.selectedTargetSkills,
            onChanged: onSkillsChanged,
          ),
        ],
      );
}

class MenteeCompetencyFields extends StatelessWidget {
  final MenteeOnboardingDraft draft;
  final ValueChanged<String> onChanged;

  const MenteeCompetencyFields({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => CustomDropdownField(
        label: 'Self-assessed skill level',
        value: draft.competencyLevel,
        items: const ['Beginner', 'Intermediate', 'Advanced'],
        onChanged: onChanged,
      );
}

class MenteePreferenceFields extends StatelessWidget {
  final MenteeOnboardingDraft draft;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onStyleChanged;

  const MenteePreferenceFields({
    super.key,
    required this.draft,
    required this.onModeChanged,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) => OnboardingFieldGroup(
        children: [
          CustomDropdownField(
            label: 'Preferred mentorship model',
            value: draft.preferredMode,
            items: const [
              'Hourly Micro-Sessions',
              'Monthly Dedicated Mentorship',
              'Both',
              'Not Sure',
            ],
            onChanged: onModeChanged,
          ),
          CustomDropdownField(
            label: 'Preferred mentor style',
            value: draft.mentorStyle,
            items: const [
              'Hands-on',
              'Strategic Advisor',
              'Accountability Partner',
            ],
            onChanged: onStyleChanged,
          ),
          CustomDropdownField(
            label: 'Budget expectation',
            value: draft.targetBudgetTier,
            items: const [
              'NPR 500 – NPR 1,500 / hr',
              'NPR 1,500 – NPR 3,500 / hr',
              'NPR 3,500 – NPR 4,000 / hr',
              'NPR 5,000+ / hr',
              'Under NPR 6,000 / month',
              'NPR 6,000 – NPR 8,000 / month',
              'NPR 8,000 – NPR 15,000 / month',
              'NPR 15,000+ / month',
              'Custom / Other',
            ],
            onChanged: (value) {
              draft.targetBudgetTier = value;
              draft.targetBudget.text = RegExp(r'\d[\d,]*')
                      .firstMatch(value)
                      ?.group(0)
                      ?.replaceAll(',', '') ??
                  '';
            },
          ),
          CustomInputField(
              controller: draft.weeklyHours,
              label: 'Weekly time commitment (hours)',
              keyboardType: TextInputType.number),
        ],
      );
}
