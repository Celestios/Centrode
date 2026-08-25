use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::patches::{EntityPatch, NodePatch};
use crate::domain::tags::TagEdge;
use crate::repo::patches::{apply_patch_check_position_db, patch_entity_db, patch_node_db};
use crate::repo::tags::SurrealTagRepository;
use crate::repo::traits::{NodeRepository, TagRepository};

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, Value};
use surrealdb::Surreal;
use tracing::info;

#[derive(Clone)]
pub struct SurrealNodeRepository {
    pub(crate) db: Surreal<Db>,
}

impl SurrealNodeRepository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }
}

impl NodeRepository for SurrealNodeRepository {
    async fn create_node(&self, input: Nodes) -> Result<()> {
        let record_id = input.id().to_record_id();
        let table = input.table_name();
        let key = input.id().to_string();
        let mut val = input.serialize_node();
        if let Value::Object(ref mut map) = val {
            map.remove("id");
        }
        let _: Option<Value> = self
            .db
            .create(record_id)
            .content(val)
            .await?;
        info!("REPO: Created Node of table {} with ID: {}", table, key);
        Ok(())
    }

    async fn get_node(&self, id: TypedRecordId) -> Result<Option<Nodes>> {
        let table = id.table.table_name().to_string();
        let record_id = id.to_record_id();

        let query_str = "SELECT * FROM $id";

        let mut res = self
            .db
            .query(query_str)
            .bind(("id", record_id))
            .await?;
        let val: Option<Value> = res.take(0)?;

        if let Some(mut node) = val.and_then(|v| Nodes::from_struct_value(&table, v).ok()) {
            if let Nodes::INode(ref mut inode) = node {
                let tag_repo = SurrealTagRepository::new(self.db.clone());
                for i in 0..inode.tags.len() {
                    if let TagEdge::Pointer(ptr) = &inode.tags[i] {
                        if let Ok(Some(tag)) = tag_repo.get_tag(ptr.key.to_string()).await {
                            inode.tags[i] = TagEdge::Hydrated(tag);
                        }
                    }
                }
            }
            return Ok(Some(node));
        }
        Ok(None)
    }

    async fn update_node(&self, input: Nodes) -> Result<()> {
        let table = input.table_name();
        let key = input.id().to_string();
        let record_id = input.id().to_record_id();
        let mut val = input.serialize_node();
        if let Value::Object(ref mut map) = val {
            map.remove("id");
        }
        let _: Option<Value> = self
            .db
            .update(record_id)
            .content(val)
            .await?;
        info!("REPO: Updated Node of table {} with ID: {}", table, key);
        Ok(())
    }

    async fn delete_node(&self, id: TypedRecordId) -> Result<()> {
        let query = "
            BEGIN TRANSACTION;
            DELETE IRelation WHERE in = $target OR out = $target;
            DELETE $target;
            COMMIT TRANSACTION;
        ";
        let record_id = id.to_record_id();
        tracing::trace!(
            "REPO: BEGIN TRANSACTION for cascading delete of {:?}",
            record_id
        );
        self.db
            .query(query)
            .bind(("target", record_id.clone()))
            .await?;

        Ok(())
    }

    async fn patch_node(&self, id: RecordId, patch: &NodePatch) -> Result<()> {
        patch_node_db(&self.db, id, patch).await
    }

    async fn patch_entity(&self, id: RecordId, patch: &EntityPatch) -> Result<()> {
        patch_entity_db(&self.db, id, patch).await
    }

    async fn apply_patch_check_position(&self, id: &TypedRecordId, patch: &EntityPatch) -> Result<bool> {
        apply_patch_check_position_db(&self.db, id, patch).await
    }
}
