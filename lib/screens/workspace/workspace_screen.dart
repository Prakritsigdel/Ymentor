import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/workspace_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/brand_footer.dart';

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
      if (!mounted) return;

      final selectedId = _selected?.id;
      Workspace? refreshedSelection;
      for (final workspace in ws) {
        if (workspace.id == selectedId) {
          refreshedSelection = workspace;
          break;
        }
      }

      setState(() {
        _workspaces = ws;
        _selected = refreshedSelection ?? (ws.isNotEmpty ? ws.first : null);
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
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    final url =
        pdfUrl.startsWith('http') ? pdfUrl : '${ApiConfig.baseUrl}$pdfUrl';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This document link is not available.')),
      );
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No PDF viewer is available on this device.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch PDF viewer: $e')),
      );
    }
  }

  Future<void> _previewPdf(Note note) async {
    final uri = Uri.tryParse(note.pdfUrl);
    final filename = uri != null && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'Attached document.pdf';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Document preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('.pdf',
                        style: TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(filename,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Your document will open in the device PDF viewer.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openPdf(note.pdfUrl);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: const Text('Post Classroom Reply'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Type your question or response...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Post')),
        ],
      ),
    );

    if (message == null || message.isEmpty) return;

    try {
      await ApiService.postComment(
        noteId: note.id,
        senderId: user.id,
        senderName: '${user.name} (${user.roleDisplayName})',
        message: message,
      );
      _loadNotes();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PDF Workspace',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadWorkspaces,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (!auth.isLoggedIn)
                  const _WorkspaceMessage(
                    icon: Icons.lock_outline,
                    message: 'Log in to see your classroom workspaces.',
                  )
                else if (_loadingWorkspaces)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_workspaces.isEmpty)
                  const _WorkspaceMessage(
                    icon: Icons.folder_open,
                    message:
                        'No active classroom workspaces yet.\nBook a mentorship session to automatically launch your shared workspace.',
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<Workspace>(
                      initialValue: _selected,
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Active Classroom Workspace',
                        prefixIcon:
                            Icon(Icons.school_outlined, color: AppColors.mint),
                      ),
                      items: _workspaces
                          .map((workspace) => DropdownMenuItem(
                                value: workspace,
                                child: Text(
                                  workspace.topic,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                      onChanged: (workspace) {
                        setState(() => _selected = workspace);
                        _loadNotes();
                      },
                    ),
                  ),
                  if (_loadingNotes)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_notes.isEmpty)
                    const _WorkspaceMessage(
                      icon: Icons.assignment_outlined,
                      message: 'No assignments attached to this workspace yet.',
                    )
                  else
                    ..._notes.map(
                      (note) => _NoteCard(
                        note: note,
                        onOpenPdf: () => _previewPdf(note),
                        onToggle: () => _toggleNote(note),
                        onComment: () => _addComment(note),
                      ),
                    ),
                ],
                const BrandFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _WorkspaceMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onOpenPdf;
  final VoidCallback onToggle;
  final VoidCallback onComment;

  const _NoteCard({
    required this.note,
    required this.onOpenPdf,
    required this.onToggle,
    required this.onComment,
  });

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
                Checkbox(
                  value: note.isCompleted,
                  onChanged: (_) => widget.onToggle(),
                  activeColor: AppColors.mint,
                ),
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration:
                          note.isCompleted ? TextDecoration.lineThrough : null,
                      color: note.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (note.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 2),
                child: Text(note.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            if (note.dueDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 14, color: AppColors.star),
                    const SizedBox(width: 4),
                    Text('Due: ${note.dueDate}',
                        style: const TextStyle(
                            color: AppColors.star, fontSize: 12)),
                  ],
                ),
              ),
            if (note.pdfUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '.pdf',
                        style: TextStyle(
                            color: AppColors.terracotta,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pdfFilename(note.pdfUrl),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: AppColors.mint, size: 18),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (note.pdfUrl.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onOpenPdf,
                      icon: const Icon(Icons.picture_as_pdf,
                          size: 18, color: AppColors.terracotta),
                      label: const Text('Preview PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.chat_bubble_outline,
                        size: 18),
                    label: Text('${note.comments.length} comments'),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(height: 24, color: AppColors.border),
              if (note.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No comments yet. Start the thread below!',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                )
              else
                ...note.comments.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(c.senderName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.mint)),
                                Text(
                                  '${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.message,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    )),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onComment,
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply to Assignment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _pdfFilename(String pdfUrl) {
    final path = Uri.tryParse(pdfUrl)?.pathSegments;
    return path != null && path.isNotEmpty ? path.last : 'Attached document';
  }
}
