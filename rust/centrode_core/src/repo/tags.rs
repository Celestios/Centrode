use crate::domain::base_models::Record;
use crate::domain::id::TypedRecordId;
use crate::domain::tags::{Tag, TagFields};
use crate::domain::traits::TableKind;
use crate::repo::traits::TagRepository;

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordIdKey, SurrealValue, Value};
use surrealdb::Surreal;

#[derive(Clone)]
pub struct SurrealTagRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealTagRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}

impl TagRepository for SurrealTagRepository {
    async fn create_tag(&self, tag: Tag) -> Result<()> {
        let record_id = tag.key.to_record_id();
        let res: surrealdb::Result<Option<TagFields>> = self.db.create(record_id).content(tag.fields).await;
        match res {
            Ok(_) => Ok(()),
            Err(e) => {
                let err_str = e.to_string();
                if err_str.contains("unique") || err_str.contains("Index") || err_str.contains("exists") {
                    Err(anyhow::anyhow!("Tag name must be unique"))
                } else {
                    Err(e.into())
                }
            }
        }
    }

    async fn update_tag(&self, tag: Tag) -> Result<()> {
        let record_id = tag.key.to_record_id();
        let res: surrealdb::Result<Option<TagFields>> = self.db.update(record_id).content(tag.fields).await;
        match res {
            Ok(_) => Ok(()),
            Err(e) => {
                let err_str = e.to_string();
                if err_str.contains("unique") || err_str.contains("Index") || err_str.contains("exists") {
                    Err(anyhow::anyhow!("Tag name must be unique"))
                } else {
                    Err(e.into())
                }
            }
        }
    }

    async fn get_tag(&self, key: String) -> Result<Option<Tag>> {
        let u = uuid::Uuid::parse_str(&key)
            .map_err(|e| anyhow::anyhow!("Invalid tag key '{}': {}", key, e))?;
        let typed_id = TypedRecordId::new(TableKind::Tag, u);
        let fields: Option<TagFields> = self.db.select(typed_id.to_record_id()).await?;
        Ok(fields.map(|f| Tag { key: typed_id, fields: f }))
    }

    async fn get_all_tags(&self) -> Result<Vec<Tag>> {
        let tag_records: Vec<Value> = self.db.select(Tag::LABEL).await?;
        let tags: Vec<Tag> = tag_records
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let u = match &record.id.key {
                    RecordIdKey::Uuid(u) => {
                        uuid::Uuid::from_bytes(u.into_bytes())
                    }
                    _ => return None,
                };
                let key = TypedRecordId::new(TableKind::Tag, u);
                let fields = TagFields::from_value(record.fields).ok()?;
                Some(Tag { key, fields })
            })
            .collect();
        Ok(tags)
    }

    async fn delete_tag(&self, key: String) -> Result<()> {
        let u = uuid::Uuid::parse_str(&key)
            .map_err(|e| anyhow::anyhow!("Invalid tag key '{}': {}", key, e))?;
        let tag_id = TypedRecordId::new(TableKind::Tag, u).to_record_id();

        // Step 1: Remove the tag RecordId from all INode.tags arrays
        self.db
            .query("UPDATE INode SET tags -= $tag_id WHERE $tag_id INSIDE tags")
            .bind(("tag_id", tag_id.clone()))
            .await?;

        // Step 2: Delete the Tag record itself
        let _: Option<Value> = self.db.delete(tag_id).await?;
        Ok(())
    }
}
