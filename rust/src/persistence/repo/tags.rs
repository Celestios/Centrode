use crate::domain::base_models::{IsTable, Record};
use crate::domain::tags::{Tag, TagFields};
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, Value};

impl Repository {
    pub async fn create_tag(&self, tag: Tag) -> Result<()> {
        let name_lower = tag.fields.name.to_lowercase();
        let mut res = self
            .db
            .query("SELECT * FROM Tag WHERE string::lowercase(name) = $name")
            .bind(("name", name_lower))
            .await?;
        let existing: Vec<Value> = res.take(0)?;
        if !existing.is_empty() {
            return Err(anyhow::anyhow!("Tag name must be unique"));
        }

        let record_id = RecordId::new(Tag::LABEL, tag.key.clone());
        let _: Option<TagFields> = self.db.create(record_id).content(tag.fields).await?;
        Ok(())
    }

    pub async fn update_tag(&self, tag: Tag) -> Result<()> {
        let name_lower = tag.fields.name.to_lowercase();
        let record_id = RecordId::new(Tag::LABEL, tag.key.clone());
        let mut res = self
            .db
            .query("SELECT * FROM Tag WHERE string::lowercase(name) = $name AND id != $id")
            .bind(("name", name_lower))
            .bind(("id", record_id.clone()))
            .await?;
        let existing: Vec<Value> = res.take(0)?;
        if !existing.is_empty() {
            return Err(anyhow::anyhow!("Tag name must be unique"));
        }

        let _: Option<TagFields> = self.db.update(record_id).content(tag.fields).await?;
        Ok(())
    }

    pub async fn get_tag(&self, key: String) -> Result<Option<Tag>> {
        let record_id = RecordId::new(Tag::LABEL, key.clone());
        let fields: Option<TagFields> = self.db.select(record_id).await?;
        Ok(fields.map(|f| Tag { key, fields: f }))
    }

    pub async fn get_all_tags(&self) -> Result<Vec<Tag>> {
        let tag_records: Vec<Value> = self.db.select(Tag::LABEL).await?;
        let tags: Vec<Tag> = tag_records
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<TagFields>()?;
                Some(Tag { key, fields })
            })
            .collect();
        Ok(tags)
    }

    pub async fn delete_tag(&self, key: String) -> Result<()> {
        let tag_id = RecordId::new(Tag::LABEL, key);

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
