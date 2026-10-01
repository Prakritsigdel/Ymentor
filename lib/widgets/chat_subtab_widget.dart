import 'package:flutter/material.dart';
import 'monthly_chat_screen.dart';

class ChatSubtabWidget extends StatelessWidget {
  final String workspaceId;

  const ChatSubtabWidget({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context) {
    return MonthlyChatScreen(conversationId: workspaceId);
  }
}
