use crate::domain::id::TypedRecordId;
use crate::domain::patches::{EntityPatch, SymmetricEntityPatch};
use crate::domain::snapshot::HistoryStatus;
use crate::domain::traits::TableKind;
use crate::repo::traits::HistoryRepository;

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;

#[derive(Debug, Clone, SurrealValue)]
pub struct HistoryRecord {
    pub id: Option<RecordId>,
    pub action_type: String,
    pub payload: Value,
    pub status: HistoryStatus,
    pub created_at: i64,
}

pub struct HistoryManager<'a> {
    db: &'a Surreal<Db>,
    threshold: usize,
}

impl<'a> HistoryManager<'a> {
    pub fn new(db: &'a Surreal<Db>, threshold: usize) -> Self {
        Self { db, threshold }
    }

    pub async fn push_event(&self, action_type: &str, payload: Value) -> Result<()> {
        self.push_event_with_time(action_type, payload, chrono::Utc::now().timestamp_millis()).await
    }

    pub async fn push_event_with_time(&self, action_type: &str, payload: Value, timestamp: i64) -> Result<()> {
        self.db
            .query("DELETE History WHERE status = $status")
            .bind(("status", HistoryStatus::Undone.into_value()))
            .await?;

        let record = HistoryRecord {
            id: None,
            action_type: action_type.to_string(),
            payload,
            status: HistoryStatus::Applied,
            created_at: timestamp,
        };

        let _: Option<Value> = self.db.create(TableKind::History.table_name()).content(record).await?;

        let mut count_response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = $status GROUP ALL")
            .bind(("status", HistoryStatus::Applied.into_value()))
            .await?;
        let count_vec: Vec<i64> = count_response.take(0)?;
        let count = count_vec.first().copied().unwrap_or(0);

        if count > self.threshold as i64 {
            let limit = count - self.threshold as i64;
            #[derive(SurrealValue)]
            struct HistoryPrune {
                id: RecordId,
            }
            let mut select_response = self
                .db
                .query("SELECT id, created_at FROM History WHERE status = $status ORDER BY created_at ASC, id ASC LIMIT $limit")
                .bind(("status", HistoryStatus::Applied.into_value()))
                .bind(("limit", limit))
                .await?;
            let ids_to_delete: Vec<HistoryPrune> = select_response.take(0)?;
            for prune in ids_to_delete {
                let _: Option<Value> = self.db.delete(prune.id).await?;
            }
        }

        Ok(())
    }

    pub async fn undo(&self) -> Result<Option<HistoryRecord>> {
        let mut response = self
            .db
            .query(
                "SELECT id, action_type, payload, status, created_at FROM History WHERE status = $status ORDER BY created_at DESC, id DESC LIMIT 1",
            )
            .bind(("status", HistoryStatus::Applied.into_value()))
            .await?;
        let record: Option<HistoryRecord> = response.take(0)?;

        let Some(mut rec) = record else { return Ok(None); };
        let Some(ref record_id) = rec.id else { return Ok(Some(rec)); };

        self.db
            .query("UPDATE $id SET status = $status")
            .bind(("id", record_id.clone()))
            .bind(("status", HistoryStatus::Undone.into_value()))
            .await?;

        rec.status = HistoryStatus::Undone;
        Ok(Some(rec))
    }

    pub async fn redo(&self) -> Result<Option<HistoryRecord>> {
        let mut response = self
            .db
            .query(
                "SELECT id, action_type, payload, status, created_at FROM History WHERE status = $status ORDER BY created_at ASC, id ASC LIMIT 1",
            )
            .bind(("status", HistoryStatus::Undone.into_value()))
            .await?;
        let record: Option<HistoryRecord> = response.take(0)?;

        let Some(mut rec) = record else { return Ok(None); };
        let Some(ref record_id) = rec.id else { return Ok(Some(rec)); };

        self.db
            .query("UPDATE $id SET status = $status")
            .bind(("id", record_id.clone()))
            .bind(("status", HistoryStatus::Applied.into_value()))
            .await?;

        rec.status = HistoryStatus::Applied;
        Ok(Some(rec))
    }
}

#[derive(Clone)]
pub struct SurrealHistoryRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealHistoryRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}

impl HistoryRepository for SurrealHistoryRepository {
    async fn record_patch_history(
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

    async fn undo_count(&self) -> Result<u32> {
        let mut response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = $status GROUP ALL")
            .bind(("status", HistoryStatus::Applied.into_value()))
            .await?;
        let count: Vec<i64> = response.take(0)?;
        Ok(count.first().copied().unwrap_or(0) as u32)
    }

    async fn redo_count(&self) -> Result<u32> {
        let mut response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = $status GROUP ALL")
            .bind(("status", HistoryStatus::Undone.into_value()))
            .await?;
        let count: Vec<i64> = response.take(0)?;
        Ok(count.first().copied().unwrap_or(0) as u32)
    }

    async fn undo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.undo().await
    }

    async fn redo_event(&self) -> Result<Option<HistoryRecord>> {
        let history_manager = HistoryManager::new(&self.db, 100);
        history_manager.redo().await
    }
}
