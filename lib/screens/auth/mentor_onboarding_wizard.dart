import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/onboarding_draft.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/auth/onboarding_progress_header.dart';
import '../../widgets/onboarding_fields.dart';
import '../root_shell.dart';

class MentorOnboardingWizard extends StatefulWidget {
  const MentorOnboardingWizard({super.key});

  @override
  State<MentorOnboardingWizard> createState() => _MentorOnboardingWizardState();
}

class _MentorOnboardingWizardState extends State<MentorOnboardingWizard> {
  final _draft = MentorOnboardingDraft();
  final Map<String, File> _files = {};
  int _step = 0;
  bool _submitting = false;
  String? _error;

  static const _stepTitles = [
    'Demographics',
    'Expertise',
    'Qualifications',
    'Identity verification',
    'Logistics & pricing',
  ];

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _pick(String field, List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (!mounted) return;
    if (result?.files.single.path case final path?) {
      setState(() => _files[field] = File(path));
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      initialDate: DateTime.now().subtract(const Duration(days: 25 * 365)),
    );
    if (!mounted || selected == null) return;
    _draft.dateOfBirth.text = '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Future<void> _submit() async {
    final dob = DateTime.tryParse(_draft.dateOfBirth.text.trim());
    if (_draft.legalName.text.trim().isEmpty ||
        _draft.email.text.trim().isEmpty ||
        _draft.password.text.length < 8 ||
        _draft.headline.text.trim().isEmpty ||
        dob == null ||
        DateTime.now().difference(dob).inDays < 18 * 365) {
      setState(() => _error =
          'Enter your name, email, password (8+ characters), headline, and a valid date confirming you are 18 or older.');
      return;
    }
    final hourly = double.tryParse(_draft.hourlyRate.text) ?? 0;
    final monthly = double.tryParse(_draft.monthlyRate.text) ?? 0;
    if (hourly <= 0 || monthly <= 4) {
      setState(() => _error =
          'Set a valid hourly rate and a monthly plan rate greater than the platform fee.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        await auth.register(
          name: _draft.legalName.text.trim(),
          email: _draft.email.text.trim(),
          password: _draft.password.text,
          role: 'mentor',
        );
      }
      final updated = await ApiService.submitMentorOnboarding(
        fields: {
          'legalName': _draft.legalName.text.trim(),
          'headline': _draft.headline.text.trim(),
          'dateOfBirth': _draft.dateOfBirth.text.trim(),
          'location': _draft.location.text.trim(),
          'timezone': _draft.timezone.text.trim(),
          'avatarUrl': _draft.avatarUrl.text.trim(),
          'primaryDomain': _draft.primaryDomain.text.trim(),
          'subSkills': _draft.selectedSubSkills.join(', '),
          'yearsExperience': _draft.yearsExperience.text,
          'currentRole': (_draft.currentRoleSelection == 'Other'
                  ? _draft.customRole.text
                  : _draft.currentRole.text)
              .trim(),
          'currentOrganization': _draft.organization.text.trim(),
          'bio': _draft.bio.text.trim(),
          'linkedinUrl': _draft.linkedinUrl.text.trim(),
          'portfolioUrl': _draft.portfolioUrl.text.trim(),
          'highestDegree': _draft.highestDegree.text.trim(),
          'governmentIdType': _draft.governmentIdType,
          'hourlyRate': hourly.toString(),
          'monthlyRate': monthly.toString(),
          'maxMentees': _draft.maxMentees.text,
          'weeklyAvailableHours': _draft.weeklyHours.text,
          'fluentLanguages': _draft.languages.text,
        },
        files: _files,
      );
      await auth.updateProfile(
        name: updated.name,
        bio: updated.bio,
        title: updated.title,
        faculty: updated.faculty,
        skillsOrInterests: updated.skillsOrInterests,
        hourlyRate: updated.hourlyRate,
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
      0 => MentorIdentityFields(
          draft: _draft,
          onPickDate: _pickDate,
          onHeadlineChanged: (value) {
            setState(() {
              _draft.headlineSelection = value;
              if (value != 'Other (Type custom)') _draft.headline.text = value;
            });
          },
          onPickAvatar: () => _pick('avatar', ['jpg', 'jpeg', 'png', 'webp']),
          selectedAvatar:
              _files['avatar']?.path.split(Platform.pathSeparator).last,
        ),
      1 => MentorExpertiseFields(
          draft: _draft,
          onDomainChanged: (value) {
            setState(() {
              _draft.primaryDomainSelection = value;
              _draft.primaryDomain.text = value;
            });
          },
          onRoleChanged: (value) {
            setState(() {
              _draft.currentRoleSelection = value;
              _draft.currentRole.text =
                  value == 'Other' ? _draft.customRole.text : value;
            });
          },
          onSkillsChanged: (skills) =>
              setState(() => _draft.selectedSubSkills = skills),
        ),
      2 => MentorQualificationFields(
          draft: _draft,
          onPickProof: () => _pick('qualificationProof', ['pdf']),
          selectedFile: _files['qualificationProof']
              ?.path
              .split(Platform.pathSeparator)
              .last,
        ),
      3 => MentorIdentityProofFields(
          draft: _draft,
          onIdTypeChanged: (value) =>
              setState(() => _draft.governmentIdType = value),
          onPickFront: () =>
              _pick('identityFront', ['pdf', 'jpg', 'jpeg', 'png', 'webp']),
          onPickBack: () =>
              _pick('identityBack', ['pdf', 'jpg', 'jpeg', 'png', 'webp']),
          frontFile:
              _files['identityFront']?.path.split(Platform.pathSeparator).last,
          backFile:
              _files['identityBack']?.path.split(Platform.pathSeparator).last,
        ),
      _ => MentorLogisticsFields(draft: _draft),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Application')),
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
                              ? 'Submit for verification'
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
