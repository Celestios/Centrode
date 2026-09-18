use anyhow::Result;
use surrealdb::types::RecordIdKey;

pub(crate) fn key_to_uuid(key: &RecordIdKey, context: &str) -> Result<uuid::Uuid> {
    match key {
        RecordIdKey::Uuid(u) => Ok(**u),
        _ => Err(anyhow::anyhow!("Non-UUID {} key", context)),
    }
}
