import 'package:mycelium/src/rust/bridge/api.dart';
import '../../store/graph_data_controller.dart';
import 'base.dart';

class InstantiateTemplateCommand extends GraphCommand {
  @override
  String targetId;
  final AppHandle api;
  final double targetX;
  final double targetY;
  final GraphDataController controller;

  InstantiateTemplateCommand({
    required this.targetId,
    required this.api,
    required this.targetX,
    required this.targetY,
    required this.controller,
  });

  @override
  CommandCategory get category => CommandCategory.lifecycle;

  @override
  Future<void> execute() async {
    await api.instantiateTemplate(
      key: targetId,
      targetX: targetX,
      targetY: targetY,
    );
  }

  @override
  void undo() {
    // Rollback handled externally or no-op on FFI failure before commit.
  }

  @override
  void onSuccess() {
    controller.loadGraph();
  }
}
