use anyhow::Result;
use crate::domain::snapshot::HistoryStatus;
use crate::domain::traits::TableKind;
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
        // Clear the "undone" redo stack when a new action is performed
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

        // Insert into DB (deserialize result as generic Value to bypass strict struct mapping)
        let _: Option<Value> = self.db.create(TableKind::History.table_name()).content(record).await?;

        // Enforce threshold (clean up old records)
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
        // Get the latest "applied" event
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

        // Mark it as "undone"
        self.db
            .query("UPDATE $id SET status = $status")
            .bind(("id", record_id.clone()))
            .bind(("status", HistoryStatus::Undone.into_value()))
            .await?;

        rec.status = HistoryStatus::Undone;
        Ok(Some(rec))
    }

    pub async fn redo(&self) -> Result<Option<HistoryRecord>> {
        // Get the oldest "undone" event (LIFO forward order for redo)
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

        // Mark it as "applied"
        self.db
            .query("UPDATE $id SET status = $status")
            .bind(("id", record_id.clone()))
            .bind(("status", HistoryStatus::Applied.into_value()))
            .await?;

        rec.status = HistoryStatus::Applied;
        Ok(Some(rec))
    }
}
