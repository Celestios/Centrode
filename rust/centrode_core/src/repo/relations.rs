use crate::domain::id::TypedRecordId;
use crate::domain::patches::RelationPatch;
use crate::domain::relations::{IRelation, IRelationFields};
use crate::repo::analysis::SurrealLayoutRepository;
use crate::repo::patches::patch_relation_db;
use crate::repo::traits::{LayoutRepository, RelationRepository};

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;
use tracing::{debug, info};

#[derive(Clone)]
pub struct SurrealRelationRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealRelationRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}

impl RelationRepository for SurrealRelationRepository {
    async fn create_relation(&self, input: IRelation) -> Result<()> {
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

        let layout_repo = SurrealLayoutRepository::new(self.db.clone());
        layout_repo.trigger_significance_update(&in_id).await?;
        layout_repo.trigger_significance_update(&out_id).await?;

        info!("REPO: Created Relation with ID: {}", key);
        info!("REPO: Created Relation from {:?} to {:?}", in_id, out_id);

        Ok(())
    }

    async fn get_relation(&self, id: TypedRecordId) -> Result<IRelation> {
        let record_id = id.to_record_id();
        let val: Option<Value> = self.db.select(record_id).await?;
        let val = val.ok_or_else(|| anyhow::anyhow!("Relation not found"))?;
        IRelation::from_value(val).map_err(|e| anyhow::anyhow!("Failed to parse Relation: {}", e))
    }

    async fn delete_relation(&self, id: TypedRecordId) -> Result<()> {
        let record_id = id.to_record_id();
        let _: Option<Value> = self.db.delete(record_id).await?;
        Ok(())
    }

    async fn update_relation(
        &self,
        id: TypedRecordId,
        fields: IRelationFields,
    ) -> Result<()> {
        debug!("REPO: update_relation called for {:?}", id);
        let record_id = id.to_record_id();
        let _: Option<Value> = self.db.update(record_id).merge(fields.into_value()).await?;
        Ok(())
    }

    async fn reroute_relation(
        &self,
        rel_id: TypedRecordId,
        updated: IRelation,
    ) -> Result<()> {
        let existing = self.get_relation(rel_id).await?;

        let old_in_id = existing.in_;
        let old_out_id = existing.out;

        let _: Option<Value> = self.db.delete(rel_id.to_record_id()).await?;

        self.create_relation(updated).await?;

        let layout_repo = SurrealLayoutRepository::new(self.db.clone());
        layout_repo.trigger_significance_update(&old_in_id).await?;
        layout_repo.trigger_significance_update(&old_out_id).await?;

        Ok(())
    }

    async fn get_connected_relations(&self, node_id: &TypedRecordId) -> Result<Vec<IRelation>> {
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let mut connected_relations = Vec::new();
        for val in relations_raw {
            if let Ok(rel) = IRelation::from_value(val) {
                if rel.in_ == *node_id || rel.out == *node_id {
                    connected_relations.push(rel);
                }
            }
        }
        Ok(connected_relations)
    }

    async fn get_all_relations(&self) -> Result<Vec<IRelation>> {
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let relations: Vec<IRelation> = relations_raw
            .into_iter()
            .filter_map(|val| IRelation::from_value(val).ok())
            .collect();
        Ok(relations)
    }

    async fn patch_relation(&self, id: RecordId, patch: &RelationPatch) -> Result<()> {
        patch_relation_db(&self.db, id, patch).await
    }
}
