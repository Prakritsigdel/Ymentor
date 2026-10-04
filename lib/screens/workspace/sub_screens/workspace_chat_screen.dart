import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../models/workspace_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';

class WorkspaceChatScreen extends StatefulWidget {
  final String workspaceId;
  final String workspaceTitle;
  final Workspace? workspace;

  const WorkspaceChatScreen({
    super.key,
    required this.workspaceId,
    required this.workspaceTitle,
    this.workspace,
  });

  @override
  State<WorkspaceChatScreen> createState() => _WorkspaceChatScreenState();
}

class _WorkspaceChatScreenState extends State<WorkspaceChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  File? _attachment;
  bool _sending = false;
  bool _loading = true;
  String? _error;

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;
  Timer? _reconnectTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _socketSub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectWebSocket() {
    if (_disposed) return;
    _socketSub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}

    try {
      final wsUrl = Uri.parse(
        '${ApiConfig.wsBaseUrl}/ws/chat?channel=${Uri.encodeComponent(widget.workspaceId)}',
      );
      _channel = WebSocketChannel.connect(wsUrl);

      _channel?.sink.add(jsonEncode({
        'type': 'join',
        'channel': widget.workspaceId,
        'workspaceId': widget.workspaceId,
      }));

      _socketSub = _channel!.stream.listen(
        (data) {
          if (!mounted || _disposed) return;
          try {
            final decoded = jsonDecode(data.toString());
            if (decoded is Map<String, dynamic>) {
              Map<String, dynamic>? msg;
              if (decoded['type'] == 'new_message' && decoded['data'] is Map) {
                msg = Map<String, dynamic>.from(decoded['data'] as Map);
              } else if (decoded.containsKey('text') || decoded.containsKey('senderId')) {
                msg = decoded;
              }
              if (msg != null) {
                _onIncomingMessage(msg);
              }
            }
          } catch (e) {
            debugPrint('Error parsing incoming WS message: $e');
          }
        },
        onError: (err) {
          debugPrint('WS error: $err');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WS connection closed');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('WS connect exception: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !mounted) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed && mounted) {
        _connectWebSocket();
      }
    });
  }

  void _onIncomingMessage(Map<String, dynamic> msg) {
    final msgId = (msg['_id'] ?? msg['id'])?.toString();
    final existingIndex = msgId != null && msgId.isNotEmpty
        ? _messages.indexWhere((m) => (m['_id'] ?? m['id'])?.toString() == msgId)
        : -1;

    setState(() {
      if (existingIndex >= 0) {
        _messages[existingIndex] = msg;
      } else {
        _messages.add(msg);
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load() async {
    try {
      final results = await ApiService.getChatMessages(widget.workspaceId);
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
      _scrollToBottom();
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
      _onIncomingMessage(message);
      _controller.clear();
      _attachment = null;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workspace Chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.workspaceTitle.isNotEmpty)
              Text(
                widget.workspaceTitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              MaterialBanner(
                backgroundColor: colorScheme.errorContainer,
                content: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
                actions: [
                  TextButton(onPressed: _load, child: const Text('Retry'))
                ],
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 56,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 14),
                              Text(
                                'No messages yet.\nStart the conversation with your mentor!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.78,
                                  ),
                                  decoration: BoxDecoration(
                                    color: own
                                        ? AppColors.mint.withValues(alpha: 0.18)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: own
                                          ? AppColors.mint.withValues(alpha: 0.3)
                                          : AppColors.border.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((msg['text']?.toString() ?? '')
                                          .isNotEmpty)
                                        Text(
                                          msg['text'].toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (attachment.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _openAttachment(attachment),
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            size: 16,
                                            color: AppColors.terracotta,
                                          ),
                                          label: const Text(
                                            'Open shared PDF',
                                            style: TextStyle(
                                              color: AppColors.terracotta,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_attachment != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 16,
                            color: AppColors.terracotta,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attachment!.path.split(Platform.pathSeparator).last,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.terracotta,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _attachment = null),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.attach_file),
                        tooltip: 'Attach PDF document',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
