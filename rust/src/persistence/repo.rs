use crate::domain::analysis::DecaySignificanceStrategy;
use crate::domain::base_models::{IsTable, MapData, Record, RecordStrings};
use crate::domain::nodes::{
    INode, INodeFields, InterNode, InterNodeFields, Nodes, TaskNode, TaskNodeFields,
};
use crate::domain::relations::{IRelation, IRelationFields};

use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, SurrealValue, Value};
use surrealdb::Surreal;
use tracing::{debug, info};

#[derive(Clone)]
pub struct Repository {
    db: Surreal<Db>,
}

impl Repository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }

    pub async fn create_node(&self, input: Nodes) -> Result<()> {
        match input {
            Nodes::INode(node) => {
                let key = node.key.clone();
                let _: Option<INodeFields> = self
                    .db
                    .create((INode::LABEL, key.clone()))
                    .content(node.fields)
                    .await?;
                info!("REPO: Created InfoNode with ID: {}", key);
                Ok(())
            }
            Nodes::TaskNode(node) => {
                let key = node.key.clone();
                let _: Option<TaskNodeFields> = self
                    .db
                    .create((TaskNode::LABEL, key.clone()))
                    .content(node.fields)
                    .await?;
                info!("REPO: Created TaskNode with ID: {}", key);
                Ok(())
            }
            Nodes::InterNode(node) => {
                let key = node.key.clone();
                let _: Option<InterNodeFields> = self
                    .db
                    .create((InterNode::LABEL, key.clone()))
                    .content(node.fields)
                    .await?;
                info!("REPO: Created InterNode with ID: {}", key);
                Ok(())
            }
        }
    }

    pub async fn create_relation(&self, input: IRelation) -> Result<()> {
        let key = input.key.clone();
        let in_id = input.get_in_id();
        let out_id = input.get_out_id();

        let mut res = self
            .db
            .query("INSERT RELATION INTO IRelation $relation")
            .bind(("relation", input.to_db_value()))
            .await?;
        let created: Option<Value> = res.take(0)?;
        let _ = created.ok_or_else(|| anyhow::anyhow!("Failed to create Relation"))?;

        self.trigger_significance_update(&in_id).await?;
        self.trigger_significance_update(&out_id).await?;

        info!("REPO: Created Relation with ID: {}", key);
        info!("REPO: Created Relation from {:?} to {:?}", in_id, out_id);

        Ok(())
    }

    pub async fn trigger_significance_update(&self, node_id: &RecordId) -> Result<()> {
        let strategy = DecaySignificanceStrategy;

        let db_clone = self.db.clone();
        let id_clone = node_id.clone();

        tokio::spawn(async move {
            if let Err(e) = strategy.recalculate_area(&db_clone, id_clone).await {
                tracing::error!("Significance update failed: {}", e);
            }
            // TODO: Broadcast SignificanceUpdate packet via FFI Sink
        });

        Ok(())
    }

    pub async fn get_node(&self, table: String, key: String) -> Result<Option<Nodes>> {
        match table.as_str() {
            INode::LABEL => {
                let fields: Option<INodeFields> = self.db.select((table, key.clone())).await?;
                Ok(fields.map(|f| Nodes::INode(INode { key, fields: f })))
            }
            TaskNode::LABEL => {
                let fields: Option<TaskNodeFields> = self.db.select((table, key.clone())).await?;
                Ok(fields.map(|f| Nodes::TaskNode(TaskNode { key, fields: f })))
            }
            InterNode::LABEL => {
                let fields: Option<InterNodeFields> = self.db.select((table, key.clone())).await?;
                Ok(fields.map(|f| Nodes::InterNode(InterNode { key, fields: f })))
            }
            _ => Err(anyhow::anyhow!("Unknown node type with id: {:?}", key)),
        }
    }

    pub async fn get_graph_snapshot(
        &self,
    ) -> Result<(
        Vec<INode>,
        Vec<TaskNode>,
        Vec<InterNode>,
        Vec<IRelation>,
        MapData,
    )> {
        tracing::info!("Fetching graph snapshot...");

        tracing::debug!("Fetching INodes...");

        let inodes_raw: Vec<Value> = self.db.select(INode::LABEL).await?;

        let inodes: Vec<INode> = inodes_raw
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<INodeFields>()?;
                Some(INode { key, fields })
            })
            .collect();

        tracing::debug!("Fetched {} INodes", inodes.len());

        tracing::debug!("Fetching TaskNodes...");
        let tasks_raw: Vec<Value> = self.db.select(TaskNode::LABEL).await?;
        let tasks: Vec<TaskNode> = tasks_raw
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<TaskNodeFields>()?;
                Some(TaskNode { key, fields })
            })
            .collect();
        tracing::debug!("Fetched {} TaskNodes", tasks.len());

        tracing::debug!("Fetching InterNodes...");
        let inters_raw: Vec<Value> = self.db.select(InterNode::LABEL).await?;
        let inters: Vec<InterNode> = inters_raw
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<InterNodeFields>()?;
                Some(InterNode { key, fields })
            })
            .collect();
        tracing::debug!("Fetched {} InterNodes", inters.len());

        tracing::debug!("Fetching IRelations...");
        let relations_raw: Vec<Value> = self.db.select(IRelation::LABEL).await?;
        let relations: Vec<IRelation> = relations_raw
            .into_iter()
            .filter_map(IRelation::from_db_value)
            .collect();
        tracing::debug!("Fetched {} IRelations", relations.len());

        tracing::debug!("Fetching MapMetadata...");
        let metadata: Option<MapData> = self.db.select((MapData::LABEL, MapData::KEY)).await?;
        let metadata = metadata.ok_or_else(|| anyhow::anyhow!("MapMetadata not found"))?;

        Ok((inodes, tasks, inters, relations, metadata))
    }

    /// Clear all graph-related tables in the correct dependency order.
    /// This helper works with any handle that derefs to `Surreal<C>` (including a transaction).
    async fn clear_graph(&self) -> Result<()> {
        tracing::debug!("Clearing existing graph data...");

        let db = self.db.clone();
        let tx = db.begin().await?;

        tracing::debug!("Deleting existing IRelations...");
        let _: Vec<IRelation> = tx.delete(IRelation::LABEL).await?;
        tracing::debug!("Deleted all IRelations");

        tracing::debug!("Deleting existing InterNodes...");
        let _: Vec<InterNode> = tx.delete(InterNode::LABEL).await?;
        tracing::debug!("Deleted all InterNodes");

        tracing::debug!("Deleting existing TaskNodes...");
        let _: Vec<TaskNode> = tx.delete(TaskNode::LABEL).await?;
        tracing::debug!("Deleted all TaskNodes");

        tracing::debug!("Deleting existing INodes...");
        let _: Vec<INode> = tx.delete(INode::LABEL).await?;
        tracing::debug!("Deleted all INodes");

        tracing::debug!("Deleting existing MapMetadata...");
        let _: Vec<MapData> = tx.delete(MapData::LABEL).await?;
        tracing::debug!("Deleted all MapMetadata");

        tx.commit().await?;
        tracing::debug!("Graph cleared.");
        Ok(())
    }

    pub async fn set_graph_snapshot(
        &self,
        inodes: Vec<INode>,
        tasknodes: Vec<TaskNode>,
        internodes: Vec<InterNode>,
        irelations: Vec<IRelation>,
        metadata: MapData,
    ) -> Result<()> {
        tracing::info!("Storing graph snapshot atomically...");

        self.clear_graph().await?;
        let db = self.db.clone();
        let tx = db.begin().await?;

        tracing::debug!("Inserting {} INodes...", inodes.len());
        for inode in inodes {
            let _: Option<INodeFields> = tx
                .create(inode.get_record_id())
                .content(inode.fields)
                .await?;
        }

        tracing::debug!("Inserting {} TaskNodes...", tasknodes.len());
        for task in tasknodes {
            let _: Option<TaskNodeFields> = tx
                .create((TaskNode::LABEL, task.key.clone()))
                .content(task.fields)
                .await?;
        }

        tracing::debug!("Inserting {} InterNodes...", internodes.len());
        for inter in internodes {
            let _: Option<InterNodeFields> = tx
                .create((InterNode::LABEL, inter.key.clone()))
                .content(inter.fields)
                .await?;
        }

        tracing::debug!("Inserting {} IRelations...", irelations.len());
        if !irelations.is_empty() {
            let relation_vals: Vec<Value> = irelations
                .into_iter()
                .map(|relation| relation.to_db_value())
                .collect();

            let mut res = tx
                .query("INSERT RELATION INTO IRelation $relations")
                .bind(("relations", relation_vals))
                .await?;
            let _: Option<Value> = res.take(0)?;
        }

        tracing::debug!("Inserting MapMetadata...");
        let _: Option<MapData> = tx
            .create((MapData::LABEL, MapData::KEY))
            .content(metadata)
            .await?;

        tx.commit().await?;
        tracing::info!("Graph snapshot stored successfully.");

        Ok(())
    }

    pub async fn update_node(&self, input: Nodes) -> Result<()> {
        match input {
            Nodes::INode(node) => {
                let key = node.key.clone();
                let _: Option<INodeFields> = self
                    .db
                    .update((INode::LABEL, key.clone()))
                    .content(node.fields)
                    .await?;
                info!("REPO: Updated InfoNode with ID: {}", key);
                Ok(())
            }
            Nodes::TaskNode(node) => {
                let key = node.key.clone();
                let _: Option<TaskNodeFields> = self
                    .db
                    .update((TaskNode::LABEL, key.clone()))
                    .content(node.fields)
                    .await?;
                info!("REPO: Updated TaskNode with ID: {}", key);
                Ok(())
            }
            Nodes::InterNode(node) => {
                let key = node.key.clone();
                let _: Option<InterNodeFields> = self
                    .db
                    .update((InterNode::LABEL, key.clone()))
                    .content(node.fields)
                    .await?;
                info!("REPO: Updated InterNode with ID: {}", key);
                Ok(())
            }
        }
    }

    pub async fn delete_node(&self, table: String, key: String) -> Result<()> {
        let query = "
            BEGIN TRANSACTION;
            DELETE IRelation WHERE in = $target OR out = $target;
            DELETE $target;
            COMMIT TRANSACTION;
        ";
        let record_id = RecordId::new(table, key);
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

    pub async fn get_relation(&self, table: String, key: String) -> Result<IRelation> {
        let record_id = RecordId::new(table, key.clone());
        let val: Option<Value> = self.db.select(record_id).await?;
        let val = val.ok_or_else(|| anyhow::anyhow!("Relation not found"))?;
        IRelation::from_db_value(val).ok_or_else(|| anyhow::anyhow!("Failed to parse Relation"))
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
        record: RecordStrings,
        from: RecordStrings,
        to: RecordStrings,
    ) -> Result<()> {
        let record_id = RecordId::new(record.table, record.key);
        let from_record = RecordId::new(from.table, from.key);
        let to_record = RecordId::new(to.table, to.key);

        self.db
            .query("UPDATE $id SET in = $from, out = $to")
            .bind(("id", record_id))
            .bind(("from", from_record))
            .bind(("to", to_record))
            .await?;

        Ok(())
    }
}
