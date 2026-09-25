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
      degree: json['degree'] ?? '',
      faculty: json['faculty'] ?? '',
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      githubUrl: json['githubUrl'] ?? '',
      linkedinUrl: json['linkedinUrl'] ?? '',
    );
  }
}

class PricingTiers {
  final double tier30m;
  final double tier60m;
  final double tier120m;

  PricingTiers({this.tier30m = 12.0, this.tier60m = 20.0, this.tier120m = 38.0});

  factory PricingTiers.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PricingTiers();
    return PricingTiers(
      tier30m: (json['tier30m'] ?? 12.0).toDouble(),
      tier60m: (json['tier60m'] ?? 20.0).toDouble(),
      tier120m: (json['tier120m'] ?? 38.0).toDouble(),
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
  final String role; // 'mentee' or 'mentor'
  final String avatarUrl;
  final String headline;
  final String bio;
  final bool isIdentityVerified;
  final bool isSkillVerified;
  final Qualifications qualifications;
  final PricingTiers pricingTiers;
  final String meetingUrl;
  final double ratingAvg;
  final int totalSessions;
  final double leaderboardScore;
  final double walletBalance;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    this.headline = '',
    this.bio = '',
    this.isIdentityVerified = false,
    this.isSkillVerified = false,
    Qualifications? qualifications,
    PricingTiers? pricingTiers,
    this.meetingUrl = '',
    this.ratingAvg = 5.0,
    this.totalSessions = 0,
    this.leaderboardScore = 0.0,
    this.walletBalance = 0.0,
  })  : qualifications = qualifications ?? Qualifications(),
        pricingTiers = pricingTiers ?? PricingTiers();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'mentee',
      avatarUrl: json['avatarUrl'] ?? '',
      headline: json['headline'] ?? '',
      bio: json['bio'] ?? '',
      isIdentityVerified: json['isIdentityVerified'] ?? false,
      isSkillVerified: json['isSkillVerified'] ?? false,
      qualifications: Qualifications.fromJson(json['qualifications']),
      pricingTiers: PricingTiers.fromJson(json['pricingTiers']),
      meetingUrl: json['meetingUrl'] ?? '',
      ratingAvg: (json['ratingAvg'] ?? 5.0).toDouble(),
      totalSessions: json['totalSessions'] ?? 0,
      leaderboardScore: (json['leaderboardScore'] ?? 0.0).toDouble(),
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
    );
  }

  bool get isMentor => role == 'mentor';
}
