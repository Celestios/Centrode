library;

enum LogOrigin {
  rust,
  dart;

  String get label => this == rust ? 'RUST' : 'DART';
}

class LogPayload implements Comparable<LogPayload> {
  final int time;
  final int level;
  final int seqId;
  final LogOrigin origin;
  final String message;

  LogPayload({
    required this.time,
    required this.level,
    required this.seqId,
    required this.origin,
    required this.message,
  });

  factory LogPayload.fromRustLog({
    required int tMicro,
    required int seqId,
    required int level,
    required String message,
  }) {
    return LogPayload(
      time: tMicro,
      seqId: seqId,
      level: level,
      origin: LogOrigin.rust,
      message: message,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'level': level,
      'seqId': seqId,
      'origin': origin.label,
      'message': message,
    };
  }

  static LogPayload fromMap(Map<String, dynamic> map) {
    final originStr = map['origin'] as String;
    final origin = originStr == 'RUST' ? LogOrigin.rust : LogOrigin.dart;
    return LogPayload(
      time: map['time'] as int,
      level: map['level'] as int,
      seqId: map['seqId'] as int,
      origin: origin,
      message: map['message'] as String,
    );
  }

  static String levelToLabel(int level) {
    switch (level) {
      case 5:
        return 'FATAL';
      case 4:
        return 'ERROR';
      case 3:
        return 'WARN';
      case 2:
        return 'INFO';
      case 1:
        return 'DEBUG';
      case 0:
        return 'TRACE';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  int compareTo(LogPayload other) {
    final tCmp = time.compareTo(other.time);
    if (tCmp != 0) return tCmp;
    final oCmp = origin.index.compareTo(other.origin.index);
    if (oCmp != 0) return oCmp;
    return seqId.compareTo(other.seqId);
  }

  @override
  String toString() {
    final ts = DateTime.fromMicrosecondsSinceEpoch(time).toIso8601String();
    return '[$ts] [${levelToLabel(level)}] [${origin.label}-$seqId] $message';
  }
}
