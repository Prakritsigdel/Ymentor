class ChatConversation {
  final String id;
  final String bookingId;
  final String mentorId;
  final String menteeId;
  final DateTime? lastMessageAt;

  const ChatConversation({
    required this.id,
    required this.bookingId,
    required this.mentorId,
    required this.menteeId,
    this.lastMessageAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      bookingId: (json['bookingId'] ?? '').toString(),
      mentorId: (json['mentorId'] ?? '').toString(),
      menteeId: (json['menteeId'] ?? '').toString(),
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'bookingId': bookingId,
        'mentorId': mentorId,
        'menteeId': menteeId,
        if (lastMessageAt != null)
          'lastMessageAt': lastMessageAt!.toIso8601String(),
      };
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String attachmentUrl;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.attachmentUrl = '',
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      text: json['text']?.toString() ?? '',
      attachmentUrl: json['attachmentUrl']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'attachmentUrl': attachmentUrl,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
