use crate::domain::base_models::{IsTable, RecordStrings};
use crate::domain::relations::{IRelation, IRelationFields};
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::{RecordId, SurrealValue, Value};
use tracing::{debug, info};

impl Repository {
    pub async fn create_relation(&self, input: IRelation) -> Result<()> {
        let key = input.key.clone();
        let in_id = input.in_.clone();
        let out_id = input.out.clone();
        let record = RecordId::new(IRelation::LABEL, key.clone());

        let mut res = self
            .db
            .query("RELATE $from -> $record -> $out CONTENT $data")
            .bind(("record", record))
            .bind(("from", in_id.into_record()))
            .bind(("out", out_id.into_record()))
            .bind(("data", input))
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
        let record_id = RecordId::new(table, key.clone());
        let val: Option<Value> = self.db.select(record_id).await?;
        let val = val.ok_or_else(|| anyhow::anyhow!("Relation not found"))?;
        IRelation::from_value(val).map_err(|e| anyhow::anyhow!("Failed to parse Relation: {}", e))
    }

    pub async fn delete_relation(&self, table: String, key: String) -> Result<()> {
        let record_id = RecordId::new(table, key);
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
        let record_id = RecordId::new(table, key);
        debug!("REPO: Parsed relation RecordID: {:?}", record_id);

        let _: Option<Value> = self.db.update(record_id).merge(fields.into_value()).await?;
        Ok(())
    }

    pub async fn reroute_relation(
        &self,
        record_string: RecordStrings,
        from: RecordStrings,
        to: RecordStrings,
    ) -> Result<()> {
        let existing = self
            .get_relation(record_string.table.clone(), record_string.key.clone())
            .await?;

        let old_in_id = existing.in_.clone();
        let old_out_id = existing.out.clone();

        let mut updated = existing;
        updated.in_ = from;
        updated.out = to;

        let _: Option<Value> = self.db.delete(record_string.into_record()).await?;

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
                if rel.in_.key == node_key || rel.out.key == node_key {
                    connected_relations.push(rel);
                }
            }
        }
        Ok(connected_relations)
    }
}
