use crate::domain::id::TypedRecordId;
use crate::domain::patches::{EntityPatch, SymmetricEntityPatch};
use crate::domain::snapshot::HistoryStatus;
use crate::persistence::history::{HistoryManager, HistoryRecord};
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::SurrealValue;

impl Repository {
    pub async fn record_patch_history(
        &self,
        id: TypedRecordId,
        forward: EntityPatch,
        reverse: EntityPatch,
    ) -> Result<()> {
        let history_manager = HistoryManager::new(&self.db, 100);
        let history_payload = SymmetricEntityPatch {
            id,
            forward,
            reverse,
        };
        history_manager
            .push_event("entity_patch", history_payload.into_value())
            .await?;
        Ok(())
    }

    pub async fn undo_count(&self) -> Result<u32> {
        let mut response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = $status GROUP ALL")
            .bind(("status", HistoryStatus::Applied.into_value()))
            .await?;
        let count: Vec<i64> = response.take(0)?;
        Ok(count.first().copied().unwrap_or(0) as u32)
    }

    pub async fn redo_count(&self) -> Result<u32> {
        let mut response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = $status GROUP ALL")
            .bind(("status", HistoryStatus::Undone.into_value()))
            .await?;
        let count: Vec<i64> = response.take(0)?;
        Ok(count.first().copied().unwrap_or(0) as u32)
    }

    pub async fn undo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.undo().await
    }

    pub async fn redo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.redo().await
    }
}
