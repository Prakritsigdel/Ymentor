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
      _loadWorkspaces();
      _hydrateConfigFields();
    });
  }

  void _hydrateConfigFields() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _tier30Ctrl.text = user.pricingTiers.tier30m.toStringAsFixed(2);
    _tier60Ctrl.text = user.pricingTiers.tier60m.toStringAsFixed(2);
    _tier120Ctrl.text = user.pricingTiers.tier120m.toStringAsFixed(2);
    _meetingUrlCtrl.text = user.meetingUrl;
  }

  Future<void> _loadWorkspaces() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final ws = await ApiService.getUserWorkspaces(user.id);
      setState(() {
        _workspaces = ws;
        _uploadTarget = ws.isNotEmpty ? ws.first : null;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a workspace and a title.')));
      return;
    }
    setState(() => _uploading = true);
    try {
      await ApiService.uploadNote(
        workspaceId: _uploadTarget!.id,
        uploadedBy: user.id,
        title: _titleCtrl.text.trim(),
        dueDate: _dueDateCtrl.text.trim(),
        pdfFile: _pickedPdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment uploaded!')));
      setState(() {
        _titleCtrl.clear();
        _pickedPdf = null;
      });
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing & meeting link updated.')));
    } catch (e) {
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
      return const Center(child: Text('Log in to see your dashboard.', style: TextStyle(color: AppColors.textSecondary)));
    }
    if (user == null || !user.isMentor) {
      return const Center(child: Text('This dashboard is for mentors only.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Wallet Balance', '\$${user.walletBalance.toStringAsFixed(2)}', AppColors.mint)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Sessions', '${user.totalSessions}', AppColors.cyan)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Rating', user.ratingAvg.toStringAsFixed(2), AppColors.star)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Leaderboard Score', user.leaderboardScore.toStringAsFixed(3), AppColors.verified)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Upload Assignment PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Workspace>(
                  initialValue: _uploadTarget,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Student workspace'),
                  items: _workspaces
                      .map((w) => DropdownMenuItem(value: w, child: Text(w.topic, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (w) => setState(() => _uploadTarget = w),
                ),
                const SizedBox(height: 12),
                TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Assignment title')),
                const SizedBox(height: 12),
                TextField(controller: _dueDateCtrl, decoration: const InputDecoration(labelText: 'Due date')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_pickedPdf == null ? 'Choose PDF' : _pickedPdf!.path.split('/').last),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _uploading ? null : _uploadAssignment,
                  child: _uploading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Upload to Workspace'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Pricing & Meeting Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: _tier30Ctrl, decoration: const InputDecoration(labelText: '30m \$'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _tier60Ctrl, decoration: const InputDecoration(labelText: '1h \$'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _tier120Ctrl, decoration: const InputDecoration(labelText: '2h \$'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                TextField(controller: _meetingUrlCtrl, decoration: const InputDecoration(labelText: 'Meeting URL')),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _savingConfig ? null : _saveConfig,
                  child: _savingConfig
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
