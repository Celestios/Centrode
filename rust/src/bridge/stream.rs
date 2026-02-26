use crate::domain::base_models::BoundingBox;
use crate::domain::nodes::NodeOutput;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use serde::Serialize;
use tokio::sync::broadcast;
use tracing::debug;

/// The Event Enum for the Graph Stream
/// This enum is serialized and sent to Flutter via the FFI stream.
#[frb]
#[derive(Debug, Clone, Serialize)]
pub enum GraphEvent {
    NodeUpdated(NodeOutput),
    NodeDeleted(String),
    RelationUpdated,
    SnapshotLoaded,
    BoundaryUpdated(BoundingBox), // NEW: The asynchronous boundary push
}

lazy_static! {
    // Global broadcast channel for graph events (capacity of 100 messages)
    static ref GRAPH_STREAM: broadcast::Sender<GraphEvent> = {
        let (tx, _rx) = broadcast::channel(100);
        tx
    };
}

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
