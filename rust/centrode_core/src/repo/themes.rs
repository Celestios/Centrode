use crate::domain::base_models::Record;
use crate::domain::id::TypedRecordId;
use crate::domain::theme::{MapTheme, ThemeFields};
use crate::domain::traits::TableKind;
use crate::repo::traits::ThemeRepository;

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};
use surrealdb::Surreal;

fn key_to_uuid(key: &RecordIdKey) -> Result<uuid::Uuid> {
    match key {
        RecordIdKey::Uuid(u) => Ok(**u),
        _ => Err(anyhow::anyhow!("Non-UUID key")),
    }
}

#[derive(Clone)]
pub struct SurrealThemeRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealThemeRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}

impl ThemeRepository for SurrealThemeRepository {
    async fn get_theme(&self, key: String) -> Result<Option<MapTheme>> {
        let record_id = RecordId::new(MapTheme::LABEL, key.clone());
        let val: Option<Value> = self.db.select(record_id).await?;
        match val {
            Some(v) => {
                let fields = ThemeFields::from_value(v)?;
                let u = uuid::Uuid::parse_str(&key).unwrap_or_else(|_| uuid::Uuid::nil());
                let typed_id = TypedRecordId::new(TableKind::MapTheme, u);
                Ok(Some(MapTheme {
                    key: typed_id,
                    fields,
                }))
            }
            None => Ok(None),
        }
    }

    async fn get_theme_by_key(&self, key: &str) -> Result<Option<MapTheme>> {
        let u = uuid::Uuid::parse_str(key).unwrap_or_else(|_| uuid::Uuid::nil());
        let typed_id = TypedRecordId::new(TableKind::MapTheme, u);
        let val: Option<Value> = self.db.select(typed_id.to_record_id()).await?;
        let fields = val.map(|v| ThemeFields::from_value(v)).transpose()?;
        Ok(fields.map(|f| MapTheme {
            key: typed_id,
            fields: f,
        }))
    }

    async fn save_theme(&self, theme: MapTheme) -> Result<MapTheme> {
        let record_id = theme.key.to_record_id();
        let _: Option<Value> = self
            .db
            .create(record_id)
            .content(theme.fields.clone().into_value())
            .await?;
        Ok(theme)
    }

    async fn list_themes(&self) -> Result<Vec<MapTheme>> {
        let vals: Vec<Value> = self.db.select(MapTheme::LABEL).await?;
        let mut result = Vec::new();
        for v in vals {
            if let Some(record) = Record::from_record_value(v) {
                if let Ok(fields) = ThemeFields::from_value(record.fields) {
                    let key = TypedRecordId::new(TableKind::MapTheme, key_to_uuid(&record.id.key)?);
                    result.push(MapTheme { key, fields });
                }
            }
        }
        Ok(result)
    }
}
