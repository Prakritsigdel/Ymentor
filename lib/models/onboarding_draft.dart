import 'package:flutter/material.dart';

class MentorOnboardingDraft {
  final legalName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final headline = TextEditingController(text: 'Lead Mobile Architect');
  final dateOfBirth = TextEditingController();
  final location = TextEditingController();
  final timezone = TextEditingController();
  final avatarUrl = TextEditingController();
  final primaryDomain = TextEditingController(text: 'Mobile Development');
  final subSkills = TextEditingController();
  final yearsExperience = TextEditingController();
  final currentRole = TextEditingController(text: 'Senior / Staff Engineer');
  final customRole = TextEditingController();
  final organization = TextEditingController();
  final bio = TextEditingController();
  final linkedinUrl = TextEditingController();
  final portfolioUrl = TextEditingController();
  final highestDegree = TextEditingController();
  final hourlyRate = TextEditingController(text: '2000');
  final monthlyRate = TextEditingController(text: '8000');
  final maxMentees = TextEditingController(text: '3');
  final weeklyHours = TextEditingController(text: '5');
  final languages = TextEditingController(text: 'English');
  String governmentIdType = 'Passport';
  String headlineSelection = 'Lead Mobile Architect';
  String primaryDomainSelection = 'Mobile Development';
  String currentRoleSelection = 'Senior / Staff Engineer';
  List<String> selectedSubSkills = [];
  String hourlyRateTier = 'NPR 1,500 – NPR 3,500 / hr';
  String monthlyRateTier = 'NPR 6,000 – NPR 8,000 / month';

  void dispose() {
    for (final controller in [
      legalName,
      email,
      password,
      headline,
      dateOfBirth,
      location,
      timezone,
      avatarUrl,
      primaryDomain,
      subSkills,
      yearsExperience,
      currentRole,
      customRole,
      organization,
      bio,
      linkedinUrl,
      portfolioUrl,
      highestDegree,
      hourlyRate,
      monthlyRate,
      maxMentees,
      weeklyHours,
      languages,
    ]) {
      controller.dispose();
    }
  }
}

class MenteeOnboardingDraft {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final fieldOfInterest = TextEditingController();
  final primaryGoal = TextEditingController();
  final targetSkills = TextEditingController();
  final targetBudget = TextEditingController();
  final weeklyHours = TextEditingController();
  String academicStatus = 'Undergraduate (1st/2nd Year)';
  String primaryGoalSelection = 'Land First Tech Job';
  List<String> selectedTargetSkills = [];
  String targetBudgetTier = 'NPR 6,000 – NPR 8,000 / month';
  String competencyLevel = 'Beginner';
  String preferredMode = 'Not Sure';
  String mentorStyle = 'Hands-on';

  void dispose() {
    for (final controller in [
      name,
      email,
      password,
      fieldOfInterest,
      primaryGoal,
      targetSkills,
      targetBudget,
      weeklyHours,
    ]) {
      controller.dispose();
    }
  }
}
