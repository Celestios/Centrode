use crate::bridge::stream::GraphEvent;
use crate::domain::patches::{GraphDelta, SymmetricEntityPatch};
use crate::persistence::history::HistoryRecord;
use crate::services::graph_service::GraphService;
use surrealdb::types::SurrealValue;

impl GraphService {
    pub async fn undo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: undo called");
        let record = self.repo.undo_event().await?;
        if let Some(ref rec) = record {
            let delta = self.apply_history_record_patch(rec, false).await?;
            if let Some(delta) = delta {
                self.publish_event(GraphEvent::BatchUpdated(delta));
            }
        }
        self.rebuild_node_cache().await;
        Ok(record)
    }

    pub async fn redo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: redo called");
        let record = self.repo.redo_event().await?;
        if let Some(ref rec) = record {
            let delta = self.apply_history_record_patch(rec, true).await?;
            if let Some(delta) = delta {
                self.publish_event(GraphEvent::BatchUpdated(delta));
            }
        }
        self.rebuild_node_cache().await;
        Ok(record)
    }

    pub async fn undo_count(&self) -> anyhow::Result<u32> {
        self.repo.undo_count().await
    }

    pub async fn redo_count(&self) -> anyhow::Result<u32> {
        self.repo.redo_count().await
    }

    pub async fn apply_history_record_patch(
        &self,
        record: &HistoryRecord,
        is_forward: bool,
    ) -> anyhow::Result<Option<GraphDelta>> {
        if record.action_type == "entity_patch" {
            let payload = SymmetricEntityPatch::from_value(record.payload.clone())?;
            let delta = if is_forward {
                payload.to_forward_graph_delta()
            } else {
                payload.to_inverse_graph_delta()
            };
            let patch = if is_forward {
                &payload.forward
            } else {
                &payload.reverse
            };
            if self
                .repo
                .apply_patch_check_position(&payload.id, patch)
                .await?
            {
                self.broadcast_boundaries().await;
            }
            return Ok(Some(delta));
        }
        Ok(None)
    }
}
