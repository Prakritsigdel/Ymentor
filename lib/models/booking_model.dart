class BookingFinancials {
  final double grossAmount;
  final double platformCommission20Percent;
  final double mentorNetPayout80Percent;
  final String escrowStatus; // HELD, RELEASED, REFUNDED

  BookingFinancials({
    required this.grossAmount,
    required this.platformCommission20Percent,
    required this.mentorNetPayout80Percent,
    required this.escrowStatus,
  });

  factory BookingFinancials.fromJson(Map<String, dynamic> json) {
    return BookingFinancials(
      grossAmount: (json['grossAmount'] ?? 0).toDouble(),
      platformCommission20Percent: (json['platformCommission20Percent'] ?? 0).toDouble(),
      mentorNetPayout80Percent: (json['mentorNetPayout80Percent'] ?? 0).toDouble(),
      escrowStatus: json['escrowStatus'] ?? 'HELD',
    );
  }
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
    required this.financials,
    required this.status,
  });

  static String _idOf(dynamic field) {
    if (field == null) return '';
    if (field is Map) return (field['_id'] ?? '').toString();
    return field.toString();
  }

  static String? _nameOf(dynamic field) {
    if (field is Map) return field['name'];
    return null;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: (json['_id'] ?? '').toString(),
      menteeId: _idOf(json['menteeId']),
      mentorId: _idOf(json['mentorId']),
      mentorName: _nameOf(json['mentorId']),
      menteeName: _nameOf(json['menteeId']),
      durationMinutes: json['durationMinutes'] ?? 30,
      scheduledTime: DateTime.tryParse(json['scheduledTime']?.toString() ?? '') ?? DateTime.now(),
      meetingUrl: json['meetingUrl'] ?? '',
      financials: BookingFinancials.fromJson(json['financials'] ?? {}),
      status: json['status'] ?? 'CONFIRMED',
    );
  }
}
