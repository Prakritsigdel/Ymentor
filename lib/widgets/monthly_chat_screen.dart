import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class MonthlyChatScreen extends StatefulWidget {
  final String conversationId;
  const MonthlyChatScreen({super.key, required this.conversationId});

  @override
  State<MonthlyChatScreen> createState() => _MonthlyChatScreenState();
}

class _MonthlyChatScreenState extends State<MonthlyChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Timer? _poller;
  File? _attachment;
  bool _sending = false;
  bool _loading = true;
  bool _polling = false;
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
    _poller = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _disposed = true;
    _poller?.cancel();
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
        '${ApiConfig.wsBaseUrl}/ws/chat?channel=${Uri.encodeComponent(widget.conversationId)}',
      );
      _channel = WebSocketChannel.connect(wsUrl);

      _channel?.sink.add(jsonEncode({
        'type': 'join',
        'channel': widget.conversationId,
        'conversationId': widget.conversationId,
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
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load() async {
    if (_polling) return;
    _polling = true;
    try {
      final results = await ApiService.getChatMessages(widget.conversationId);
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
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString();
        });
    } finally {
      _polling = false;
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
        conversationId: widget.conversationId,
        text: _controller.text.trim(),
        pdf: _attachment,
        sessionType: 'HOURLY',
      );
      if (!mounted) return;
      _onIncomingMessage(message);
      _controller.clear();
      _attachment = null;
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openAttachment(String path) async {
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open attachment.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Mentorship chat')),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _load, child: const Text('Retry'))
              ],
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      final own = '${message['senderId']}' == userId;
                      final attachment =
                          message['attachmentUrl']?.toString() ?? '';
                      return Align(
                        alignment:
                            own ? Alignment.centerRight : Alignment.centerLeft,
                        child: Card(
                          color:
                              own ? AppColors.surfaceRaised : AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((message['text']?.toString() ?? '')
                                    .isNotEmpty)
                                  Text(message['text'].toString()),
                                if (attachment.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _openAttachment(attachment),
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('Open shared PDF'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                      onPressed: _pickPdf, icon: const Icon(Icons.attach_file)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _attachment?.path
                                .split(Platform.pathSeparator)
                                .last ??
                            'Write a message',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
