import 'dart:async';
import 'dart:ui';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../../src/rust/layout_engine/types.dart';
import 'package:centrode/src/rust/domain/styles.dart';
import 'graph_store.dart';

/// Module responsible for smoothing incoming layout tick steps from Rust.
///
/// Subdivides discrete [LayoutTickResult] steps into intermediate sub-steps,
/// LERPing node positions smoothly at high frame rates to make movement silky smooth.
class LayoutTickInterpolator {
  final int subStepsCount;
  final Duration subStepDuration;

  Timer? _interpolationTimer;
  final List<LayoutTickResult> _tickQueue = [];
  bool _isInterpolating = false;

  LayoutTickInterpolator({
    this.subStepsCount = 4,
    this.subStepDuration = const Duration(milliseconds: 4),
  });

  /// Enqueues a new [LayoutTickResult] tick for smooth sub-step interpolation.
  void processTick({
    required LayoutTickResult tick,
    required GraphStore store,
    required void Function(Set<RawUuid> movedNodeIds) onSubStep,
    required void Function(LayoutTickResult result) onConverged,
  }) {
    _tickQueue.add(tick);
    if (!_isInterpolating) {
      _runInterpolationLoop(
        store: store,
        onSubStep: onSubStep,
        onConverged: onConverged,
      );
    }
  }

  void _runInterpolationLoop({
    required GraphStore store,
    required void Function(Set<RawUuid> movedNodeIds) onSubStep,
    required void Function(LayoutTickResult result) onConverged,
  }) {
    if (_tickQueue.isEmpty) {
      _isInterpolating = false;
      return;
    }

    _isInterpolating = true;
    final currentTick = _tickQueue.removeAt(0);

    final startPositions = <RawUuid, Offset>{};
    final targetPositions = <RawUuid, Offset>{};

    for (final patch in currentTick.positionPatches) {
      final rawId = RawUuid.fromString(patch.id.key.uuid);
      final node = store.nodeLookup[rawId];
      if (node != null) {
        startPositions[rawId] = node.position;
        targetPositions[rawId] = Offset(patch.x, patch.y);
      }
    }

    int currentSubStep = 0;
    final effectiveSubSteps = _tickQueue.length > 6
        ? 1
        : _tickQueue.length > 2
            ? 2
            : subStepsCount;

    _interpolationTimer?.cancel();
    _interpolationTimer = Timer.periodic(subStepDuration, (timer) {
      currentSubStep++;
      final double progress = (currentSubStep / effectiveSubSteps).clamp(0.0, 1.0);

      final movedNodeIds = <RawUuid>{};

      for (final entry in targetPositions.entries) {
        final rawId = entry.key;
        final startPos = startPositions[rawId] ?? entry.value;
        final targetPos = entry.value;
        final interpolatedPos = Offset.lerp(startPos, targetPos, progress)!;

        final node = store.nodeLookup[rawId];
        if (node != null) {
          node.position = interpolatedPos;
          movedNodeIds.add(rawId);
        }
      }

      if (movedNodeIds.isNotEmpty) {
        onSubStep(movedNodeIds);
      }

      if (currentSubStep >= effectiveSubSteps) {
        timer.cancel();

        _applyPortPatches(store, currentTick.portPatches);

        if (currentTick.converged) {
          for (final remainingTick in _tickQueue) {
            for (final patch in remainingTick.positionPatches) {
              final rawId = RawUuid.fromString(patch.id.key.uuid);
              final node = store.nodeLookup[rawId];
              if (node != null) {
                node.position = Offset(patch.x, patch.y);
              }
            }
            _applyPortPatches(store, remainingTick.portPatches);
          }
          _tickQueue.clear();
          _isInterpolating = false;
          onConverged(currentTick);
        } else {
          _runInterpolationLoop(
            store: store,
            onSubStep: onSubStep,
            onConverged: onConverged,
          );
        }
      }
    });
  }

  void _applyPortPatches(GraphStore store, List<PortPatch> patches) {
    for (final patch in patches) {
      final relId = RawUuid.fromString(patch.relationId.key.uuid);
      final rel = store.relationLookup[relId];
      if (rel != null) {
        final baseLayout = rel.resolvedLayout ?? rel.layout;
        rel.resolvedLayout = RelationLayout(
          fromSide: patch.fromSide,
          toSide: patch.toSide,
          strategyType: baseLayout?.strategyType ?? 'default',
          controlPoint1: baseLayout?.controlPoint1,
          controlPoint2: baseLayout?.controlPoint2,
        );
      }
    }
  }

  /// Cancels any active interpolation loop and clears the tick queue.
  void cancel() {
    _interpolationTimer?.cancel();
    _tickQueue.clear();
    _isInterpolating = false;
  }
}
