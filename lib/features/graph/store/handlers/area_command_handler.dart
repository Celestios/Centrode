import 'package:centrode/src/rust/layout_engine/config.dart';
import 'package:centrode/src/rust/layout_engine/types.dart';
import 'package:centrode/src/rust/domain/base_models.dart';
import '../api/layout_api.dart';
import '../api/layout_config_defaults.dart';

/// Command handler managing OptArea boundaries and layout optimization passes.
class AreaCommandHandler {
  final LayoutApi _api;

  const AreaCommandHandler({
    required LayoutApi api,
  }) : _api = api;

  Future<void> triggerLayoutOptimization({
    LayoutConfig? config,
    required List<LayoutPatch> livePositions,
  }) async {
    await _api.triggerLayoutOptimization(
      config: config ?? defaultLayoutConfig(),
      livePositions: livePositions,
    );
  }

  Future<void> setOptArea({BoundingBox? bounds}) async {
    await _api.setOptArea(bounds: bounds);
  }
}
