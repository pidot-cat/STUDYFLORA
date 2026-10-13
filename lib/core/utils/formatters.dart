String formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

String two(int n) => n.toString().padLeft(2, '0');

/// 2h 15m -> "02h 15m"
String formatCountdown(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  return '${two(total.inHours)}h ${two(total.inMinutes % 60)}m';
}

/// 4404839 -> "4.2 MB", 320000 -> "313 KB"
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
