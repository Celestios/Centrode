import '../../store/graph_data_query.dart';
import '../../store/modules/graph_store.dart';
import '../../store/modules/graph_spatial.dart';

abstract class GraphStyleUpdater {
  void updateStyleForNode(String id);
  void updateStyleForRelation(String id);
}

/// Abstract interface for commands to access graph state.
/// Commands depend on this abstraction, not the concrete GraphDataController,
/// enforcing the Dependency Inversion Principle across the tier boundary.
abstract interface class GraphCommandContext {
  GraphStore get store;
  GraphSpatial get spatial;
  GraphStyleUpdater? get styleUpdater;

  void publishUpdate(GraphEntityUpdate update);
  void triggerUpdate();
  Future<void> loadGraph();
}
