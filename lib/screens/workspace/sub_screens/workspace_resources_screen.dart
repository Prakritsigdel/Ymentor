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

class WorkspaceResourcesScreen extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceResourcesScreen({super.key, required this.workspace});

  @override
  State<WorkspaceResourcesScreen> createState() =>
      _WorkspaceResourcesScreenState();
}

class _WorkspaceResourcesScreenState extends State<WorkspaceResourcesScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
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

  Future<void> _uploadResource() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      await ApiService.uploadNote(
        workspaceId: widget.workspace.id,
        uploadedBy: user.id,
        title: result!.files.single.name,
        pdfFile: File(path),
      );
      if (mounted) {
        _showSnackBar('PDF resource uploaded successfully');
      }
      await _loadResources();
    } catch (error) {
      if (mounted) {
        _showSnackBar('Unable to upload PDF: $error');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pdfNotes = _notes.where((n) => n.pdfUrl.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources & PDFs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadResources,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadResources,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Upload Action Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                elevation: 0,
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 44,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Share Learning Resources',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload PDF documents, study guides, or assignments directly to this classroom.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _uploadResource,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(
                            _uploading ? 'Uploading...' : 'Upload PDF Resource',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shared Classroom Files (${pdfNotes.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadResources,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (pdfNotes.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No PDF files shared yet.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Uploaded materials will appear here for both mentor and mentee to view.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pdfNotes.map(
                  (note) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.terracotta,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: note.dueDate.isNotEmpty
                          ? Text(
                              'Due: ${note.dueDate}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.star,
                              ),
                            )
                          : const Text(
                              'Document Ready',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Preview Document',
                            onPressed: () => _previewPdf(note),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open in Viewer',
                            onPressed: () => _openPdf(note.pdfUrl),
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
