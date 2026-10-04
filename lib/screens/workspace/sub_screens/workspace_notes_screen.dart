import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../models/workspace_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';

class WorkspaceNotesScreen extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceNotesScreen({super.key, required this.workspace});

  @override
  State<WorkspaceNotesScreen> createState() => _WorkspaceNotesScreenState();
}

class _WorkspaceNotesScreenState extends State<WorkspaceNotesScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (mounted) setState(() => _loading = true);
    try {
      final notes = await ApiService.getWorkspaceNotes(widget.workspace.id);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _error = null;
        _loading = false;
      });
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load workspace documents: $err';
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleNote(Note note) async {
    try {
      await ApiService.toggleNote(note.id);
      await _loadNotes();
    } catch (error) {
      if (mounted) {
        _showSnackBar('Unable to update assignment: $error');
      }
    }
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
            hintText: 'Type your question or response...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Post'),
          ),
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
      await _loadNotes();
    } catch (error) {
      if (mounted) {
        _showSnackBar('Unable to post reply: $error');
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    final url =
        pdfUrl.startsWith('http') ? pdfUrl : '${ApiConfig.baseUrl}$pdfUrl';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showSnackBar('This document link is not available.');
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showSnackBar('No PDF viewer is available on this device.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not launch PDF viewer: $e');
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
              const Text(
                'Document Preview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '.pdf',
                      style: TextStyle(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      filename,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
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

  Future<void> _showAddNoteDialog() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final dueController = TextEditingController();
    File? pickedFile;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Note or Code Snippet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Flutter Architecture Notes',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content or Code *',
                    hintText: 'Paste code snippets or describe tasks...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date (Optional)',
                    hintText: 'e.g. Tomorrow 5 PM',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );
                        final p = result?.files.single.path;
                        if (p != null) {
                          setDialogState(() => pickedFile = File(p));
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(pickedFile != null
                          ? 'PDF Attached'
                          : 'Attach PDF (Optional)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final desc = descController.text.trim();
                if (title.isEmpty) {
                  _showSnackBar('Please enter a title');
                  return;
                }
                Navigator.of(dialogCtx).pop();

                try {
                  await ApiService.uploadNote(
                    workspaceId: widget.workspace.id,
                    uploadedBy: user.id,
                    title: title,
                    description: desc.isNotEmpty ? desc : null,
                    dueDate: dueController.text.trim().isNotEmpty
                        ? dueController.text.trim()
                        : null,
                    pdfFile: pickedFile,
                  );
                  _showSnackBar('Note added successfully');
                  await _loadNotes();
                } catch (e) {
                  _showSnackBar('Failed to add note: $e');
                }
              },
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descController.dispose();
    dueController.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadNotes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Note', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotes,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppColors.danger),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadNotes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _notes.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.code,
                                  size: 56, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'No notes or code snippets yet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap "+ Add Note" below to create the first shared note.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return _NoteCardWidget(
                              note: note,
                              onOpenPdf: () => _previewPdf(note),
                              onToggle: () => _toggleNote(note),
                              onComment: () => _addComment(note),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _NoteCardWidget extends StatefulWidget {
  final Note note;
  final VoidCallback onOpenPdf;
  final VoidCallback onToggle;
  final VoidCallback onComment;

  const _NoteCardWidget({
    required this.note,
    required this.onOpenPdf,
    required this.onToggle,
    required this.onComment,
  });

  @override
  State<_NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends State<_NoteCardWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                child: Text(
                  note.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            if (note.dueDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 14, color: AppColors.star),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${note.dueDate}',
                      style: const TextStyle(
                          color: AppColors.star, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (note.pdfUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
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
                          fontWeight: FontWeight.w800,
                        ),
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
                      size: 18,
                    ),
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
                  child: Text(
                    'No comments yet. Start the thread below!',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.mint,
                                  ),
                                ),
                                Text(
                                  '${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.message, style: const TextStyle(fontSize: 13)),
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
