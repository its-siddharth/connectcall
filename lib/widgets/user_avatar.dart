import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_utils.dart';
import '../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final String? name;
  final String? avatarUrl;
  final double size;
  final bool showStatus;
  final UserStatus? status;

  const UserAvatar({
    super.key,
    this.user,
    this.name,
    this.avatarUrl,
    this.size = 48,
    this.showStatus = false,
    this.status,
  });

  String get _name => user?.name ?? name ?? '?';
  String? get _avatarUrl => user?.avatarUrl ?? avatarUrl;
  UserStatus get _status => status ?? user?.status ?? UserStatus.offline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildAvatar(),
        if (showStatus)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(_avatarUrl!),
        backgroundColor: AppUtils.avatarColor(_name),
        child: null,
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppUtils.avatarColor(_name),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : '?';
  }

  Color get _statusColor {
    switch (_status) {
      case UserStatus.online:
        return AppColors.online;
      case UserStatus.offline:
        return AppColors.offline;
      case UserStatus.busy:
        return AppColors.busy;
    }
  }
}
