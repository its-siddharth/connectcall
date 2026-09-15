import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';
import 'user_avatar.dart';

/// Tile shown in the contacts list.
///
/// When ZegoCloud is configured the call buttons use
/// [ZegoSendCallInvitationButton] so the callee's device receives a real
/// push invitation via the signalling plugin.
/// When Zego is not configured (mock mode) the plain [onAudioCall] /
/// [onVideoCall] callbacks are used instead.
class UserTile extends StatelessWidget {
  final UserModel user;

  /// Called in mock mode (no Zego credentials). Ignored when Zego is active.
  final VoidCallback? onAudioCall;

  /// Called in mock mode (no Zego credentials). Ignored when Zego is active.
  final VoidCallback? onVideoCall;

  final VoidCallback? onTap;

  /// The logged-in user's Zego user ID — required for the invitation button.
  final String? currentUserId;

  /// The logged-in user's display name — required for the invitation button.
  final String? currentUserName;

  const UserTile({
    super.key,
    required this.user,
    this.onAudioCall,
    this.onVideoCall,
    this.onTap,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(user: user, size: 50, showStatus: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: user.status == UserStatus.online
                          ? AppColors.online
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Call buttons
            Row(
              children: [
                _buildAudioButton(context),
                const SizedBox(width: 4),
                _buildVideoButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Button builders ──────────────────────────────────────────────────────

  Widget _buildAudioButton(BuildContext context) {
    // Use Zego invitation button if credentials are available and we have the
    // current user's identity.
    if (_zegoReady) {
      return _ZegoCallButtonWrapper(
        icon: Icons.call_outlined,
        color: AppColors.primary,
        tooltip: 'Audio Call',
        child: ZegoSendCallInvitationButton(
          invitees: [ZegoUIKitUser(id: user.id, name: user.name)],
          isVideoCall: false,
          resourceID: 'ConnectCall',
          buttonSize: const Size(36, 36),
          iconSize: const Size(20, 20),
          icon: ButtonIcon(
            icon: Icon(Icons.call_outlined, color: AppColors.primary, size: 20),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      );
    }
    // Fallback: mock mode
    return _CallIconButton(
      icon: Icons.call_outlined,
      color: AppColors.primary,
      onTap: onAudioCall,
      tooltip: 'Audio Call',
    );
  }

  Widget _buildVideoButton(BuildContext context) {
    if (_zegoReady) {
      return _ZegoCallButtonWrapper(
        icon: Icons.videocam_outlined,
        color: AppColors.secondary,
        tooltip: 'Video Call',
        child: ZegoSendCallInvitationButton(
          invitees: [ZegoUIKitUser(id: user.id, name: user.name)],
          isVideoCall: true,
          resourceID: 'ConnectCall',
          buttonSize: const Size(36, 36),
          iconSize: const Size(20, 20),
          icon: ButtonIcon(
            icon: Icon(Icons.videocam_outlined,
                color: AppColors.secondary, size: 20),
            backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
          ),
        ),
      );
    }
    return _CallIconButton(
      icon: Icons.videocam_outlined,
      color: AppColors.secondary,
      onTap: onVideoCall,
      tooltip: 'Video Call',
    );
  }

  /// True when Zego is configured and we have the caller's identity.
  bool get _zegoReady =>
      currentUserId != null &&
      currentUserId!.isNotEmpty &&
      currentUserName != null &&
      currentUserName!.isNotEmpty;
}

// ── Internal widgets ────────────────────────────────────────────────────────

/// Wraps a Zego button in a fixed-size tooltip container so it matches the
/// look of the plain _CallIconButton.
class _ZegoCallButtonWrapper extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final Widget child;

  const _ZegoCallButtonWrapper({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(width: 36, height: 36, child: child),
    );
  }
}

class _CallIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const _CallIconButton({
    required this.icon,
    required this.color,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ── Call history tile ────────────────────────────────────────────────────────

/// Tile for call history
class CallHistoryTile extends StatelessWidget {
  final CallModel call;
  final VoidCallback? onCallBack;

  const CallHistoryTile({
    super.key,
    required this.call,
    this.onCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = call.direction == CallDirection.incoming;
    final isMissed = call.isMissed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Direction icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _iconBgColor(isMissed, isIncoming),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _directionIcon(isMissed, isIncoming),
              size: 20,
              color: _iconColor(isMissed, isIncoming),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncoming ? call.callerName : call.calleeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      call.isVideo
                          ? Icons.videocam_outlined
                          : Icons.call_outlined,
                      size: 13,
                      color: AppColors.lightTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      call.typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightTextMuted,
                      ),
                    ),
                    if (isMissed) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '• Missed',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (call.formattedDuration.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${call.formattedDuration}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(call.startedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              if (onCallBack != null)
                InkWell(
                  onTap: onCallBack,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      call.isVideo
                          ? Icons.videocam_outlined
                          : Icons.call_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _iconBgColor(bool missed, bool incoming) {
    if (missed) return AppColors.error.withValues(alpha: 0.1);
    if (incoming) return AppColors.success.withValues(alpha: 0.1);
    return AppColors.primary.withValues(alpha: 0.1);
  }

  Color _iconColor(bool missed, bool incoming) {
    if (missed) return AppColors.error;
    if (incoming) return AppColors.success;
    return AppColors.primary;
  }

  IconData _directionIcon(bool missed, bool incoming) {
    if (missed) return Icons.call_missed;
    if (incoming) return Icons.call_received;
    return Icons.call_made;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(dt.year, dt.month, dt.day);
    if (callDate == today) {
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    }
    return '${dt.day}/${dt.month}';
  }
}
