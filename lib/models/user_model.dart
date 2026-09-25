class Qualifications {
  final String degree;
  final String faculty;
  final List<String> skills;
  final String githubUrl;
  final String linkedinUrl;

  Qualifications({
    this.degree = '',
    this.faculty = '',
    this.skills = const [],
    this.githubUrl = '',
    this.linkedinUrl = '',
  });

  factory Qualifications.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Qualifications();
    return Qualifications(
      degree: json['degree']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      githubUrl: json['githubUrl']?.toString() ?? '',
      linkedinUrl: json['linkedinUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'faculty': faculty,
        'skills': skills,
        'githubUrl': githubUrl,
        'linkedinUrl': linkedinUrl,
      };
}

class PricingTiers {
  final double tier30m;
  final double tier60m;
  final double tier120m;

  PricingTiers({this.tier30m = 12.0, this.tier60m = 20.0, this.tier120m = 38.0});

  factory PricingTiers.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PricingTiers();
    return PricingTiers(
      tier30m: (json['tier30m'] as num?)?.toDouble() ?? 12.0,
      tier60m: (json['tier60m'] as num?)?.toDouble() ?? 20.0,
      tier120m: (json['tier120m'] as num?)?.toDouble() ?? 38.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'tier30m': tier30m,
        'tier60m': tier60m,
        'tier120m': tier120m,
      };

  double priceFor(int minutes) {
    switch (minutes) {
      case 30:
        return tier30m;
      case 60:
        return tier60m;
      case 120:
        return tier120m;
      default:
        return tier30m;
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'mentor', 'mentee'
  final String status; // 'active', 'pending_approval', 'suspended'
  final String faculty;
  final List<String> skillsOrInterests;
  final String title;
  final String bio;
  final double hourlyRate;
  final bool isOnboarded;
  final String avatarUrl;
  final String headline;
  final bool isIdentityVerified;
  final bool isSkillVerified;
  final Qualifications qualifications;
  final PricingTiers pricingTiers;
  final String meetingUrl;
  final double ratingAvg;
  final int totalSessions;
  final double leaderboardScore;
  final double walletBalance;
  final double pendingEscrow;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'active',
    this.faculty = '',
    this.skillsOrInterests = const [],
    this.title = '',
    this.bio = '',
    this.hourlyRate = 20.0,
    this.isOnboarded = false,
    this.avatarUrl = '',
    this.headline = '',
    this.isIdentityVerified = false,
    this.isSkillVerified = false,
    Qualifications? qualifications,
    PricingTiers? pricingTiers,
    this.meetingUrl = '',
    this.ratingAvg = 5.0,
    this.totalSessions = 0,
    this.leaderboardScore = 0.0,
    this.walletBalance = 0.0,
    this.pendingEscrow = 0.0,
  })  : qualifications = qualifications ?? Qualifications(),
        pricingTiers = pricingTiers ?? PricingTiers();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] is Map ? json['wallet'] as Map<String, dynamic> : null;
    final balanceVal = wallet != null
        ? (wallet['balance'] as num?)?.toDouble()
        : (json['walletBalance'] as num?)?.toDouble();
    final escrowVal = wallet != null ? (wallet['pendingEscrow'] as num?)?.toDouble() : 0.0;

    // Resolve skills
    final skillsRaw = json['skillsOrInterests'] as List? ??
        (json['qualifications'] is Map ? json['qualifications']['skills'] as List? : null);
    final parsedSkills = skillsRaw?.map((e) => e.toString()).toList() ?? [];

    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: (json['role']?.toString() ?? 'mentee').toLowerCase(),
      status: (json['status']?.toString() ?? 'active').toLowerCase(),
      faculty: json['faculty']?.toString() ??
          (json['qualifications'] is Map ? json['qualifications']['faculty']?.toString() ?? '' : ''),
      skillsOrInterests: parsedSkills,
      title: json['title']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 20.0,
      isOnboarded: json['isOnboarded'] == true,
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      isIdentityVerified: json['isIdentityVerified'] == true,
      isSkillVerified: json['isSkillVerified'] == true,
      qualifications: Qualifications.fromJson(json['qualifications'] as Map<String, dynamic>?),
      pricingTiers: PricingTiers.fromJson(json['pricingTiers'] as Map<String, dynamic>?),
      meetingUrl: json['meetingUrl']?.toString() ?? '',
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 5.0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      leaderboardScore: (json['leaderboardScore'] as num?)?.toDouble() ?? 0.0,
      walletBalance: balanceVal ?? 0.0,
      pendingEscrow: escrowVal ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'role': role,
        'status': status,
        'faculty': faculty,
        'skillsOrInterests': skillsOrInterests,
        'title': title,
        'bio': bio,
        'hourlyRate': hourlyRate,
        'isOnboarded': isOnboarded,
        'avatarUrl': avatarUrl,
        'headline': headline,
        'isIdentityVerified': isIdentityVerified,
        'isSkillVerified': isSkillVerified,
        'qualifications': qualifications.toJson(),
        'pricingTiers': pricingTiers.toJson(),
        'meetingUrl': meetingUrl,
        'ratingAvg': ratingAvg,
        'totalSessions': totalSessions,
        'leaderboardScore': leaderboardScore,
        'walletBalance': walletBalance,
        'wallet': {
          'balance': walletBalance,
          'pendingEscrow': pendingEscrow,
        },
      };

  bool get isAdmin => role == 'admin';
  bool get isMentor => role == 'mentor';
  bool get isMentee => role == 'mentee';

  bool get isActive => status == 'active';
  bool get isPendingApproval => status == 'pending_approval';
  bool get isSuspended => status == 'suspended';

  String get roleDisplayName {
    if (isAdmin) return 'Admin';
    if (isMentor) return 'Mentor';
    return 'Mentee';
  }

  String get roleBadgeLabel {
    if (isAdmin) return '[ADMIN]';
    if (isMentor) return '[MENTOR]';
    return '[MENTEE]';
  }

  String get statusBadgeLabel {
    if (isSuspended) return '[SUSPENDED]';
    if (isPendingApproval) return '[PENDING APPROVAL]';
    return '[ACTIVE]';
  }
}
