/// "2 days 9 hours", "5 hours", "45 minutes".
String formatDuration(Duration duration) {
  if (duration.isNegative) return '0 minutes';
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;

  String unit(int value, String name) => '$value $name${value == 1 ? '' : 's'}';

  if (days > 0) {
    return hours > 0
        ? '${unit(days, 'day')} ${unit(hours, 'hour')}'
        : unit(days, 'day');
  }
  if (hours > 0) {
    return minutes > 0
        ? '${unit(hours, 'hour')} ${unit(minutes, 'minute')}'
        : unit(hours, 'hour');
  }
  return unit(minutes, 'minute');
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// "Fri 19 Apr".
String formatDayMonth(DateTime time) =>
    '${_weekdays[time.weekday - 1]} ${time.day} ${_months[time.month - 1]}';

/// "19 Apr 2026".
String formatDate(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} ${time.year}';

/// 24-hour time such as "09:00".
String formatTime(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

/// "just now", "22m ago", "4h ago", "Yesterday", "4d ago", "2w ago".
String relativeTime(DateTime time, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(time);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 14) return '${difference.inDays}d ago';
  return '${difference.inDays ~/ 7}w ago';
}
