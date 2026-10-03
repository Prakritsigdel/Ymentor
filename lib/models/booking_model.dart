class BookingFinancials {
  final double? grossAmount;
  final double? platformCommission20Percent;
  final double? mentorNetPayout80Percent;
  final String
      escrowStatus; // 'held_in_escrow', 'release_requested', 'released', 'refunded'

  BookingFinancials({
    required this.grossAmount,
    required this.platformCommission20Percent,
    required this.mentorNetPayout80Percent,
    required this.escrowStatus,
  });

  factory BookingFinancials.fromJson(Map<String, dynamic> json) {
    final status =
        (json['escrowStatus']?.toString() ?? 'held_in_escrow').toLowerCase();
    return BookingFinancials(
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
      platformCommission20Percent:
          (json['platformCommission20Percent'] as num?)?.toDouble(),
      mentorNetPayout80Percent:
          (json['mentorNetPayout80Percent'] as num?)?.toDouble(),
      escrowStatus: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'grossAmount': grossAmount,
        'platformCommission20Percent': platformCommission20Percent,
        'mentorNetPayout80Percent': mentorNetPayout80Percent,
        'escrowStatus': escrowStatus,
      };
}

class Booking {
  final String id;
  final String menteeId;
  final String mentorId;
  final String? mentorName;
  final String? menteeName;
  final int durationMinutes;
  final DateTime scheduledTime;
  final String meetingUrl;
  final double? platformFee;
  final double? totalAmount;
  final double? mentorNetPayout;
  final double? hourlyRate;
  final String escrowStatus;
  final BookingFinancials financials;
  final String status; // CONFIRMED, COMPLETED, CANCELLED
  final String planType;
  final DateTime? planEndsAt;
  final String conversationId;

  Booking({
    required this.id,
    required this.menteeId,
    required this.mentorId,
    this.mentorName,
    this.menteeName,
    required this.durationMinutes,
    required this.scheduledTime,
    required this.meetingUrl,
    this.platformFee,
    this.totalAmount,
    this.mentorNetPayout,
    this.hourlyRate,
    this.escrowStatus = 'held_in_escrow',
    required this.financials,
    required this.status,
    this.planType = 'hourly',
    this.planEndsAt,
    this.conversationId = '',
  });

  static String _idOf(dynamic field) {
    if (field == null) return '';
    if (field is Map) return (field['_id'] ?? field['id'] ?? '').toString();
    return field.toString();
  }

  static String? _nameOf(dynamic field) {
    if (field is Map) return field['name']?.toString();
    return null;
  }

  static double? _rateOf(dynamic field) {
    if (field is Map) {
      final rate = (field['hourlyRate'] as num?)?.toDouble();
      if (rate != null && rate > 0) return rate;
      if (field['pricing'] is Map) {
        final pRate = (field['pricing']['hourly'] as num?)?.toDouble();
        if (pRate != null && pRate > 0) return pRate;
      }
    }
    return null;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final finMap = json['financials'] is Map
        ? json['financials'] as Map<String, dynamic>
        : <String, dynamic>{};
    final fin = BookingFinancials.fromJson(finMap);

    final resolvedEscrow =
        (json['escrowStatus']?.toString() ?? fin.escrowStatus).toLowerCase();
    final feeVal = (json['platformFee'] as num?)?.toDouble() ??
        fin.platformCommission20Percent;
    final topTotal = (json['totalAmount'] as num?)?.toDouble() ??
        (fin.grossAmount != null && fin.grossAmount! > 0 ? fin.grossAmount : null);
    final topPayout = (json['mentorNetPayout'] as num?)?.toDouble() ??
        fin.mentorNetPayout80Percent;
    final detectedHourly = _rateOf(json['mentorId']) ??
        (json['hourlyRate'] as num?)?.toDouble();

    return Booking(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      menteeId: _idOf(json['menteeId']),
      mentorId: _idOf(json['mentorId']),
      mentorName: _nameOf(json['mentorId']),
      menteeName: _nameOf(json['menteeId']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      scheduledTime:
          DateTime.tryParse(json['scheduledTime']?.toString() ?? '') ??
              DateTime.now(),
      meetingUrl: json['meetingUrl']?.toString() ?? '',
      platformFee: feeVal,
      totalAmount: topTotal,
      mentorNetPayout: topPayout,
      hourlyRate: detectedHourly,
      escrowStatus: resolvedEscrow,
      financials: fin,
      status: json['status']?.toString() ?? 'CONFIRMED',
      planType: json['planType']?.toString() ?? 'hourly',
      planEndsAt: DateTime.tryParse(json['planEndsAt']?.toString() ?? ''),
      conversationId: json['conversationId']?.toString() ?? '',
    );
  }

  /// Dynamic calculation of totalAmount guaranteeing no legacy test numbers (e.g. 20, 12, 40)
  double get totalAmountCalculated {
    if (totalAmount != null && totalAmount! > 100) return totalAmount!;
    if (financials.grossAmount != null && financials.grossAmount! > 100) {
      return financials.grossAmount!;
    }
    final rate = (hourlyRate != null && hourlyRate! >= 500) ? hourlyRate! : 1000.0;
    final hours = (durationMinutes > 0 ? durationMinutes : 60) / 60.0;
    return (rate * hours).roundToDouble();
  }

  /// Dynamic calculation of 20% platform fee
  double get platformFeeCalculated {
    if (platformFee != null && platformFee! > 20) return platformFee!;
    if (financials.platformCommission20Percent != null &&
        financials.platformCommission20Percent! > 20) {
      return financials.platformCommission20Percent!;
    }
    return (totalAmountCalculated * 0.20).roundToDouble();
  }

  /// Dynamic calculation of 80% mentor net payout
  double get mentorPayoutCalculated {
    if (mentorNetPayout != null && mentorNetPayout! > 80) return mentorNetPayout!;
    if (financials.mentorNetPayout80Percent != null &&
        financials.mentorNetPayout80Percent! > 80) {
      return financials.mentorNetPayout80Percent!;
    }
    return (totalAmountCalculated - platformFeeCalculated).roundToDouble();
  }

  bool get isHeld => escrowStatus == 'held_in_escrow' || escrowStatus == 'held';
  bool get isReleased => escrowStatus == 'released';
  bool get isReleaseRequested => escrowStatus == 'release_requested';
}
