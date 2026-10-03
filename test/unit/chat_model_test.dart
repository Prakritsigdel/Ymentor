import 'package:flutter_test/flutter_test.dart';
import 'package:ymentor/models/chat_model.dart';

void main() {
  test('serializes and restores chat conversation', () {
    final source = ChatConversation(
      id: 'conversation-1',
      bookingId: 'booking-1',
      mentorId: 'mentor-1',
      menteeId: 'mentee-1',
    );
    final restored = ChatConversation.fromJson(source.toJson());
    expect(restored.id, source.id);
    expect(restored.bookingId, source.bookingId);
    expect(restored.mentorId, source.mentorId);
    expect(restored.menteeId, source.menteeId);
  });

  test('serializes and restores chat message', () {
    final source = ChatMessage(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'mentor-1',
      text: 'Hello',
      attachmentUrl: '/uploads/file.pdf',
    );
    final restored = ChatMessage.fromJson(source.toJson());
    expect(restored.id, source.id);
    expect(restored.text, source.text);
    expect(restored.attachmentUrl, source.attachmentUrl);
  });
}
