/// Log domain models for the Mycelium Central Logger.
///
/// This module handles the taxonomy and sorting logic for log entries
/// from both Rust and Dart origins.
library;

/// Represents the source of a log entry.
enum LogOrigin {
  /// Log originated from Rust backend (via FFI stream)
  rust,
  /// Log originated from Dart/Flutter frontend
  dart;

  String get label => this == rust ? "RUST" : "DART";
}

/// Represents a single log entry with full metadata.
///
/// The [compareTo] method implements the specification's sorting priority:
/// Time (T) → Origin → Sequence ID, which resolves interleaving issues
/// between Rust and Dart events.
class LogState {
  /// Microseconds since epoch
  final int t;

  /// Log level (L0 to L5)
  /// - L0: Trace
  /// - L1: Debug
  /// - L2: Info
  /// - L3: Warn
  /// - L4: Error
  /// - L5: Fatal
  final int level;

  /// Origin of the log (Rust or Dart)
  final LogOrigin origin;

  /// Sequence ID for ordering within the same origin and time
  final int seqId;

  /// The log message content
  final String message;

  LogState({
    required this.t,
    required this.level,
    required this.origin,
    required this.seqId,
    required this.message,
  });

  /// Compares logs based on T → Origin → SeqID as per specification.
  ///
  /// This ensures deterministic ordering when logs from different sources
  /// have the same timestamp.
  int compareTo(LogState other) {
    // Primary: Time comparison
    if (t != other.t) return t.compareTo(other.t);

    // Secondary: Origin comparison (Rust before Dart)
    if (origin != other.origin) {
      return origin.index.compareTo(other.origin.index);
    }

    // Tertiary: Sequence ID comparison
    return seqId.compareTo(other.seqId);
  }

  /// Formats the log entry as a human-readable string.
  ///
  /// Format: `[ISO8601_TIME] [L{level}] [{ORIGIN}-{seqId}] {message}`
  @override
  String toString() {
    final time = DateTime.fromMicrosecondsSinceEpoch(t).toIso8601String();
    return '[$time] [L$level] [${origin.label}-$seqId] $message';
  }

  /// Serializes the log entry to a map for isolate transfer.
  Map<String, dynamic> toMap() {
    return {
      't': t,
      'level': level,
      'origin': origin.index,
      'seqId': seqId,
      'message': message,
    };
  }

  /// Deserializes a log entry from a map (for isolate transfer).
  static LogState fromMap(Map<String, dynamic> map) {
    return LogState(
      t: map['t'] as int,
      level: map['level'] as int,
      origin: LogOrigin.values[map['origin'] as int],
      seqId: map['seqId'] as int,
      message: map['message'] as String,
    );
  }
}

/// Payload structure for log entries used in the logging pipeline.
///
/// This is used for both Rust FFI and Dart log entries, with the [origin]
/// field indicating the source.
class LogPayload {
  /// Microseconds since epoch
  final int time;

  /// Log level (0-5)
  final int level;

  /// Sequence ID
  final int seqId;

  /// Origin string ("RUST" or "DART")
  final String origin;

  /// Log message content
  final String message;

  LogPayload({
    required this.time,
    required this.level,
    required this.seqId,
    required this.origin,
    required this.message,
  });

  /// Converts to LogState with proper LogOrigin enum
  LogState toLogState() {
    return LogState(
      t: time,
      level: level,
      origin: origin.toUpperCase() == 'RUST' ? LogOrigin.rust : LogOrigin.dart,
      seqId: seqId,
      message: message,
    );
  }

  /// Deserializes from a map (for FFI compatibility)
  static LogPayload fromMap(Map<String, dynamic> map) {
    return LogPayload(
      time: map['time'] as int,
      level: map['level'] as int,
      seqId: map['seqId'] as int,
      origin: map['origin'] as String,
      message: map['message'] as String,
    );
  }
}

/// Payload structure for log entries received from Rust FFI.
///
/// This mirrors the expected Rust FFI structure. When the Rust side
/// implements the log stream, this class will be used to deserialize
/// the incoming data.
class RustLogPayload {
  /// Microseconds since epoch
  final int tMicro;

  /// Log level (0-5)
  final int level;

  /// Sequence ID from Rust
  final int sId;

  /// Log message content
  final String message;

  RustLogPayload({
    required this.tMicro,
    required this.level,
    required this.sId,
    required this.message,
  });

  /// Converts to LogPayload with Rust origin
  LogPayload toLogPayload() {
    return LogPayload(
      time: tMicro,
      level: level,
      seqId: sId,
      origin: 'RUST',
      message: message,
    );
  }

  /// Deserializes from a map (for FFI compatibility)
  static RustLogPayload fromMap(Map<String, dynamic> map) {
    return RustLogPayload(
      tMicro: map['tMicro'] as int,
      level: map['level'] as int,
      sId: map['sId'] as int,
      message: map['message'] as String,
    );
  }
}
