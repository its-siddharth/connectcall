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

class AudioCallScreen extends StatefulWidget {
  final CallModel call;
  final UserModel currentUser;
  final UserModel remoteUser;

  const AudioCallScreen({
    super.key,
    required this.call,
    required this.currentUser,
    required this.remoteUser,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  // Mock-mode state
  bool _micMuted = false;
  bool _speakerOn = false;
  bool _connecting = true;
  bool _permissionGranted = false;
  Timer? _connectTimer;
  String _statusText = 'Calling...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      _showPermissionDialog('Microphone', permanentlyDenied: true);
      return;
    }
    if (status.isDenied) {
      _showPermissionDialog('Microphone');
      return;
    }

    setState(() => _permissionGranted = true);

    // If Zego is configured, the ZegoUIKitPrebuiltCall widget handles
    // the connection entirely — no mock timer needed.
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
              ? '$permission permission is permanently denied. Please enable it in App Settings.'
              : '$permission access is required to make calls.',
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
              if (permanentlyDenied) {
                await openAppSettings();
              }
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
    // Use real Zego call if credentials are set AND permission is granted
    if (ZegoService.isConfigured && _permissionGranted) {
      return ZegoService.buildAudioCall(
        call: widget.call,
        currentUser: widget.currentUser,
        onCallEnd: _endCall,
      );
    }
    // Show loading while permissions are being requested
    if (!_permissionGranted) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
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
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              durationText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            UserAvatar(user: widget.remoteUser, size: 100),
            const SizedBox(height: 20),
            Text(
              widget.remoteUser.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.remoteUser.email,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _connectionIndicator(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallControl(
                    icon: _micMuted ? Icons.mic_off : Icons.mic,
                    label: _micMuted ? 'Unmute' : 'Mute',
                    onTap: () => setState(() => _micMuted = !_micMuted),
                    active: _micMuted,
                  ),
                  _EndCallButton(onTap: _endCall),
                  _CallControl(
                    icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    onTap: () => setState(() => _speakerOn = !_speakerOn),
                    active: _speakerOn,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionIndicator() {
    final isConnected = !_connecting;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? AppColors.online : AppColors.warning,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'Connected' : 'Connecting...',
          style: TextStyle(
            color: isConnected ? AppColors.online : AppColors.warning,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Shared call control widgets ───────────────────────────────────────────────

class _CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _CallControl({
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.callEnd,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          const Text(
            'End',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
