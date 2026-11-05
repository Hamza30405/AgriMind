import 'package:flutter/material.dart';

String _two(int v) => v.toString().padLeft(2, '0');

/// "just now", "42s ago", "5 min ago", "3 h ago", "2 d ago"
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.isNegative || d.inSeconds < 10) return 'just now';
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// HH:mm:ss (24 h)
String clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// yyyy-MM-dd HH:mm
String dateTime(DateTime t) =>
    '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';

void showMessage(BuildContext context, String text, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
      ),
    );
}
