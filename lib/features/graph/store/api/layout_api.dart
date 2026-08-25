import 'dart:async';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';

abstract interface class LayoutApi {
  Future<void> triggerLayoutOptimization({
    required LayoutConfig config,
    List<LayoutPatch> livePositions = const [],
  });
  Future<BoundingBox?> getOptArea();
  Future<void> setOptArea({BoundingBox? bounds});
  Future<(double, double)> computeAutoPlacement({
    required TypedRecordId sourceId,
    required PortSide portSide,
  });
  Future<void> setAlignmentConstraint({
    required List<TypedRecordId> nodeIds,
    required Axis axis,
  });
  Future<void> addAnchorSpring({
    required TypedRecordId nodeId,
    required double x,
    required double y,
    required double strength,
  });
}
