import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/calling_service.dart';
import '../../services/zego_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common_button.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.read<AuthProvider>().currentUser;
    final calling = context.read<CallingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: UserAvatar(user: user, size: 96, showStatus: true),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _StatusChip(status: user.status),
            const SizedBox(height: 32),
            // Call buttons — use Zego invitation buttons when configured
            if (currentUser != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ZegoService.isConfigured
                          ? _ZegoProfileCallButton(
                              callee: user,
                              isVideo: false,
                            )
                          : CommonButton(
                              label: 'Audio Call',
                              icon: Icons.call_outlined,
                              onPressed: () => _startCall(
                                context,
                                currentUser,
                                user,
                                CallType.audio,
                                calling,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ZegoService.isConfigured
                          ? _ZegoProfileCallButton(
                              callee: user,
                              isVideo: true,
                            )
                          : CommonButton(
                              label: 'Video Call',
                              icon: Icons.videocam_outlined,
                              onPressed: () => _startCall(
                                context,
                                currentUser,
                                user,
                                CallType.video,
                                calling,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            const Divider(indent: 24, endIndent: 24),
            // Info rows
            _InfoRow(label: 'Name', value: user.name),
            _InfoRow(label: 'Email', value: user.email),
            if (user.phone != null && user.phone!.isNotEmpty)
              _InfoRow(label: 'Phone', value: user.phone!),
            _InfoRow(label: 'Status', value: user.statusLabel),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _startCall(
    BuildContext context,
    UserModel caller,
    UserModel callee,
    CallType type,
    CallingService calling,
  ) {
    final call = calling.initiateCall(caller: caller, callee: callee, type: type);
    if (type == CallType.audio) {
      Navigator.of(context).pushNamed('/audio-call', arguments: {
        'call': call,
        'currentUser': caller,
        'remoteUser': callee,
      });
    } else {
      Navigator.of(context).pushNamed('/video-call', arguments: {
        'call': call,
        'currentUser': caller,
        'remoteUser': callee,
      });
    }
  }
}

/// Full-width styled button that wraps [ZegoSendCallInvitationButton].
class _ZegoProfileCallButton extends StatelessWidget {
  final UserModel callee;
  final bool isVideo;
  const _ZegoProfileCallButton({required this.callee, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    final color = isVideo ? AppColors.secondary : AppColors.primary;
    final label = isVideo ? 'Video Call' : 'Audio Call';
    final icon = isVideo ? Icons.videocam_outlined : Icons.call_outlined;

    return SizedBox(
      height: 48,
      child: ZegoSendCallInvitationButton(
        invitees: [ZegoUIKitUser(id: callee.id, name: callee.name)],
        isVideoCall: isVideo,
        resourceID: 'ConnectCall',
        buttonSize: const Size(double.infinity, 48),
        iconSize: const Size(20, 20),
        icon: ButtonIcon(
          icon: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final UserStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case UserStatus.online:
        color = AppColors.online;
        break;
      case UserStatus.offline:
        color = AppColors.offline;
        break;
      case UserStatus.busy:
        color = AppColors.busy;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.name[0].toUpperCase() + status.name.substring(1),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
