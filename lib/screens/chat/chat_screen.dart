import 'package:flutter/material.dart';
import '../../widgets/monthly_chat_screen.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) =>
      MonthlyChatScreen(conversationId: conversationId);
}
