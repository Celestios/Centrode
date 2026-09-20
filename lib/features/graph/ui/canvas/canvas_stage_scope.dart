import 'package:flutter/widgets.dart';
import '../../presentation/canvas_lifecycle_coordinator.dart';

/// Read-only geometry data provided by CanvasStageScope.
class CanvasStageData {
  final BoxConstraints constraints;
  final Size size;

  const CanvasStageData({required this.constraints, required this.size});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasStageData &&
          runtimeType == other.runtimeType &&
          constraints == other.constraints &&
          size == other.size;

  @override
  int get hashCode => Object.hash(constraints, size);
}

/// Single root LayoutBuilder authority for the canvas subsystem.
/// Computes layout constraints once, memoizes size, and notifies the lifecycle coordinator
/// via post-frame callbacks only when physical constraints genuinely mutate.
class CanvasStageScope extends StatefulWidget {
  final CanvasLifecycleCoordinator lifecycleCoordinator;
  final Widget child;

  const CanvasStageScope({
    super.key,
    required this.lifecycleCoordinator,
    required this.child,
  });

  static CanvasStageData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_InheritedCanvasStageScope>();
    assert(scope != null, 'No CanvasStageScope found in context');
    return scope!.data;
  }

  @override
  State<CanvasStageScope> createState() => _CanvasStageScopeState();
}

class _CanvasStageScopeState extends State<CanvasStageScope> {
  Size _lastReportedSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = constraints.biggest;
        if (currentSize != _lastReportedSize && currentSize != Size.zero) {
          _lastReportedSize = currentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.lifecycleCoordinator.updateViewportDimensions(currentSize);
            }
          });
        }

        return _InheritedCanvasStageScope(
          data: CanvasStageData(constraints: constraints, size: currentSize),
          child: widget.child,
        );
      },
    );
  }
}

class _InheritedCanvasStageScope extends InheritedWidget {
  final CanvasStageData data;

  const _InheritedCanvasStageScope({required this.data, required super.child});

  @override
  bool updateShouldNotify(_InheritedCanvasStageScope oldWidget) =>
      data != oldWidget.data;
}
