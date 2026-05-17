use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;

#[derive(Debug, Clone, Copy, PartialEq, Eq, SurrealValue)]
pub enum HistoryStatus {
    Applied,
    Undone,
}

#[derive(Debug, SurrealValue)]
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
        // Clear the "undone" redo stack when a new action is performed
        self.db
            .query("DELETE History WHERE status = 'undone'")
            .await?;

        let record = HistoryRecord {
            id: None,
            action_type: action_type.to_string(),
            payload,
            status: HistoryStatus::Applied,
            created_at: chrono::Utc::now().timestamp_millis(),
        };

        // Insert into DB
        let _: Option<HistoryRecord> = self.db.create("History").content(record).await?;

        // Enforce threshold (clean up old records)
        let mut count_response = self
            .db
            .query("SELECT count() FROM History WHERE status = 'applied'")
            .await?;
        let count: Option<i64> = count_response.take(0)?;
        let count = count.unwrap_or(0);

        if count > self.threshold as i64 {
            let limit = count - self.threshold as i64;
            let _ = self
                .db
                .query(
                    "DELETE History WHERE status = 'applied' ORDER BY created_at ASC LIMIT $limit",
                )
                .bind(("limit", limit))
                .await?;
        }

        Ok(())
    }

    pub async fn undo(&self) -> Result<Option<HistoryRecord>> {
        // Get the latest "applied" event
        let mut response = self
            .db
            .query(
                "SELECT * FROM History WHERE status = 'applied' ORDER BY created_at DESC LIMIT 1",
            )
            .await?;
        let record: Option<HistoryRecord> = response.take(0)?;

        if let Some(mut rec) = record {
            if let Some(id) = &rec.id {
                // Mark it as "undone"
                self.db
                    .query("UPDATE $id SET status = 'undone'")
                    .bind(("id", id.clone()))
                    .await?;

                rec.status = HistoryStatus::Undone;
                return Ok(Some(rec));
            }
        }
        Ok(None)
    }

    pub async fn redo(&self) -> Result<Option<HistoryRecord>> {
        // Get the latest "undone" event (LIFO for redo)
        let mut response = self
            .db
            .query("SELECT * FROM History WHERE status = 'undone' ORDER BY created_at DESC LIMIT 1")
            .await?;
        let record: Option<HistoryRecord> = response.take(0)?;

        if let Some(mut rec) = record {
            if let Some(id) = &rec.id {
                // Mark it as "applied"
                self.db
                    .query("UPDATE $id SET status = 'applied'")
                    .bind(("id", id.clone()))
                    .await?;

                rec.status = HistoryStatus::Applied;
                return Ok(Some(rec));
            }
        }
        Ok(None)
    }
}
