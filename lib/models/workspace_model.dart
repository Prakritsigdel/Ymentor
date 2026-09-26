class WorkspaceParty {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  WorkspaceParty({required this.id, required this.name, this.email = '', this.avatarUrl = ''});

  factory WorkspaceParty.fromDynamic(dynamic field) {
    if (field is Map) {
      return WorkspaceParty(
        id: (field['_id'] ?? '').toString(),
        name: field['name'] ?? 'User',
        email: field['email'] ?? '',
        avatarUrl: field['avatarUrl'] ?? '',
      );
    }
    return WorkspaceParty(id: field?.toString() ?? '', name: 'User');
  }
}

class Workspace {
  final String id;
  final WorkspaceParty mentor;
  final WorkspaceParty mentee;
  final String topic;

  Workspace({required this.id, required this.mentor, required this.mentee, required this.topic});

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: (json['_id'] ?? '').toString(),
      mentor: WorkspaceParty.fromDynamic(json['mentorId']),
      mentee: WorkspaceParty.fromDynamic(json['menteeId']),
      topic: json['topic'] ?? 'Workspace',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workspace && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class NoteComment {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  NoteComment({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory NoteComment.fromJson(Map<String, dynamic> json) {
    return NoteComment(
      id: (json['_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderName: json['senderName'] ?? 'User',
      message: json['message'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Note {
  final String id;
  final String workspaceId;
  final String title;
  final String description;
  final String dueDate;
  final String pdfUrl;
  final bool isCompleted;
  final List<NoteComment> comments;

  Note({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.pdfUrl,
    required this.isCompleted,
    required this.comments,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: (json['_id'] ?? '').toString(),
      workspaceId: (json['workspaceId'] ?? '').toString(),
      title: json['title'] ?? 'Assignment',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      comments: (json['comments'] as List? ?? [])
          .map((c) => NoteComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
