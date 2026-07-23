use crate::domain::id::TypedRecordId;
use crate::domain::relations::{IRelation, IRelationFields};
use crate::domain::traits::SurrealTable;
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, SurrealValue, Value};
use tracing::{debug, info};

impl Repository {
    pub async fn create_relation(&self, input: IRelation) -> Result<()> {
        let key = input.key.to_string();
        let in_id = input.in_;
        let out_id = input.out;
        let record = input.key.to_record_id();

        let mut res = self
            .db
            .query("RELATE $from -> $id -> $out CONTENT $data")
            .bind(("id", record))
            .bind(("from", in_id.to_record_id()))
            .bind(("out", out_id.to_record_id()))
            .bind(("data", input.fields))
            .await?;
        let created: Option<Value> = res.take(0)?;
        let _ = created.ok_or_else(|| anyhow::anyhow!("Failed to create Relation"))?;

        self.trigger_significance_update(&in_id).await?;
        self.trigger_significance_update(&out_id).await?;

        info!("REPO: Created Relation with ID: {}", key);
        info!("REPO: Created Relation from {:?} to {:?}", in_id, out_id);

        Ok(())
    }

    pub async fn get_relation(&self, table: String, key: String) -> Result<IRelation> {
        let clean_key = key.split(':').last().unwrap_or(&key);
        let record_id = if let Ok(u) = uuid::Uuid::parse_str(clean_key) {
            if let Ok(kind) = std::str::FromStr::from_str(&table) {
                crate::domain::id::TypedRecordId::new(kind, u).to_record_id()
            } else {
                RecordId::new(table, key)
            }
        } else {
            RecordId::new(table, key)
        };
        let val: Option<Value> = self.db.select(record_id).await?;
        let val = val.ok_or_else(|| anyhow::anyhow!("Relation not found"))?;
        IRelation::from_value(val).map_err(|e| anyhow::anyhow!("Failed to parse Relation: {}", e))
    }

    pub async fn delete_relation(&self, table: String, key: String) -> Result<()> {
        let clean_key = key.split(':').last().unwrap_or(&key);
        let record_id = if let Ok(u) = uuid::Uuid::parse_str(clean_key) {
            if let Ok(kind) = std::str::FromStr::from_str(&table) {
                crate::domain::id::TypedRecordId::new(kind, u).to_record_id()
            } else {
                RecordId::new(table, key)
            }
        } else {
            RecordId::new(table, key)
        };
        let _: Option<Value> = self.db.delete(record_id).await?;
        Ok(())
    }

    pub async fn update_relation(
        &self,
        table: String,
        key: String,
        fields: IRelationFields,
    ) -> Result<()> {
        debug!("REPO: update_relation called for {} ", key);
        let clean_key = key.split(':').last().unwrap_or(&key);
        let record_id = if let Ok(u) = uuid::Uuid::parse_str(clean_key) {
            if let Ok(kind) = std::str::FromStr::from_str(&table) {
                crate::domain::id::TypedRecordId::new(kind, u).to_record_id()
            } else {
                RecordId::new(table, key)
            }
        } else {
            RecordId::new(table, key)
        };
        debug!("REPO: Parsed relation RecordID: {:?}", record_id);

        let _: Option<Value> = self.db.update(record_id).merge(fields.into_value()).await?;
        Ok(())
    }

    pub async fn reroute_relation(
        &self,
        rel_id: TypedRecordId,
        from: TypedRecordId,
        to: TypedRecordId,
    ) -> Result<()> {
        let existing = self
            .get_relation(rel_id.table.table_name().to_string(), rel_id.key.to_string())
            .await?;

        let old_in_id = existing.in_;
        let old_out_id = existing.out;

        let mut updated = existing;
        updated.in_ = from;
        updated.out = to;

        let _: Option<Value> = self.db.delete(rel_id.into_record()).await?;

        self.create_relation(updated).await?;

        self.trigger_significance_update(&old_in_id).await?;
        self.trigger_significance_update(&old_out_id).await?;

        Ok(())
    }

    pub async fn get_connected_relations(&self, node_key: &str) -> Result<Vec<IRelation>> {
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let mut connected_relations = Vec::new();
        for val in relations_raw {
            if let Ok(rel) = IRelation::from_value(val) {
                if rel.in_.key.to_string() == node_key || rel.out.key.to_string() == node_key {
                    connected_relations.push(rel);
                }
            }
        }
        Ok(connected_relations)
    }
}
