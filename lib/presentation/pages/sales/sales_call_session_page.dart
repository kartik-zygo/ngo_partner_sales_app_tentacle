import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/support_call_request.dart';
import '../../../domain/usecases/sales_usecases.dart';
import '../../blocs/leads/leads_bloc.dart';

class SalesCallSessionPage extends StatefulWidget {
  const SalesCallSessionPage({
    super.key,
    required this.call,
    required this.actorId,
    required this.actorName,
    required this.socketService,
    required this.agoraTokenUseCase,
  });

  final SupportCallRequest call;
  final String actorId;
  final String actorName;
  final SocketService socketService;
  final GetAgoraTokenUseCase agoraTokenUseCase;

  @override
  State<SalesCallSessionPage> createState() => _SalesCallSessionPageState();
}

class _SalesCallSessionPageState extends State<SalesCallSessionPage> {
  // Agora engine
  RtcEngine? _engine;
  RtcEngineEventHandler? _eventHandler;

  // Page state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';

  // Agora session data from backend
  String _agoraToken = '';
  String _channelName = '';
  int _localUid = 2;
  String _appId = '';

  // Remote user
  int? _remoteUid;
  bool _remoteJoined = false;

  // Controls state
  bool _micMuted = false;
  bool _speakerOn = true;
  bool _cameraOn = true;
  bool _frontCamera = true;

  // Guard against double-pop / callbacks after dispose
  bool _callEnded = false;

  // Duration timer
  Timer? _timer;
  int _elapsedSeconds = 0;

  bool get _isVideo => widget.call.type == SupportCallType.video;

