/// Utility class for date and time formatting
class DateTimeUtils {
  /// Format timestamp for chat list (shows time if today, date if this week, full date otherwise)
  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      return _formatTime(dateTime);
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
      // This week - show day name
      return _getDayName(dateTime.weekday);
    } else if (messageDate.year == today.year) {
      // This year - show month and day
      return '${_getMonthName(dateTime.month)} ${dateTime.day}';
    } else {
      // Other years - show full date
      return '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
    }
  }

  /// Format timestamp for message bubbles
  static String formatMessageTime(DateTime dateTime) {
    return _formatTime(dateTime);
  }

  /// Format timestamp for message date headers
  static String formatMessageDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return _getDayName(dateTime.weekday);
    } else if (messageDate.year == today.year) {
      return '${_getMonthName(dateTime.month)} ${dateTime.day}';
    } else {
      return '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
    }
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  /// Get relative time string (e.g., "2 minutes ago", "1 hour ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatChatListTime(dateTime);
    }
  }

  /// Format time as HH:MM
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get day name from weekday number
  static String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Get month name from month number
  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
