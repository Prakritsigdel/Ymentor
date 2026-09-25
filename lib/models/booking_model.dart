class BookingFinancials {
  final double grossAmount;
  final double platformCommission20Percent;
  final double mentorNetPayout80Percent;
  final String escrowStatus; // 'held_in_escrow', 'release_requested', 'released', 'refunded'

  BookingFinancials({
    required this.grossAmount,
    required this.platformCommission20Percent,
    required this.mentorNetPayout80Percent,
    required this.escrowStatus,
  });

  factory BookingFinancials.fromJson(Map<String, dynamic> json) {
    final status = (json['escrowStatus']?.toString() ?? 'held_in_escrow').toLowerCase();
    return BookingFinancials(
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
      platformCommission20Percent:
          (json['platformCommission20Percent'] as num?)?.toDouble() ?? 4.0,
      mentorNetPayout80Percent:
          (json['mentorNetPayout80Percent'] as num?)?.toDouble() ?? 16.0,
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
  final double platformFee;
  final String escrowStatus;
  final BookingFinancials financials;
  final String status; // CONFIRMED, COMPLETED, CANCELLED

  Booking({
    required this.id,
    required this.menteeId,
    required this.mentorId,
    this.mentorName,
    this.menteeName,
    required this.durationMinutes,
    required this.scheduledTime,
    required this.meetingUrl,
    this.platformFee = 4.0,
    this.escrowStatus = 'held_in_escrow',
    required this.financials,
    required this.status,
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

  factory Booking.fromJson(Map<String, dynamic> json) {
    final finMap = json['financials'] is Map ? json['financials'] as Map<String, dynamic> : <String, dynamic>{};
    final fin = BookingFinancials.fromJson(finMap);

    final resolvedEscrow = (json['escrowStatus']?.toString() ?? fin.escrowStatus).toLowerCase();
    final feeVal = (json['platformFee'] as num?)?.toDouble() ?? fin.platformCommission20Percent;

    return Booking(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      menteeId: _idOf(json['menteeId']),
      mentorId: _idOf(json['mentorId']),
      mentorName: _nameOf(json['mentorId']),
      menteeName: _nameOf(json['menteeId']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      scheduledTime: DateTime.tryParse(json['scheduledTime']?.toString() ?? '') ?? DateTime.now(),
      meetingUrl: json['meetingUrl']?.toString() ?? 'https://meet.google.com/abc-defg-hij',
      platformFee: feeVal,
      escrowStatus: resolvedEscrow,
      financials: fin,
      status: json['status']?.toString() ?? 'CONFIRMED',
    );
  }

  bool get isHeld => escrowStatus == 'held_in_escrow' || escrowStatus == 'held';
  bool get isReleased => escrowStatus == 'released';
  bool get isReleaseRequested => escrowStatus == 'release_requested';
}