  @override
  void initState() {
    super.initState();
    widget.socketService.joinCallRoom(widget.call.id);
    widget.socketService.onCallStatusChanged(_onCallStatusChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
    _initAgora();
  }

  @override
  void dispose() {
    _callEnded = true;
    _timer?.cancel();
    widget.socketService.offCallStatusChanged();
    widget.socketService.leaveCallRoom(widget.call.id);
    if (_engine != null && _eventHandler != null) {
      _engine!.unregisterEventHandler(_eventHandler!);
    }
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _initAgora() async {
    // 1. Request permissions
    final permissions = _isVideo
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];
    final results = await permissions.request();
    final denied = results.values.any(
      (s) => s == PermissionStatus.denied || s == PermissionStatus.permanentlyDenied,
    );
    if (denied) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMsg = _isVideo
              ? 'Camera and microphone permissions are required.'
              : 'Microphone permission is required.';
        });
      }
      return;
    }

    try {
      // 2. Get Agora token from backend
      final tokenData = await widget.agoraTokenUseCase(widget.call.id);
      _agoraToken = tokenData['token'] as String? ?? '';
      _channelName = tokenData['channelName'] as String? ?? widget.call.id;
      _localUid = tokenData['uid'] as int? ?? 2;
      _appId = tokenData['appId'] as String? ?? '';

      if (_appId.isEmpty) throw Exception('Agora App ID missing from server response.');

      // 3. Create and initialize Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: _appId));

      // 4. Set communication profile for 1:1 calls — must be before enableAudio.
      //    The default liveBroadcasting profile can suppress mic capture for non-hosts.
      await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);

      // 5. Register event handlers (stored so we can unregister cleanly in dispose)
      _eventHandler = RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _engine?.setEnableSpeakerphone(_speakerOn);
          if (mounted) setState(() => _isLoading = false);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted && !_callEnded) {
            setState(() {
              _remoteUid = remoteUid;
              _remoteJoined = true;
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted || _callEnded) return;
          if (remoteUid == 1) {
            _endCall();
          }
        },
        onTokenPrivilegeWillExpire: (connection, token) async {
          try {
            final data = await widget.agoraTokenUseCase(widget.call.id);
            final newToken = data['token'] as String? ?? '';
            if (newToken.isNotEmpty) {
              await _engine?.renewToken(newToken);
            }
          } catch (_) {}
        },
        onError: (err, msg) {
          if (mounted && !_callEnded) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMsg = 'Agora error: $msg';
            });
          }
        },
      );
      _engine!.registerEventHandler(_eventHandler!);

      // 6. Enable audio and video
      await _engine!.enableAudio();
      if (_isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        // For voice-only calls, default audio route to speaker before joining
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      }

      // 7. Join channel (setEnableSpeakerphone is called in onJoinChannelSuccess
      //    — calling it before join causes ERR_INVALID_ARGUMENT on Agora 6.x)
      await _engine!.joinChannel(
        token: _agoraToken,
        channelId: _channelName,
        uid: _localUid,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: _isVideo,
          publishCameraTrack: _isVideo,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _onCallStatusChanged(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (!mounted || _callEnded) return;
    if (status == 'ended' || status == 'rejected') {
      _endCall();
    }
  }

  void _endCall() {
    if (_callEnded) return;
    _callEnded = true;
    context.read<LeadsBloc>().add(
          SupportCallUpdated(
            callId: widget.call.id,
            status: SupportCallStatus.ended,
            actorId: widget.actorId,
            actorName: widget.actorName,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMic() async {
    _micMuted = !_micMuted;
    await _engine?.muteLocalAudioStream(_micMuted);
    if (mounted) setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine?.setEnableSpeakerphone(_speakerOn);
    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    _cameraOn = !_cameraOn;
    await _engine?.enableLocalVideo(_cameraOn);
    if (mounted) setState(() {});
  }

  Future<void> _flipCamera() async {
    _frontCamera = !_frontCamera;
    await _engine?.switchCamera();
    if (mounted) setState(() {});
  }

  String _durationLabel() {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _hasError
            ? _ErrorView(message: _errorMsg, onEnd: _endCall)
            : _isVideo
                ? _VideoCallView(
                    engine: _engine,
                    channelName: _channelName,
                    localUid: _localUid,
                    remoteUid: _remoteUid,
                    remoteJoined: _remoteJoined,
                    isLoading: _isLoading,
                    call: widget.call,
                    duration: _durationLabel(),
                    micMuted: _micMuted,
                    speakerOn: _speakerOn,
                    cameraOn: _cameraOn,
                    onToggleMic: _toggleMic,
                    onToggleSpeaker: _toggleSpeaker,
                    onToggleCamera: _toggleCamera,
                    onFlipCamera: _flipCamera,
                    onEnd: _endCall,
                  )
                : _VoiceCallView(
                    call: widget.call,
                    duration: _durationLabel(),
                    remoteJoined: _remoteJoined,
                    isLoading: _isLoading,
                    micMuted: _micMuted,
                    speakerOn: _speakerOn,
                    onToggleMic: _toggleMic,
                    onToggleSpeaker: _toggleSpeaker,
                    onEnd: _endCall,
                  ),
      ),
    );
  }
}

// ─── Video Call View ─────────────────────────────────────────────────────────

class _VideoCallView extends StatelessWidget {
  const _VideoCallView({
    required this.engine,
    required this.channelName,
    required this.localUid,
    required this.remoteUid,
    required this.remoteJoined,
    required this.isLoading,
    required this.call,
    required this.duration,
    required this.micMuted,
    required this.speakerOn,
    required this.cameraOn,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.onEnd,
  });

  final RtcEngine? engine;
  final String channelName;
  final int localUid;
  final int? remoteUid;
  final bool remoteJoined;
  final bool isLoading;
  final SupportCallRequest call;
  final String duration;
  final bool micMuted;
  final bool speakerOn;
  final bool cameraOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Remote video (full screen)
        if (remoteJoined && remoteUid != null && engine != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine!,
              canvas: VideoCanvas(uid: remoteUid!),
              connection: RtcConnection(channelId: channelName),
            ),
          )
        else
          _WaitingBackground(isLoading: isLoading, call: call),

        // Local preview (picture-in-picture, top-right)
        if (engine != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 110,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              clipBehavior: Clip.hardEdge,
              child: cameraOn
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(Icons.videocam_off_rounded,
                            color: Colors.white54, size: 28),
                      ),
                    ),
            ),
          ),

        // Top bar — caller name + duration
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(call: call, duration: duration),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _VideoControls(
            micMuted: micMuted,
            speakerOn: speakerOn,
            cameraOn: cameraOn,
            onToggleMic: onToggleMic,
            onToggleSpeaker: onToggleSpeaker,
            onToggleCamera: onToggleCamera,
            onFlipCamera: onFlipCamera,
            onEnd: onEnd,
          ),
        ),
      ],
    );
  }
}

