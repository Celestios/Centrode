use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::tags::TagEdge;
use crate::persistence::repo::Repository;

use anyhow::Result;
use surrealdb::types::Value;
use tracing::info;

impl Repository {
    pub async fn create_node<N>(&self, input: N) -> Result<()>
    where
        N: IsNode,
    {
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

    pub async fn get_node(&self, id: TypedRecordId) -> Result<Option<Nodes>> {
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
                for i in 0..inode.tags.len() {
                    if let TagEdge::Pointer(ptr) = &inode.tags[i] {
                        if let Ok(Some(tag)) = self.get_tag(ptr.key.to_string()).await {
                            inode.tags[i] = TagEdge::Hydrated(tag);
                        }
                    }
                }
            }
            return Ok(Some(node));
        }
        Ok(None)
    }

    pub async fn update_node<N>(&self, input: N) -> Result<()>
    where
        N: IsNode,
    {
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

    pub async fn delete_node(&self, id: TypedRecordId) -> Result<()> {
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
}
