import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/onboarding_draft.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/auth/custom_input_field.dart';
import '../../widgets/auth/onboarding_progress_header.dart';
import '../../widgets/onboarding_fields.dart';
import '../root_shell.dart';

class MenteeOnboardingWizard extends StatefulWidget {
  const MenteeOnboardingWizard({super.key});

  @override
  State<MenteeOnboardingWizard> createState() => _MenteeOnboardingWizardState();
}

class _MenteeOnboardingWizardState extends State<MenteeOnboardingWizard> {
  final _draft = MenteeOnboardingDraft();
  int _step = 0;
  bool _submitting = false;
  String? _error;

  static const _stepTitles = [
    'Academic status',
    'Learning objectives',
    'Competency level',
    'Preferences & engagement',
  ];

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_draft.name.text.trim().isEmpty ||
        _draft.email.text.trim().isEmpty ||
        _draft.password.text.length < 8) {
      setState(() => _error =
          'Enter your name, email, and a password with at least 8 characters.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.register(
        name: _draft.name.text.trim(),
        email: _draft.email.text.trim(),
        password: _draft.password.text,
        role: 'mentee',
      );
      final updated = await ApiService.completeMenteeOnboarding(
        academicStatus: _draft.academicStatus,
        fieldOfInterest: _draft.fieldOfInterest.text.trim(),
        primaryGoal: _draft.primaryGoalSelection == 'Other'
            ? _draft.primaryGoal.text.trim()
            : _draft.primaryGoalSelection,
        targetSkills: _draft.selectedTargetSkills,
        competencyLevel: _draft.competencyLevel,
        preferredMode: const {
          'Hourly Micro-Sessions': 'hourly',
          'Monthly Dedicated Mentorship': 'monthly',
          'Both': 'both',
          'Not Sure': 'not_sure',
        }[_draft.preferredMode]!,
        mentorStyle: _draft.mentorStyle,
        targetBudget: double.tryParse(_draft.targetBudget.text) ?? 0,
        weeklyCommitmentHours: double.tryParse(_draft.weeklyHours.text) ?? 0,
      );
      await auth.updateProfile(
        name: updated.name,
        bio: updated.bio,
        title: updated.title,
        faculty: updated.faculty,
        skillsOrInterests: updated.skillsOrInterests,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      0 => OnboardingFieldGroup(
          children: [
            CustomInputField(controller: _draft.name, label: 'Full name'),
            CustomInputField(
                controller: _draft.email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress),
            CustomInputField(
                controller: _draft.password,
                label: 'Password',
                obscureText: true),
            MenteeAcademicFields(
              draft: _draft,
              onChanged: (value) =>
                  setState(() => _draft.academicStatus = value),
            ),
          ],
        ),
      1 => MenteeLearningFields(
          draft: _draft,
          onGoalChanged: (value) {
            setState(() {
              _draft.primaryGoalSelection = value;
              if (value != 'Other') _draft.primaryGoal.text = value;
            });
          },
          onSkillsChanged: (skills) =>
              setState(() => _draft.selectedTargetSkills = skills),
        ),
      2 => MenteeCompetencyFields(
          draft: _draft,
          onChanged: (value) => setState(() => _draft.competencyLevel = value),
        ),
      _ => MenteePreferenceFields(
          draft: _draft,
          onModeChanged: (value) =>
              setState(() => _draft.preferredMode = value),
          onStyleChanged: (value) => setState(() => _draft.mentorStyle = value),
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Mentee Onboarding')),
      body: Column(
        children: [
          OnboardingProgressHeader(
            step: _step,
            totalSteps: _stepTitles.length,
            title: _stepTitles[_step],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: content,
            ),
          ),
          if (_error case final error?)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(error),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _submitting ? null : () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_step < _stepTitles.length - 1) {
                                setState(() => _step++);
                              } else {
                                _submit();
                              }
                            },
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_step == _stepTitles.length - 1
                              ? 'Finish onboarding'
                              : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
