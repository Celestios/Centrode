use crate::bridge::api::RelationEngine;
use crate::bridge::node_ffi::NodeFfi;
use crate::bridge::relation_ffi::RelationFfi;
use crate::domain::patches::SymmetricEntityPatch;
use crate::persistence::history::HistoryRecord;
use crate::persistence::repo::Repository;
use surrealdb::types::SurrealValue;
use std::sync::{Arc, Mutex};

pub struct HistoryFfi {
    repo: Repository,
}

impl HistoryFfi {
    pub fn new(repo: Repository) -> Self {
        Self { repo }
    }

    async fn apply_history_record_patch(
        &self,
        record: &HistoryRecord,
        is_forward: bool,
    ) -> anyhow::Result<()> {
        if record.action_type == "entity_patch" {
            let payload = SymmetricEntityPatch::from_value(record.payload.clone())?;
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
                NodeFfi::broadcast_boundaries(&self.repo).await;
            }
        }
        Ok(())
    }

    pub async fn undo(&self, relation_engine: Arc<Mutex<RelationEngine>>) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: undo called");
        let record = self.repo.undo_event().await?;
        if let Some(ref rec) = record {
            self.apply_history_record_patch(rec, false).await?;
        }
        let relation_ffi = RelationFfi::new(self.repo.clone(), relation_engine);
        relation_ffi.rebuild_node_cache().await;
        Ok(record)
    }

    pub async fn redo(&self, relation_engine: Arc<Mutex<RelationEngine>>) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: redo called");
        let record = self.repo.redo_event().await?;
        if let Some(ref rec) = record {
            self.apply_history_record_patch(rec, true).await?;
        }
        let relation_ffi = RelationFfi::new(self.repo.clone(), relation_engine);
        relation_ffi.rebuild_node_cache().await;
        Ok(record)
    }

    pub async fn undo_count(&self) -> anyhow::Result<u32> {
        self.repo.undo_count().await
    }

    pub async fn redo_count(&self) -> anyhow::Result<u32> {
        self.repo.redo_count().await
    }
}
