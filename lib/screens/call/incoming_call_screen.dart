import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../services/calling_service.dart';
import '../../widgets/user_avatar.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _acceptCall() {
    final calling = context.read<CallingService>();
    calling.onCallAccepted();
    final call = widget.call;
    final callerUser = UserModel(
      id: call.callerId,
      name: call.callerName,
      avatarUrl: call.callerAvatarUrl,
      email: '',
      createdAt: DateTime.now(),
    );
    final currentUser = UserModel(
      id: call.calleeId,
      name: call.calleeName,
      avatarUrl: call.calleeAvatarUrl,
      email: '',
      createdAt: DateTime.now(),
    );

    if (call.type == CallType.audio) {
      Navigator.of(context).pushNamed('/audio-call', arguments: {
        'call': call,
        'currentUser': currentUser,
        'remoteUser': callerUser,
      });
    } else {
      Navigator.of(context).pushNamed('/video-call', arguments: {
        'call': call,
        'currentUser': currentUser,
        'remoteUser': callerUser,
      });
    }
  }

  void _declineCall() {
    context.read<CallingService>().onCallRejected();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xE6000000),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                call.isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ScaleTransition(
                scale: _pulseAnimation,
                child: UserAvatar(
                  name: call.callerName,
                  avatarUrl: call.callerAvatarUrl,
                  size: 96,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                call.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                call.isVideo ? 'Video Call' : 'Audio Call',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decline
                  _ActionButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: AppColors.callDecline,
                    onTap: _declineCall,
                  ),
                  const SizedBox(width: 80),
                  // Accept
                  _ActionButton(
                    icon: call.isVideo ? Icons.videocam : Icons.call,
                    label: 'Accept',
                    color: AppColors.callAccept,
                    onTap: _acceptCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
