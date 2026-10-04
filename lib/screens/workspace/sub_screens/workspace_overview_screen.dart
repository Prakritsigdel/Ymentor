import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/workspace_model.dart';
import '../../../services/api_service.dart';
import '../video_call_screen.dart';

class WorkspaceOverviewScreen extends StatefulWidget {
  final Workspace workspace;
  final VoidCallback? onJoinSession;

  const WorkspaceOverviewScreen({
    super.key,
    required this.workspace,
    this.onJoinSession,
  });

  @override
  State<WorkspaceOverviewScreen> createState() =>
      _WorkspaceOverviewScreenState();
}

class _WorkspaceOverviewScreenState extends State<WorkspaceOverviewScreen> {
  bool _joining = false;

  Future<void> _handleJoinSession() async {
    if (widget.onJoinSession != null) {
      widget.onJoinSession!();
      return;
    }

    setState(() => _joining = true);
    try {
      final rtc = await ApiService.getRtcToken(widget.workspace.id);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to join call: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = widget.workspace;
    final isHourly = workspace.planType == 'hourly';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentorship Overview'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: AppColors.mint,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workspace.topic,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isHourly
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.mint.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isHourly
                                      ? '⏱ Hourly Session'
                                      : '📅 30-Day Monthly Mentorship',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isHourly
                                        ? AppColors.primary
                                        : AppColors.mint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _overviewRow('Mentor', workspace.mentor.name),
                    const SizedBox(height: 10),
                    _overviewRow('Mentee', workspace.mentee.name),
                    const SizedBox(height: 10),
                    _overviewRow(
                      'Format',
                      isHourly
                          ? '1-on-1 Dedicated Consultation'
                          : 'Continuous Async Chat & Live Calls',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video Calling Quick Action Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.videocam, color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Live Video Session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Launch an interactive high-definition Agora RTC video session with screen audio and camera controls.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _joining ? null : _handleJoinSession,
                        icon: _joining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.video_call_outlined),
                        label: Text(
                          _joining ? 'Connecting...' : 'Join Video Session',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Classroom Guidelines Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.mint,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Escrow Protected Classroom',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your mentorship session is fully protected under Ymentor Escrow. Funds are safely held and disbursed to the mentor only upon milestone completion.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
