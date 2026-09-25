import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/workspace_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  List<Workspace> _workspaces = [];
  Workspace? _selected;
  List<Note> _notes = [];
  bool _loadingWorkspaces = true;
  bool _loadingNotes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkspaces());
  }

  Future<void> _loadWorkspaces() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _loadingWorkspaces = false);
      return;
    }
    setState(() => _loadingWorkspaces = true);
    try {
      final ws = await ApiService.getUserWorkspaces(user.id);
      setState(() {
        _workspaces = ws;
        _selected = ws.isNotEmpty ? ws.first : null;
      });
      if (_selected != null) await _loadNotes();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingWorkspaces = false);
    }
  }

  Future<void> _loadNotes() async {
    if (_selected == null) return;
    setState(() => _loadingNotes = true);
    try {
      final notes = await ApiService.getWorkspaceNotes(_selected!.id);
      setState(() => _notes = notes);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    final url = pdfUrl.startsWith('http') ? pdfUrl : '${ApiConfig.baseUrl}$pdfUrl';
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleNote(Note note) async {
    try {
      await ApiService.toggleNote(note.id);
      _loadNotes();
    } catch (_) {}
  }

  Future<void> _addComment(Note note) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Ask a question'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Type your message...')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Post')),
        ],
      ),
    );
    if (message == null || message.isEmpty) return;
    try {
      await ApiService.postComment(noteId: note.id, senderId: user.id, senderName: '${user.name} (${user.role})', message: message);
      _loadNotes();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const Center(child: Text('Log in to see your workspaces.', style: TextStyle(color: AppColors.textSecondary)));
    }
    if (_loadingWorkspaces) return const Center(child: CircularProgressIndicator());
    if (_workspaces.isEmpty) {
      return const Center(child: Text('No active workspaces yet. Book a session to start one.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<Workspace>(
            initialValue: _selected,
            dropdownColor: AppColors.surface,
            decoration: const InputDecoration(labelText: 'Classroom workspace'),
            items: _workspaces
                .map((w) => DropdownMenuItem(value: w, child: Text(w.topic, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (w) {
              setState(() => _selected = w);
              _loadNotes();
            },
          ),
        ),
        Expanded(
          child: _loadingNotes
              ? const Center(child: CircularProgressIndicator())
              : _notes.isEmpty
                  ? const Center(child: Text('No assignments yet.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _notes.length,
                      itemBuilder: (context, i) => _NoteCard(
                        note: _notes[i],
                        onOpenPdf: () => _openPdf(_notes[i].pdfUrl),
                        onToggle: () => _toggleNote(_notes[i]),
                        onComment: () => _addComment(_notes[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onOpenPdf;
  final VoidCallback onToggle;
  final VoidCallback onComment;

  const _NoteCard({required this.note, required this.onOpenPdf, required this.onToggle, required this.onComment});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(value: note.isCompleted, onChanged: (_) => widget.onToggle(), activeColor: AppColors.mint),
                Expanded(
                  child: Text(note.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                          color: note.isCompleted ? AppColors.textSecondary : AppColors.textPrimary)),
                ),
              ],
            ),
            if (note.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 2),
                child: Text(note.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 6),
              child: Text('Due: ${note.dueDate}', style: const TextStyle(color: AppColors.star, fontSize: 12)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onOpenPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('View PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(_expanded ? Icons.expand_less : Icons.chat_bubble_outline, size: 18),
                    label: Text('${note.comments.length} comments'),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 24, color: AppColors.border),
              ...note.comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.senderName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(c.message, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onComment,
                  icon: const Icon(Icons.add_comment, size: 16),
                  label: const Text('Reply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
