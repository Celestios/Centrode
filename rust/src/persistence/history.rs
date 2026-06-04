use anyhow::Result;
use serde::{Deserialize, Serialize};
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HistoryStatus {
    Applied,
    Undone,
}

impl HistoryStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            HistoryStatus::Applied => "applied",
            HistoryStatus::Undone => "undone",
        }
    }
}

impl Serialize for HistoryStatus {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(self.as_str())
    }
}

impl<'de> Deserialize<'de> for HistoryStatus {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        match s.as_str() {
            "applied" => Ok(HistoryStatus::Applied),
            "undone" => Ok(HistoryStatus::Undone),
            _ => Err(serde::de::Error::custom("expected applied or undone")),
        }
    }
}

impl SurrealValue for HistoryStatus {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Any
    }

    fn into_value(self) -> Value {
        self.as_str().to_string().into_value()
    }

    fn from_value(value: Value) -> std::result::Result<Self, surrealdb::types::Error> {
        let s = String::from_value(value)?;
        match s.as_str() {
            "applied" => Ok(HistoryStatus::Applied),
            "undone" => Ok(HistoryStatus::Undone),
            _ => Err(surrealdb::types::Error::thrown(format!("Expected applied or undone, found: {}", s))),
        }
    }
}

#[derive(Debug, SurrealValue)]
pub struct HistoryRecord {
    pub id: Option<String>,
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

        // Insert into DB (deserialize result as generic Value to bypass strict struct mapping)
        let _: Option<Value> = self.db.create("History").content(record).await?;

        // Enforce threshold (clean up old records)
        let mut count_response = self
            .db
            .query("SELECT VALUE count() FROM History WHERE status = 'applied' GROUP ALL")
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
                .query("SELECT id, created_at FROM History WHERE status = 'applied' ORDER BY created_at ASC, id ASC LIMIT $limit")
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
                "SELECT <string> id AS id, action_type, payload, status, created_at FROM History WHERE status = 'applied' ORDER BY created_at DESC LIMIT 1",
            )
            .await?;
        let record: Option<HistoryRecord> = response.take(0)?;

        if let Some(mut rec) = record {
            if let Some(ref id_str) = rec.id {
                let (table, key) = id_str.split_once(':').unwrap_or(("History", id_str));
                let record_id = RecordId::new(table, key);

                // Mark it as "undone"
                self.db
                    .query("UPDATE $id SET status = 'undone'")
                    .bind(("id", record_id))
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
            .query(
                "SELECT <string> id AS id, action_type, payload, status, created_at FROM History WHERE status = 'undone' ORDER BY created_at DESC LIMIT 1",
            )
            .await?;
        let record: Option<HistoryRecord> = response.take(0)?;

        if let Some(mut rec) = record {
            if let Some(ref id_str) = rec.id {
                let (table, key) = id_str.split_once(':').unwrap_or(("History", id_str));
                let record_id = RecordId::new(table, key);

                // Mark it as "applied"
                self.db
                    .query("UPDATE $id SET status = 'applied'")
                    .bind(("id", record_id))
                    .await?;

                rec.status = HistoryStatus::Applied;
                return Ok(Some(rec));
            }
        }
        Ok(None)
    }
}
