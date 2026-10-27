const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "2h 45m"
String fmtHm(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m}m';
}

/// "2 h 45m"
String fmtHmSpaced(Duration d) => '${d.inHours} h ${d.inMinutes.remainder(60)}m';

/// "Oct 4, 2026"
String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "Oct4, 2026" – compact variant used in quiz history rows of the mock-up.
String fmtDateCompact(DateTime d) => '${_months[d.month - 1]}${d.day}, ${d.year}';

String fmtTime(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  return '${h12.toString().padLeft(2, '0')}:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Oct 26, 2026, 10:24 AM"
String fmtDateTime(DateTime d) => '${fmtDate(d)}, ${fmtTime(d)}';

/// "Today, 09:12 AM" or "Oct 18, 2026, 10:45 AM"
String fmtRelativeDay(DateTime d) {
  final n = DateTime.now();
  if (d.year == n.year && d.month == n.month && d.day == n.day) return 'Today, ${fmtTime(d)}';
  return fmtDateTime(d);
}

/// "2 days ago", "1 week ago"
String fmtAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays >= 14) return '${diff.inDays ~/ 7} weeks ago';
  if (diff.inDays >= 7) return '1 week ago';
  if (diff.inDays >= 2) return '${diff.inDays} days ago';
  if (diff.inDays == 1) return '1 day ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  return 'just now';
}

/// "4d ago", "1w ago", or month name for older uploads.
String fmtAgoShort(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays >= 28)
    return '${const [
      'Jan',
      'Feb',
      'March',
      'April',
      'May',
      'June',
      'July',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec'
    ][d.month - 1]} ${d.year}';
  if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w ago';
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  return 'today';
}

String fmtSize(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).round()} KB';
}

String two(int n) => n.toString().padLeft(2, '0');
