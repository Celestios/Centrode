import 'graph_store.dart';
import 'graph_spatial.dart';
import 'graph_sync_engine.dart';
import '../../presentation/style_manager.dart';

/// Abstract facade that coordinates the different graph store modules.
///
/// Implemented by [GraphDataController] to provide access to shared services
/// without introducing circular dependencies or direct tightly-coupled references.
abstract class GraphStateFacade {
  GraphStore get store;
  GraphSpatial get spatial;
  GraphSyncEngine get syncEngine;
  StyleManager get styleManager;

  /// Callback when a sub-service encounters an error.
  void Function(String) get onError;

  /// Notifies the outer UI boundary that state has changed.
  void triggerUpdate();
}