// ─── Voice Call View ──────────────────────────────────────────────────────────

class _VoiceCallView extends StatelessWidget {
  const _VoiceCallView({
    required this.call,
    required this.duration,
    required this.remoteJoined,
    required this.isLoading,
    required this.micMuted,
    required this.speakerOn,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onEnd,
  });

  final SupportCallRequest call;
  final String duration;
  final bool remoteJoined;
  final bool isLoading;
  final bool micMuted;
  final bool speakerOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final initials = call.userName.isNotEmpty ? call.userName[0].toUpperCase() : 'U';
    return Column(
      children: [
        const Spacer(flex: 2),
        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.salesAccent.withValues(alpha: 0.6),
              AppColors.salesAccentDeep,
            ]),
            boxShadow: [
              BoxShadow(
                color: AppColors.salesAccent.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          call.userName.isEmpty ? 'Unknown Caller' : call.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (call.userEmail.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            call.userEmail,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          isLoading
              ? 'Connecting…'
              : remoteJoined
                  ? duration
                  : 'Waiting for user…',
          style: TextStyle(
            color: isLoading ? Colors.white38 : AppColors.salesAccent,
            fontSize: 16,
          ),
        ),
        const Spacer(flex: 3),
        _VoiceControls(
          micMuted: micMuted,
          speakerOn: speakerOn,
          onToggleMic: onToggleMic,
          onToggleSpeaker: onToggleSpeaker,
          onEnd: onEnd,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Reusable Sub-widgets ─────────────────────────────────────────────────────

class _WaitingBackground extends StatelessWidget {
  const _WaitingBackground({required this.isLoading, required this.call});

  final bool isLoading;
  final SupportCallRequest call;

  @override
  Widget build(BuildContext context) {
    final initials = call.userName.isNotEmpty ? call.userName[0].toUpperCase() : 'U';
    return Container(
      color: const Color(0xFF0A0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.salesAccent.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isLoading ? 'Joining call…' : 'Waiting for ${call.userName}…',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            if (isLoading) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.salesAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.call, required this.duration});

  final SupportCallRequest call;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.userName.isEmpty ? 'Caller' : call.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.salesAccent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.salesAccent.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: AppColors.salesAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({
    required this.micMuted,
    required this.speakerOn,
    required this.cameraOn,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.onEnd,
  });

  final bool micMuted;
  final bool speakerOn;
  final bool cameraOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xDD000000), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlBtn(
            icon: micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: micMuted ? 'Unmute' : 'Mute',
            active: micMuted,
            onTap: onToggleMic,
          ),
          _ControlBtn(
            icon: speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: 'Speaker',
            active: speakerOn,
            onTap: onToggleSpeaker,
          ),
          _ControlBtn(
            icon: cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: cameraOn ? 'Camera' : 'Cam Off',
            active: cameraOn,
            onTap: onToggleCamera,
          ),
          _ControlBtn(
            icon: Icons.flip_camera_ios_rounded,
            label: 'Flip',
            onTap: onFlipCamera,
          ),
          _EndCallBtn(onEnd: onEnd),
        ],
      ),
    );
  }
}

class _VoiceControls extends StatelessWidget {
  const _VoiceControls({
    required this.micMuted,
    required this.speakerOn,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onEnd,
  });

  final bool micMuted;
  final bool speakerOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlBtn(
          icon: micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: micMuted ? 'Unmute' : 'Mute',
          active: micMuted,
          onTap: onToggleMic,
          size: 64,
        ),
        _EndCallBtn(onEnd: onEnd, size: 72),
        _ControlBtn(
          icon: speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: 'Speaker',
          active: speakerOn,
          onTap: onToggleSpeaker,
          size: 64,
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.size = 56,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.44),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EndCallBtn extends StatelessWidget {
  const _EndCallBtn({required this.onEnd, this.size = 56});

  final VoidCallback onEnd;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger,
            ),
            child: Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: size * 0.44,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'End',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onEnd});

  final String message;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Call Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onEnd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.call_end_rounded),
              label: const Text('Leave Call'),
            ),
          ],
        ),
      ),
    );
  }
}
