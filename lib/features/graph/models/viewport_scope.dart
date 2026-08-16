import 'dart:math' as math;
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Sealed base class representing an active viewport coordinate scope.
sealed class ViewportScope {
  final ViewportScope? parentScope;
  final RawUuid? scopeId;
  const ViewportScope({this.parentScope, this.scopeId});

  int get depth => parentScope == null ? 0 : parentScope!.depth + 1;
}

/// Root canvas interaction mode.
class RootViewportScope extends ViewportScope {
  const RootViewportScope() : super(parentScope: null, scopeId: null);
}

/// Focused container interaction mode.
class ContainerViewportScope extends ViewportScope {
  final RawUuid containerId;
  final Offset containerPositionInParent;
  final Size outerSize;
  final Matrix4 savedParentTransform;
  final double containerInitScale;

  ContainerViewportScope({
    required ViewportScope parentScope,
    required this.containerId,
    required this.containerPositionInParent,
    required this.outerSize,
    required this.savedParentTransform,
    required this.containerInitScale,
  }) : super(parentScope: parentScope, scopeId: containerId);

  /// Dynamic min scale for this scope allowing zoom-out past exit threshold.
  double get minScale => (containerInitScale * 0.2).clamp(0.05, 1.0);

  /// Dynamic max scale for this scope allowing nested zooming.
  double get maxScale => math.max(containerInitScale * 10.0, 50.0);

  /// Zoom-out exit threshold in container space.
  double get exitScale => containerInitScale * 0.65;
}
