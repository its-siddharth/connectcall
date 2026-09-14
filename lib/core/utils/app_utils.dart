import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class AppUtils {
  AppUtils._();

  /// Formats a DateTime as a human-readable call time label
  static String formatCallTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(dt.year, dt.month, dt.day);

    if (callDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(dt)}';
    } else if (callDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  /// Formats duration in seconds to MM:SS
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Returns a relative time string (e.g., "2 minutes ago")
  static String timeAgo(DateTime dt) => timeago.format(dt);

  /// Validates an email address
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  /// Validates a phone number (basic)
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-]{7,15}$').hasMatch(phone.trim());
  }

  /// Returns an avatar background color based on name
  static Color avatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF0891B2),
      const Color(0xFF9333EA),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
