import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/workspace_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/brand_footer.dart';
import 'sub_screens/workspace_chat_screen.dart';
import 'sub_screens/workspace_notes_screen.dart';
import 'sub_screens/workspace_overview_screen.dart';
import 'sub_screens/workspace_resources_screen.dart';
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
  String? _workspaceError;
  late final TabController _categoryTabs;

  @override
  void initState() {
    super.initState();
    _categoryTabs = TabController(length: 2, vsync: this);
    _categoryTabs.addListener(() {
      if (!_categoryTabs.indexIsChanging) return;
      _loadWorkspaces(
        category: _categoryTabs.index == 1 ? 'monthly' : 'hourly',
      );
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
    try {
      final notes = await ApiService.getWorkspaceNotes(sel.id);
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (_) {}
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

  void _navigateToSection(BuildContext context, Widget targetScreen) {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active workspace first'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => targetScreen),
    );
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Hourly Mentorships'),
                Tab(text: 'Monthly Mentorships'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _categoryTabs,
              children: [
                _WorkspaceHubView(
                  category: 'hourly',
                  auth: auth,
                  workspaces: _workspaces,
                  selected: _selected,
                  notes: _notes,
                  loadingWorkspaces: _loadingWorkspaces,
                  workspaceError: _workspaceError,
                  onSelectWorkspace: (ws) {
                    setState(() => _selected = ws);
                    _loadNotes();
                  },
                  onRefresh: () => _loadWorkspaces(category: 'hourly'),
                  onJoinSession: _joinSession,
                  onNavigateToSection: _navigateToSection,
                ),
                _WorkspaceHubView(
                  category: 'monthly',
                  auth: auth,
                  workspaces: _workspaces,
                  selected: _selected,
                  notes: _notes,
                  loadingWorkspaces: _loadingWorkspaces,
                  workspaceError: _workspaceError,
                  onSelectWorkspace: (ws) {
                    setState(() => _selected = ws);
                    _loadNotes();
                  },
                  onRefresh: () => _loadWorkspaces(category: 'monthly'),
                  onJoinSession: _joinSession,
                  onNavigateToSection: _navigateToSection,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workspace Hub View ────────────────────────────────────────────────────

class _WorkspaceHubView extends StatelessWidget {
  final String category;
  final AuthProvider auth;
  final List<Workspace> workspaces;
  final Workspace? selected;
  final List<Note> notes;
  final bool loadingWorkspaces;
  final String? workspaceError;
  final ValueChanged<Workspace> onSelectWorkspace;
  final Future<void> Function() onRefresh;
  final VoidCallback onJoinSession;
  final void Function(BuildContext context, Widget targetScreen)
      onNavigateToSection;

  const _WorkspaceHubView({
    required this.category,
    required this.auth,
    required this.workspaces,
    required this.selected,
    required this.notes,
    required this.loadingWorkspaces,
    required this.workspaceError,
    required this.onSelectWorkspace,
    required this.onRefresh,
    required this.onJoinSession,
    required this.onNavigateToSection,
  });

  @override
  Widget build(BuildContext context) {
    final categoryWorkspaces =
        workspaces.where((ws) => ws.planType == category).toList();

    // Determine which workspace is active for this tab
    final activeWorkspace =
        selected != null && selected!.planType == category ? selected : null;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  // 1. Classroom Workspace Selector Dropdown
                  DropdownButtonFormField<Workspace>(
                    initialValue: activeWorkspace,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Active Classroom Workspace',
                      prefixIcon: const Icon(
                        Icons.school_outlined,
                        color: AppColors.mint,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: categoryWorkspaces
                        .map(
                          (ws) => DropdownMenuItem(
                            value: ws,
                            child: Text(
                              ws.topic,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (ws) {
                      if (ws != null) onSelectWorkspace(ws);
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Section Selector Grid (2x2 Modular Hub Navigation)
                  _SectionNavigationGrid(
                    workspace: activeWorkspace,
                    onNavigate: (screen) =>
                        onNavigateToSection(context, screen),
                  ),
                  const SizedBox(height: 20),

                  // 3. Active Workspace Summary Card
                  if (activeWorkspace != null)
                    _ActiveWorkspaceSummaryCard(
                      workspace: activeWorkspace,
                      isHourly: category == 'hourly',
                      onJoinSession: onJoinSession,
                    ),
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

// ─── 2x2 Modular Section Navigation Grid ───────────────────────────────────

class _SectionNavigationGrid extends StatelessWidget {
  final Workspace? workspace;
  final ValueChanged<Widget> onNavigate;

  const _SectionNavigationGrid({
    required this.workspace,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final hasWs = workspace != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Classroom Modules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _HubSectionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Chat',
                subtitle: 'Direct messaging',
                accentColor: AppColors.mint,
                onTap: () {
                  if (hasWs) {
                    onNavigate(
                      WorkspaceChatScreen(
                        workspaceId: workspace!.id,
                        workspaceTitle: workspace!.topic,
                        workspace: workspace,
                      ),
                    );
                  } else {
                    onNavigate(const SizedBox.shrink());
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HubSectionCard(
                icon: Icons.code,
                title: 'Notes & Code',
                subtitle: 'Snippets & tasks',
                accentColor: const Color(0xFF6366F1),
                onTap: () {
                  if (hasWs) {
                    onNavigate(WorkspaceNotesScreen(workspace: workspace!));
                  } else {
                    onNavigate(const SizedBox.shrink());
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HubSectionCard(
                icon: Icons.insert_drive_file_outlined,
                title: 'Resources & PDFs',
                subtitle: 'Shared materials',
                accentColor: AppColors.terracotta,
                onTap: () {
                  if (hasWs) {
                    onNavigate(
                      WorkspaceResourcesScreen(workspace: workspace!),
                    );
                  } else {
                    onNavigate(const SizedBox.shrink());
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HubSectionCard(
                icon: Icons.map_outlined,
                title: 'Overview',
                subtitle: 'Schedule & details',
                accentColor: const Color(0xFF0EA5E9),
                onTap: () {
                  if (hasWs) {
                    onNavigate(
                      WorkspaceOverviewScreen(workspace: workspace!),
                    );
                  } else {
                    onNavigate(const SizedBox.shrink());
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HubSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _HubSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Active Workspace Summary Card ─────────────────────────────────────────

class _ActiveWorkspaceSummaryCard extends StatelessWidget {
  final Workspace workspace;
  final bool isHourly;
  final VoidCallback onJoinSession;

  const _ActiveWorkspaceSummaryCard({
    required this.workspace,
    required this.isHourly,
    required this.onJoinSession,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.mint.withValues(alpha: 0.18),
                  child: Text(
                    workspace.mentor.name.isNotEmpty
                        ? workspace.mentor.name[0].toUpperCase()
                        : 'M',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.mint,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.topic,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mentor: ${workspace.mentor.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHourly
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.mint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isHourly ? 'Hourly' : 'Monthly',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isHourly ? AppColors.primary : AppColors.mint,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: AppColors.mint,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Status: Active Classroom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Mentee: ${workspace.mentee.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onJoinSession,
                icon: const Icon(Icons.video_call_outlined, size: 20),
                label: const Text(
                  'Join Video Session',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Helpers ─────────────────────────────────────────────────────

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
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
