import 'package:flutter/foundation.dart';

/// Debug-only mixin that logs ChangeNotifier notification chains.
///
/// Enable globally by setting [DebugNotifierTracer.enabled] = true.
/// Enable per-notifier by mixing in [TraceableNotifier].
///
/// Output format (for analyze_builds.py --notifications):
///   [Notify] NotifierName -> ChildNotifierName (depth=2)
class DebugNotifierTracer {
  static bool enabled = false;
  static int _depth = 0;
  static final List<String> _stack = [];

  static void _push(String name) {
    if (!enabled) return;
    final parent = _stack.isNotEmpty ? _stack.last : '(root)';
    _stack.add(name);
    _depth++;
    // ignore: avoid_print
    print('[Notify] $parent -> $name (depth=$_depth)');
  }

  static void _pop() {
    if (!enabled) return;
    if (_stack.isNotEmpty) _stack.removeLast();
    _depth = (_depth > 0) ? _depth - 1 : 0;
  }

  static void reset() {
    _stack.clear();
    _depth = 0;
  }
}

/// Mixin for ChangeNotifiers that logs notification chains in debug mode.
///
/// Usage:
///   class MyNotifier extends ChangeNotifier with TraceableNotifier {
///     MyNotifier() : super('MyNotifier');
///   }
mixin TraceableNotifier on ChangeNotifier {
  String get notifierName;

  @override
  void notifyListeners() {
    if (DebugNotifierTracer.enabled) {
      DebugNotifierTracer._push(notifierName);
      try {
        super.notifyListeners();
      } finally {
        DebugNotifierTracer._pop();
      }
    } else {
      super.notifyListeners();
    }
  }
}
