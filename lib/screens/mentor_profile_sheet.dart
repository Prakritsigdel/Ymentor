import 'package:flutter/material.dart';
import 'mentor_profile_screen.dart';

Future<void> showMentorProfileSheet(BuildContext context, String mentorId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.96,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: MentorProfileScreen(mentorId: mentorId),
      ),
    ),
  );
}
