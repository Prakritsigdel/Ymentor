import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/workspace_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  State<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  List<Workspace> _workspaces = [];
  Workspace? _uploadTarget;
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController(text: 'Next Sunday, 11:59 PM');
  File? _pickedPdf;
  bool _uploading = false;

  final _tier30Ctrl = TextEditingController();
  final _tier60Ctrl = TextEditingController();
  final _tier120Ctrl = TextEditingController();
  final _meetingUrlCtrl = TextEditingController();
  bool _savingConfig = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
      _hydrateConfigFields();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _dueDateCtrl.dispose();
    _tier30Ctrl.dispose();
    _tier60Ctrl.dispose();
    _tier120Ctrl.dispose();
    _meetingUrlCtrl.dispose();
    super.dispose();
  }

  void _hydrateConfigFields() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _tier30Ctrl.text = user.pricingTiers.tier30m.toStringAsFixed(2);
    _tier60Ctrl.text = user.pricingTiers.tier60m.toStringAsFixed(2);
    _tier120Ctrl.text = user.pricingTiers.tier120m.toStringAsFixed(2);
    _meetingUrlCtrl.text = user.meetingUrl;
  }

  Future<void> _loadDashboard() async {
    final auth = context.read<AuthProvider>();
    await auth.refreshUser();
    final user = auth.user;
    if (user == null) return;

    try {
      final ws = await ApiService.getUserWorkspaces(user.id);
      if (!mounted) return;
      setState(() {
        _workspaces = ws;
        if (_uploadTarget == null && ws.isNotEmpty) {
          _uploadTarget = ws.first;
        } else if (_uploadTarget != null) {
          final exists = ws.any((w) => w.id == _uploadTarget!.id);
          if (!exists && ws.isNotEmpty) _uploadTarget = ws.first;
        }
      });
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedPdf = File(result.files.single.path!));
    }
  }

  Future<void> _uploadAssignment() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _uploadTarget == null || _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student workspace and enter an assignment title.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await ApiService.uploadNote(
        workspaceId: _uploadTarget!.id,
        uploadedBy: user.id,
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
        dueDate: _dueDateCtrl.text.trim(),
        pdfFile: _pickedPdf,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF Assignment successfully uploaded to classroom!')),
      );

      setState(() {
        _titleCtrl.clear();
        _descriptionCtrl.clear();
        _pickedPdf = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveConfig() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _savingConfig = true);
    try {
      await ApiService.updateMentorConfig(
        user.id,
        pricingTiers: PricingTiers(
          tier30m: double.tryParse(_tier30Ctrl.text) ?? user.pricingTiers.tier30m,
          tier60m: double.tryParse(_tier60Ctrl.text) ?? user.pricingTiers.tier60m,
          tier120m: double.tryParse(_tier120Ctrl.text) ?? user.pricingTiers.tier120m,
        ),
        meetingUrl: _meetingUrlCtrl.text.trim(),
      );

      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pricing tiers and meeting URL updated!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _savingConfig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (!auth.isLoggedIn) {
      return const Center(child: Text('Log in to view your dashboard.', style: TextStyle(color: AppColors.textSecondary)));
    }

    if (user == null || !user.isMentor) {
      return const Center(
        child: Text('This dashboard is accessible to Mentors only.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final isPendingApproval = user.isPendingApproval;

    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pending Approval Warning Banner
            if (isPendingApproval) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.star.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.pending_actions, color: AppColors.star, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your mentor account is currently awaiting Admin Approval. You can prepare assignments and configure your pricing in the meantime.',
                        style: TextStyle(color: AppColors.star, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Financial Summary Cards: Virtual Wallet & Pending Escrow
            Row(
              children: [
                Expanded(child: _statCard('Virtual Wallet Balance', '\$${user.walletBalance.toStringAsFixed(2)}', AppColors.mint, Icons.account_balance_wallet)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Pending Escrow Balance', '\$${user.pendingEscrow.toStringAsFixed(2)}', AppColors.star, Icons.lock_clock)),
              ],
            ),
            const SizedBox(height: 10),

            // Rating and Sessions Cards
            Row(
              children: [
                Expanded(child: _statCard('Sessions Completed', '${user.totalSessions}', AppColors.cyan, Icons.people)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Rating Avg', user.ratingAvg.toStringAsFixed(2), AppColors.verified, Icons.star)),
              ],
            ),

            const SizedBox(height: 24),

            // Multer PDF Assignment Uploader
            const Text('Upload Classroom PDF Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_workspaces.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'No active student workspaces yet. Workspaces are automatically created when a student books a session with you.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<Workspace>(
                        initialValue: _uploadTarget,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Student Workspace',
                          prefixIcon: Icon(Icons.school, color: AppColors.textSecondary),
                        ),
                        items: _workspaces
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.topic, overflow: TextOverflow.ellipsis, maxLines: 1),
                                ))
                            .toList(),
                        onChanged: (w) => setState(() => _uploadTarget = w),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Assignment Title',
                          hintText: 'e.g. Week 1: Clean Architecture Refactor.pdf',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Instructions / Description (Optional)',
                          hintText: 'e.g. Complete exercises in section 2...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dueDateCtrl,
                        decoration: const InputDecoration(labelText: 'Due Date'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _pickedPdf == null
                              ? 'Attach PDF File'
                              : 'Selected: ${_pickedPdf!.path.split(Platform.pathSeparator).last}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _uploading ? null : _uploadAssignment,
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: _uploading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Upload PDF to Classroom'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tier Pricing Editor & Meeting URL
            const Text('Session Tier Pricing & Meeting Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tier30Ctrl,
                            decoration: const InputDecoration(labelText: '30m (\$)', prefixText: '\$'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _tier60Ctrl,
                            decoration: const InputDecoration(labelText: '60m (\$)', prefixText: '\$'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _tier120Ctrl,
                            decoration: const InputDecoration(labelText: '120m (\$)', prefixText: '\$'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _meetingUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Google Meet / Zoom URL',
                        prefixIcon: Icon(Icons.videocam_outlined, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _savingConfig ? null : _saveConfig,
                      child: _savingConfig
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Update Pricing & Meeting URL'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
