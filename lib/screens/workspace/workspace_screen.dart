import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
import 'video_call_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with SingleTickerProviderStateMixin {
  List<Workspace> _workspaces = [];
  Workspace? _selected;
  List<Note> _notes = [];
  bool _loadingWorkspaces = true;
  bool _loadingNotes = false;
  String? _workspaceError;
  String? _notesError;
  late final TabController _categoryTabs;

  @override
  void initState() {
    super.initState();
    _categoryTabs = TabController(length: 2, vsync: this);
    _categoryTabs.addListener(() {
      if (!_categoryTabs.indexIsChanging) return;
      _loadWorkspaces(
          category: _categoryTabs.index == 1 ? 'monthly' : 'hourly');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkspaces());
  }

  @override
  void dispose() {
    _categoryTabs.dispose();
    super.dispose();
  }


  Future<void> _loadWorkspaces({String category = 'hourly'}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (mounted) setState(() => _loadingWorkspaces = false);
      return;
    }

    if (mounted) setState(() => _loadingWorkspaces = true);
    try {
      if (mounted) setState(() => _workspaceError = null);
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

      final categorized =
          ws.where((workspace) => workspace.planType == category).toList();
      setState(() {
        _workspaces = ws;
        _selected = refreshedSelection != null &&
                refreshedSelection.planType == category
            ? refreshedSelection
            : (categorized.isNotEmpty ? categorized.first : null);
      });

      if (_selected != null) {
        await _loadNotes();
      } else if (mounted) {
        setState(() => _notes = []);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _workspaceError =
            'Unable to connect to the workspace service. Check that the backend is running and the app API URL is reachable.\n$error');
      }
    } finally {
      if (mounted) setState(() => _loadingWorkspaces = false);
    }
  }

  Future<void> _loadNotes() async {
    final sel = _selected;
    if (sel == null) return;
    if (mounted) setState(() => _loadingNotes = true);
    try {
      if (mounted) setState(() => _notesError = null);
      final notes = await ApiService.getWorkspaceNotes(sel.id);
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (error) {
      if (mounted) {
        setState(
            () => _notesError = 'Unable to load workspace documents.\n$error');
      }
    } finally {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    final url =
        pdfUrl.startsWith('http') ? pdfUrl : '${ApiConfig.baseUrl}$pdfUrl';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showThemedSnackBar('This document link is not available.');
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showThemedSnackBar('No PDF viewer is available on this device.');
      }
    } catch (e) {
      if (!mounted) return;
      _showThemedSnackBar('Could not launch PDF viewer: $e');
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

  Future<void> _joinSession() async {
    final sel = _selected;
    if (sel == null) return;
    try {
      final rtc = await ApiService.getRtcToken(sel.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoCallScreen(
            appId: rtc['appId'].toString(),
            token: rtc['token'].toString(),
            channelName: rtc['channelName'].toString(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showThemedSnackBar('Unable to join this session: $error');
    }
  }

  void _showThemedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Future<void> _toggleNote(Note note) async {
    try {
      await ApiService.toggleNote(note.id);
      await _loadNotes();
    } catch (error) {
      if (mounted) {
        _showThemedSnackBar('Unable to update the assignment: $error');
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
      await _loadNotes();
    } catch (error) {
      if (mounted) {
        _showThemedSnackBar('Unable to post the reply: $error');
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _uploadResource() async {
    final workspace = _selected;
    final user = context.read<AuthProvider>().user;
    if (workspace == null || user == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      await ApiService.uploadNote(
        workspaceId: workspace.id,
        uploadedBy: user.id,
        title: result!.files.single.name,
        pdfFile: File(path),
      );
      await _loadNotes();
    } catch (error) {
      if (mounted) _showThemedSnackBar('Unable to upload the PDF: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Workspaces',
                  style: GoogleFonts.playfairDisplay(
                    color: colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          // Category Tabs (Hourly / Monthly)
          SafeArea(
            top: false,
            bottom: false,
            child: TabBar(
              controller: _categoryTabs,
              labelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Hourly Workspaces'),
                Tab(text: 'Monthly Workspaces'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _categoryTabs,
              children: [
                _CategoryWorkspaceView(
                  category: 'hourly',
                  auth: auth,
                  workspaces: _workspaces,
                  selected: _selected,
                  notes: _notes,
                  loadingWorkspaces: _loadingWorkspaces,
                  loadingNotes: _loadingNotes,
                  workspaceError: _workspaceError,
                  notesError: _notesError,
                  onSelectWorkspace: (ws) {
                    setState(() => _selected = ws);
                    _loadNotes();
                  },
                  onRefresh: () => _loadWorkspaces(category: 'hourly'),
                  onRetryNotes: _loadNotes,
                  onOpenPdf: _previewPdf,
                  onToggle: _toggleNote,
                  onComment: _addComment,
                  onUploadResource: _uploadResource,
                  onJoinSession: _joinSession,
                ),
                _CategoryWorkspaceView(
                  category: 'monthly',
                  auth: auth,
                  workspaces: _workspaces,
                  selected: _selected,
                  notes: _notes,
                  loadingWorkspaces: _loadingWorkspaces,
                  loadingNotes: _loadingNotes,
                  workspaceError: _workspaceError,
                  notesError: _notesError,
                  onSelectWorkspace: (ws) {
                    setState(() => _selected = ws);
                    _loadNotes();
                  },
                  onRefresh: () => _loadWorkspaces(category: 'monthly'),
                  onRetryNotes: _loadNotes,
                  onOpenPdf: _previewPdf,
                  onToggle: _toggleNote,
                  onComment: _addComment,
                  onUploadResource: _uploadResource,
                  onJoinSession: _joinSession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-category workspace list + 4-tab inner workspace ───────────────────

class _CategoryWorkspaceView extends StatelessWidget {
  final String category;
  final AuthProvider auth;
  final List<Workspace> workspaces;
  final Workspace? selected;
  final List<Note> notes;
  final bool loadingWorkspaces;
  final bool loadingNotes;
  final String? workspaceError;
  final String? notesError;
  final ValueChanged<Workspace> onSelectWorkspace;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetryNotes;
  final ValueChanged<Note> onOpenPdf;
  final ValueChanged<Note> onToggle;
  final ValueChanged<Note> onComment;
  final VoidCallback onUploadResource;
  final VoidCallback onJoinSession;

  const _CategoryWorkspaceView({
    required this.category,
    required this.auth,
    required this.workspaces,
    required this.selected,
    required this.notes,
    required this.loadingWorkspaces,
    required this.loadingNotes,
    required this.workspaceError,
    required this.notesError,
    required this.onSelectWorkspace,
    required this.onRefresh,
    required this.onRetryNotes,
    required this.onOpenPdf,
    required this.onToggle,
    required this.onComment,
    required this.onUploadResource,
    required this.onJoinSession,
  });

  @override
  Widget build(BuildContext context) {
    final categoryWorkspaces =
        workspaces.where((ws) => ws.planType == category).toList();

    // Determine which workspace to show content for: must belong to this category
    final activeWorkspace =
        selected != null && selected!.planType == category ? selected : null;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!auth.isLoggedIn)
                  const _WorkspaceMessage(
                    icon: Icons.lock_outline,
                    message: 'Log in to see your classroom workspaces.',
                  )
                else if (workspaceError != null)
                  _WorkspaceError(
                    message: workspaceError!,
                    onRetry: onRefresh,
                  )
                else if (loadingWorkspaces)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 56),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (categoryWorkspaces.isEmpty)
                  _WorkspaceMessage(
                    icon: Icons.folder_open,
                    message: category == 'hourly'
                        ? 'No hourly session workspaces yet.\nBook a session with a mentor to get started.'
                        : 'No monthly mentorship workspaces yet.\nEnroll in a monthly plan to get started.',
                  )
                else ...[
                  const SizedBox(height: 6),
                  // Workspace selector dropdown
                  DropdownButtonFormField<Workspace>(
                    initialValue: activeWorkspace,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Active Classroom Workspace',
                      prefixIcon:
                          Icon(Icons.school_outlined, color: AppColors.mint),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    items: categoryWorkspaces
                        .map((ws) => DropdownMenuItem(
                              value: ws,
                              child: Text(ws.topic,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1),
                            ))
                        .toList(),
                    onChanged: (ws) {
                      if (ws != null) onSelectWorkspace(ws);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (activeWorkspace != null) ...[
                    // 4-tab workspace content
                    _WorkspaceTabs(
                      workspace: activeWorkspace,
                      notes: notes,
                      loadingNotes: loadingNotes,
                      notesError: notesError,
                      onRetryNotes: onRetryNotes,
                      onOpenPdf: onOpenPdf,
                      onToggle: onToggle,
                      onComment: onComment,
                      onUploadResource: onUploadResource,
                      onJoinSession: onJoinSession,
                      isHourly: category == 'hourly',
                    ),
                  ],
                ],
              ]),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: BrandFooter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4-tab workspace panel ─────────────────────────────────────────────────

class _WorkspaceTabs extends StatelessWidget {
  final Workspace workspace;
  final List<Note> notes;
  final bool loadingNotes;
  final String? notesError;
  final VoidCallback onRetryNotes;
  final ValueChanged<Note> onOpenPdf;
  final ValueChanged<Note> onToggle;
  final ValueChanged<Note> onComment;
  final VoidCallback onUploadResource;
  final VoidCallback onJoinSession;
  final bool isHourly;

  const _WorkspaceTabs({
    required this.workspace,
    required this.notes,
    required this.loadingNotes,
    required this.notesError,
    required this.onRetryNotes,
    required this.onOpenPdf,
    required this.onToggle,
    required this.onComment,
    required this.onUploadResource,
    required this.onJoinSession,
    required this.isHourly,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inner tab bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.mint.withValues(alpha: 0.18),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.mint,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Chat'),
                Tab(text: 'Notes & Code'),
                Tab(text: 'Resources & PDFs'),
                Tab(text: 'Overview'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab content — fixed height so it stays inside the scroll
          SizedBox(
            height: 420,
            child: TabBarView(
              children: [
                // ── Tab 1: Direct Chat ──────────────────────────────────
                _EmbeddedChat(workspaceId: workspace.id),

                // ── Tab 2: Notes & Code ─────────────────────────────────
                _NotesView(
                  notes: notes,
                  loading: loadingNotes,
                  error: notesError,
                  onRetry: onRetryNotes,
                  onOpenPdf: onOpenPdf,
                  onToggle: onToggle,
                  onComment: onComment,
                ),

                // ── Tab 3: Resources & PDFs ─────────────────────────────
                _ResourcesView(
                  notes: notes,
                  onOpenPdf: onOpenPdf,
                  onUploadResource: onUploadResource,
                ),

                // ── Tab 4: Session / Plan Overview ──────────────────────
                _OverviewTab(
                  workspace: workspace,
                  isHourly: isHourly,
                  onJoinSession: onJoinSession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Embedded chat (no Scaffold wrapper) ──────────────────────────────────

class _EmbeddedChat extends StatefulWidget {
  final String workspaceId;
  const _EmbeddedChat({required this.workspaceId});

  @override
  State<_EmbeddedChat> createState() => _EmbeddedChatState();
}

class _EmbeddedChatState extends State<_EmbeddedChat> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  File? _attachment;
  bool _sending = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results =
          await ApiService.getChatMessages(widget.workspaceId);
      if (!mounted) return;
      final loaded =
          results.whereType<Map>().map(Map<String, dynamic>.from).toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
        _loading = false;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => _attachment = File(path));
  }

  Future<void> _send() async {
    final user = context.read<AuthProvider>().user;
    if (user == null ||
        (_controller.text.trim().isEmpty && _attachment == null)) return;
    setState(() => _sending = true);
    try {
      final message = await ApiService.sendChatMessage(
        conversationId: widget.workspaceId,
        text: _controller.text.trim(),
        pdf: _attachment,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(message);
        _controller.clear();
        _attachment = null;
      });
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openAttachment(String path) async {
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open attachment.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;
    return Column(
      children: [
        if (_error != null)
          MaterialBanner(
            backgroundColor:
                Theme.of(context).colorScheme.errorContainer,
            content: Text(_error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
            actions: [
              TextButton(onPressed: _load, child: const Text('Retry'))
            ],
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const _WorkspaceMessage(
                      icon: Icons.chat_bubble_outline,
                      message:
                          'No messages yet. Start the conversation!',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final own = '${msg['senderId']}' == userId;
                        final attachment =
                            msg['attachmentUrl']?.toString() ?? '';
                        return Align(
                          alignment: own
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.sizeOf(context).width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              color: own
                                  ? AppColors.mint.withValues(alpha: 0.18)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((msg['text']?.toString() ?? '')
                                    .isNotEmpty)
                                  Text(msg['text'].toString()),
                                if (attachment.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _openAttachment(attachment),
                                    icon: const Icon(
                                        Icons.picture_as_pdf,
                                        size: 16),
                                    label:
                                        const Text('Open shared PDF'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.6))),
          ),
          child: Row(
            children: [
              IconButton(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach PDF'),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _attachment != null
                        ? _attachment!.path
                            .split(Platform.pathSeparator)
                            .last
                        : 'Write a message…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Notes tab ────────────────────────────────────────────────────────────

class _NotesView extends StatelessWidget {
  final List<Note> notes;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Note> onOpenPdf;
  final ValueChanged<Note> onToggle;
  final ValueChanged<Note> onComment;

  const _NotesView({
    required this.notes,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpenPdf,
    required this.onToggle,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _WorkspaceError(message: error!, onRetry: onRetry);
    }
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notes.isEmpty) {
      return const _WorkspaceMessage(
        icon: Icons.code_outlined,
        message: 'Shared notes and code snippets will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: notes
          .map((note) => _NoteCard(
                note: note,
                onOpenPdf: () => onOpenPdf(note),
                onToggle: () => onToggle(note),
                onComment: () => onComment(note),
              ))
          .toList(),
    );
  }
}

// ─── Resources tab ────────────────────────────────────────────────────────

class _ResourcesView extends StatelessWidget {
  final List<Note> notes;
  final ValueChanged<Note> onOpenPdf;
  final VoidCallback onUploadResource;

  const _ResourcesView({
    required this.notes,
    required this.onOpenPdf,
    required this.onUploadResource,
  });

  @override
  Widget build(BuildContext context) {
    final pdfNotes = notes.where((n) => n.pdfUrl.isNotEmpty).toList();
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onUploadResource,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Upload PDF resource'),
          ),
        ),
        const SizedBox(height: 10),
        if (pdfNotes.isEmpty)
          const _WorkspaceMessage(
            icon: Icons.picture_as_pdf_outlined,
            message: 'Uploaded PDF resources will appear here.',
          )
        else
          ...pdfNotes.map(
            (note) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                leading: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.terracotta),
                title: Text(note.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Open PDF',
                  onPressed: () => onOpenPdf(note),
                  icon: const Icon(Icons.visibility_outlined),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Session Overview tab ─────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Workspace workspace;
  final bool isHourly;
  final VoidCallback onJoinSession;

  const _OverviewTab({
    required this.workspace,
    required this.isHourly,
    required this.onJoinSession,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined,
                        color: AppColors.mint, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workspace.topic,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _overviewRow('Type',
                    isHourly ? '⏱ Hourly Session' : '📅 Monthly Mentorship'),
                const SizedBox(height: 8),
                _overviewRow('Mentor', workspace.mentor.name),
                const SizedBox(height: 8),
                _overviewRow('Mentee', workspace.mentee.name),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onJoinSession,
            icon: const Icon(Icons.video_call_outlined),
            label: const Text('Join Video Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _overviewRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }
}

// ─── Shared UI helpers ─────────────────────────────────────────────────────

class _WorkspaceMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _WorkspaceMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

class _WorkspaceError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WorkspaceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.danger),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry connection'),
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
                    onPressed: () =>
                        setState(() => _expanded = !_expanded),
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
