import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';
import 'user_avatar.dart';

/// Tile shown in the contacts list
class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.user,
    this.onAudioCall,
    this.onVideoCall,
    this.onTap,
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
                _CallIconButton(
                  icon: Icons.call_outlined,
                  color: AppColors.primary,
                  onTap: onAudioCall,
                  tooltip: 'Audio Call',
                ),
                const SizedBox(width: 4),
                _CallIconButton(
                  icon: Icons.videocam_outlined,
                  color: AppColors.secondary,
                  onTap: onVideoCall,
                  tooltip: 'Video Call',
                ),
              ],
            ),
          ],
        ),
      ),
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
                      call.isVideo ? Icons.videocam_outlined : Icons.call_outlined,
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
