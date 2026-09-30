import 'package:flutter/material.dart';
import 'mentor_profile_screen.dart';

Future<void> showMentorProfileSheet(BuildContext context, String mentorId) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => MentorProfileScreen(mentorId: mentorId),
    ),
  );
}
