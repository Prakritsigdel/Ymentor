import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String appId;
  final String token;
  final String channelName;

  const VideoCallScreen({
    super.key,
    required this.appId,
    required this.token,
    required this.channelName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final RtcEngine _engine;

  // ── Strict Lifecycle Guards ───────────────────────────────────────────────
  bool _isEngineJoined = false;
  bool _isInitializing = false;
  int? _remoteUid;
  String _debugStatus = 'Initializing...';
  bool _isMuted = false;
  bool _isVideoOff = false;

  late final String _sanitizedChannel;

  @override
  void initState() {
    super.initState();
    _sanitizedChannel =
        widget.channelName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    _initAgora();
  }

  Future<void> _initAgora() async {
    if (_isInitializing || _isEngineJoined) return;
    _isInitializing = true;

    try {
      if (mounted) setState(() => _debugStatus = 'Requesting permissions...');

      // A. Request Runtime Permissions
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      if (!cameraGranted || !micGranted) {
        if (mounted) {
          setState(() => _debugStatus = 'Camera/Microphone permission denied');
        }
        return;
      }

      if (mounted) setState(() => _debugStatus = 'Initializing Agora Engine...');

      // B. Create Engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: widget.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // C. Event Callbacks
      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('[Agora] ✅ Joined channel: ${connection.channelId}');
          if (!mounted) return;
          setState(() {
            _isEngineJoined = true;
            _debugStatus = 'Connected to channel';
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('[Agora] 👤 User joined: $remoteUid');
          if (!mounted) return;
          setState(() {
            _remoteUid = remoteUid;
            _debugStatus = 'Remote user joined ($remoteUid)';
          });
        },
        onUserOffline:
            (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('[Agora] 👋 User left: $remoteUid');
          if (!mounted) return;
          setState(() {
            _remoteUid = null;
            _debugStatus = 'Waiting for participant...';
          });
        },
        onFirstRemoteVideoFrame:
            (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
          debugPrint('[Agora] 📹 First remote video frame from: $remoteUid');
          if (!mounted) return;
          setState(() {
            _debugStatus = 'Streaming remote video';
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('[Agora] ❌ Error [$err]: $msg');
          if (mounted) {
            setState(() {
              _debugStatus = 'Agora error: $err';
            });
          }
        },
      ));

      // D. Enable Audio/Video Pipeline BEFORE Join
      await _engine.enableVideo();
      await _engine.enableAudio();
      await _engine.setDefaultAudioRouteToSpeakerphone(true);
      await _engine.startPreview();

      // E. Resolve Token
      String activeToken = widget.token;
      if (activeToken.isEmpty) {
        if (mounted) setState(() => _debugStatus = 'Fetching RTC token...');
        final rtc = await ApiService.getRtcToken(_sanitizedChannel);
        activeToken = rtc['token']?.toString() ?? '';
      }

      if (mounted) setState(() => _debugStatus = 'Joining channel...');

      // F. Join Channel
      await _engine.joinChannel(
        token: activeToken,
        channelId: _sanitizedChannel,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      debugPrint('[Agora] Setup failed: $e');
      if (mounted) {
        setState(() {
          _debugStatus = 'Error: $e';
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // ── Call Controls Handlers ──────────────────────────────────────────────────

  void _toggleMute() {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    _engine.muteLocalAudioStream(next);
  }

  void _toggleVideo() {
    final next = !_isVideoOff;
    setState(() => _isVideoOff = next);
    _engine.muteLocalVideoStream(next);
  }

  void _flipCamera() {
    _engine.switchCamera();
  }

  Future<void> _leave() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            active: !_isMuted,
            onPressed: _toggleMute,
          ),
          _CircleButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            active: !_isVideoOff,
            onPressed: _toggleVideo,
          ),
          _CircleButton(
            icon: Icons.flip_camera_ios,
            active: true,
            onPressed: _flipCamera,
          ),
          FloatingActionButton(
            backgroundColor: Colors.red,
            elevation: 2,
            onPressed: _leave,
            child: const Icon(Icons.call_end, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1: Remote Video (Always rendered in tree; hidden behind overlay when no remote UID)
            if (_remoteUid != null)
              Positioned.fill(
                child: AgoraVideoView(
                  key: ValueKey('remote_$_remoteUid'),
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(
                      uid: _remoteUid,
                      renderMode: RenderModeType.renderModeHidden,
                    ),
                    connection: RtcConnection(channelId: _sanitizedChannel),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _debugStatus,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Channel: $_sanitizedChannel',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Layer 2: Floating Local Video Preview
            if (_isEngineJoined)
              Positioned(
                top: 20,
                right: 20,
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.grey[900],
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AgoraVideoView(
                          key: const ValueKey('local_preview'),
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(
                              uid: 0,
                              renderMode: RenderModeType.renderModeHidden,
                            ),
                          ),
                        ),
                        if (_isVideoOff)
                          const ColoredBox(
                            color: Color(0xDD000000),
                            child: Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white54,
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Layer 3: Control Buttons Bar (Mute, Camera Flip, End Call)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: _buildCallControls(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: active ? Colors.white24 : Colors.white10,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(14),
      ),
      onPressed: onPressed,
    );
  }
}
