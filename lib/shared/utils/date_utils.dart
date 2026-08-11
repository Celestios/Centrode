String formatTimestampShort(int timestampMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
}
