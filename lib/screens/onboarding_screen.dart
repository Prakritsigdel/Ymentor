import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

const List<String> kFacultyOptions = [
  'Computer Science',
  'Software Engineering',
  'Artificial Intelligence & Robotics',
  'Data Science & Analytics',
  'Information Systems',
  'Electrical & Computer Engineering',
];

const List<String> kInterestChips = [
  'Python',
  'Flutter',
  'AI',
  'System Design',
  'Node.js',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedFaculty = kFacultyOptions.first;
  final Set<String> _selectedInterests = {'Python', 'Flutter'};
  final _titleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController(text: '20');
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      if (user.faculty.isNotEmpty && kFacultyOptions.contains(user.faculty)) {
        _selectedFaculty = user.faculty;
      }
      if (user.skillsOrInterests.isNotEmpty) {
        _selectedInterests.addAll(user.skillsOrInterests);
      }
      if (user.title.isNotEmpty) _titleCtrl.text = user.title;
      if (user.bio.isNotEmpty) _bioCtrl.text = user.bio;
      if (user.hourlyRate > 0) _hourlyRateCtrl.text = user.hourlyRate.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _hourlyRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedInterests.isEmpty) {
      setState(() => _error = 'Please select at least one learning interest tag.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final isMentor = auth.isMentor;
      final rate = isMentor ? (double.tryParse(_hourlyRateCtrl.text.trim()) ?? 20.0) : null;

      await auth.completeOnboarding(
        faculty: _selectedFaculty,
        skillsOrInterests: _selectedInterests.toList(),
        title: _titleCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        hourlyRate: rate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding completed! Welcome to Ymentor.')),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isMentor = user?.isMentor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.mint.withValues(alpha: 0.2),
                      child: Icon(
                        isMentor ? Icons.school : Icons.person_search,
                        color: AppColors.mint,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? 'Scholar'}!',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMentor
                                ? 'Set up your mentorship specialties & rates.'
                                : 'Select your faculty and what you want to learn.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Faculty Selection
              const Text('Academic Faculty / Department',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedFaculty,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance, color: AppColors.textSecondary),
                ),
                items: kFacultyOptions
                    .map((fac) => DropdownMenuItem(
                          value: fac,
                          child: Text(fac, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFaculty = val);
                },
              ),

              const SizedBox(height: 24),

              // Learning / Specialization Interests
              Text(
                isMentor ? 'Mentorship Specializations' : 'Learning Interests',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select topics matching your focus areas:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kInterestChips.map((chip) {
                  final selected = _selectedInterests.contains(chip);
                  return FilterChip(
                    label: Text(chip),
                    selected: selected,
                    selectedColor: AppColors.mint,
                    checkmarkColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.background : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedInterests.add(chip);
                        } else {
                          _selectedInterests.remove(chip);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Professional Title
              Text(
                isMentor ? 'Professional Title / Role' : 'Current Status / Degree',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: isMentor ? 'e.g. Senior AI Engineer' : 'e.g. CS Sophomore @ Stanford',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                ),
              ),

              if (isMentor) ...[
                const SizedBox(height: 20),
                const Text('Base Hourly Mentorship Rate (USD \$)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _hourlyRateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.mint),
                    hintText: '20',
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Bio
              const Text('Short Bio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isMentor
                      ? 'Describe your background, real-world systems, and how you help mentees...'
                      : 'Tell mentors about your learning objectives and goals...',
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Complete Onboarding & Enter Ymentor'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
