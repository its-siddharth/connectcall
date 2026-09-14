import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../services/calling_service.dart';
import '../../services/zego_service.dart';
import '../../widgets/user_avatar.dart';

class VideoCallScreen extends StatefulWidget {
  final CallModel call;
  final UserModel currentUser;
  final UserModel remoteUser;

  const VideoCallScreen({
    super.key,
    required this.call,
    required this.currentUser,
    required this.remoteUser,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Mock-mode state
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _frontCamera = true;
  bool _connecting = true;
  bool _permissionsGranted = false;
  Timer? _connectTimer;
  String _statusText = 'Calling...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (!mounted) return;

    final camGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!camGranted) {
      _showPermissionDialog('Camera',
          permanentlyDenied: statuses[Permission.camera]?.isPermanentlyDenied ?? false);
      return;
    }
    if (!micGranted) {
      _showPermissionDialog('Microphone',
          permanentlyDenied: statuses[Permission.microphone]?.isPermanentlyDenied ?? false);
      return;
    }

    setState(() => _permissionsGranted = true);

    if (!ZegoService.isConfigured) {
      _startMockCall();
    }
  }

  void _startMockCall() {
    setState(() => _statusText = 'Ringing...');
    _connectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.read<CallingService>().onCallConnected();
      setState(() {
        _connecting = false;
        _statusText = 'Connected';
      });
    });
  }

  void _showPermissionDialog(String permission, {bool permanentlyDenied = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          permanentlyDenied
              ? '$permission is permanently denied. Enable it in App Settings to use video calls.'
              : '$permission access is needed for video calls.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endCall();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (permanentlyDenied) await openAppSettings();
              _endCall();
            },
            child: Text(permanentlyDenied ? 'Open Settings' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _endCall() {
    _connectTimer?.cancel();
    context.read<CallingService>().onCallEnded();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ZegoService.isConfigured && _permissionsGranted) {
      return ZegoService.buildVideoCall(
        call: widget.call,
        currentUser: widget.currentUser,
        onCallEnd: _endCall,
      );
    }
    if (!_permissionsGranted) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }
    return _buildMockUI();
  }

  Widget _buildMockUI() {
    final calling = context.watch<CallingService>();
    final durationText = calling.state == CallServiceState.connected
        ? AppUtils.formatDuration(calling.callDurationSeconds)
        : _statusText;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video area
          Container(
            color: const Color(0xFF1A1A2E),
            width: double.infinity,
            height: double.infinity,
            child: _connecting
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UserAvatar(user: widget.remoteUser, size: 96),
                        const SizedBox(height: 20),
                        Text(
                          widget.remoteUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(
                          color: AppColors.primaryLight,
                          strokeWidth: 2,
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      size: 80,
                      color: Colors.white12,
                    ),
                  ),
          ),

          // Local PiP preview
          if (!_connecting)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: _cameraOff ? Colors.grey[900] : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: _cameraOff
                    ? const Center(
                        child: Icon(Icons.videocam_off_outlined,
                            color: Colors.white54, size: 28),
                      )
                    : const Center(
                        child: Icon(Icons.person_outline,
                            color: Colors.white38, size: 40),
                      ),
              ),
            ),

          // Top info bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: !_connecting
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.remoteUser.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                            ),
                          ),
                          Text(
                            durationText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _VideoControl(
                      icon: _micMuted ? Icons.mic_off : Icons.mic,
                      label: _micMuted ? 'Unmute' : 'Mute',
                      onTap: () => setState(() => _micMuted = !_micMuted),
                      active: _micMuted,
                    ),
                    _VideoControl(
                      icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _cameraOff ? 'Cam On' : 'Camera',
                      onTap: () => setState(() => _cameraOff = !_cameraOff),
                      active: _cameraOff,
                    ),
                    _VideoControl(
                      icon: Icons.flip_camera_ios_outlined,
                      label: _frontCamera ? 'Rear' : 'Front',
                      onTap: () => setState(() => _frontCamera = !_frontCamera),
                    ),
                    _EndCallVideoButton(onTap: _endCall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video control widgets ────────────────────────────────────────────────────

class _VideoControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _VideoControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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

class _EndCallVideoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallVideoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.callEnd,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
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
