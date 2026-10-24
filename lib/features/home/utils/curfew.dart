/// Hostel curfew hour (22:00), matching the warden configuration in Figma.
const int curfewHour = 22;

/// "Good morning", "Good afternoon" or "Good evening".
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Time left until tonight's curfew, or null once it has passed.
Duration? timeUntilCurfew(DateTime now) {
  final curfew = DateTime(now.year, now.month, now.day, curfewHour);
  final remaining = curfew.difference(now);
  return remaining.isNegative || remaining == Duration.zero ? null : remaining;
}

/// "Curfew at 22:00 · in 46 min", "in 2 h 5 min" or "Curfew has passed".
String curfewMessage(DateTime now) {
  final remaining = timeUntilCurfew(now);
  if (remaining == null) return 'Curfew has passed';

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  final left = hours == 0
      ? '$minutes min'
      : minutes == 0
      ? '$hours h'
      : '$hours h $minutes min';
  return 'Curfew at $curfewHour:00 · in $left';
}
