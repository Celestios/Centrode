use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::domain::patches::{NodePatch, RelationPatch};
use flutter_rust_bridge::frb;
use std::sync::LazyLock;
use tokio::sync::broadcast;
use tracing::debug;

pub use crate::domain::patches::GraphDelta;

/// The Event Enum for the Graph Stream
/// This enum is serialized and sent to Flutter via the FFI stream.
#[frb]
#[derive(Debug, Clone)]
pub enum GraphEvent {
    /// Fine-grained node patch updates (e.g., single position move)
    NodeUpdated { id: TypedRecordId, patches: Vec<NodePatch> },
    /// Fine-grained relation patch updates (e.g., control point re-routing)
    RelationUpdated { id: TypedRecordId, patches: Vec<RelationPatch> },
    /// Atomic batch update for history undo/redo cascades or template instantiations
    BatchUpdated(GraphDelta),
    /// Elastic canvas boundary recalculation
    BoundaryUpdated(BoundingBox),
}

// Global broadcast channel for graph events (capacity of 1000 messages)
static GRAPH_STREAM: LazyLock<broadcast::Sender<GraphEvent>> = LazyLock::new(|| {
    let (tx, _rx) = broadcast::channel(1000);
    tx
});

/// Publishes an event to the Flutter UI asynchronously
pub fn publish_event(event: GraphEvent) {
    // It's okay if there are no receivers yet (Flutter hasn't connected)
    if let Err(e) = GRAPH_STREAM.send(event) {
        debug!("Graph stream publish skipped: No active listeners ({})", e);
    }
}

/// Subscribes to the global graph stream
pub fn subscribe_to_graph() -> broadcast::Receiver<GraphEvent> {
    GRAPH_STREAM.subscribe()
}
