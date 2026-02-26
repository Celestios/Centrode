use super::templates;
use crate::domain::analysis::DecaySignificanceStrategy;
use crate::domain::base_models::MapConfig;
use crate::domain::nodes::{NodeInput, NodeOutput};
use crate::domain::relations::RelationInput;
use anyhow::Result;
use serde::Deserialize;
use serde_json::Value;
use surrealdb::engine::local::Db;
use surrealdb::sql::Thing;
use surrealdb::Surreal;
use tracing::{debug, error, info};

// [CHANGED] Struct now holds state (the DB connection)
#[derive(Clone)]
pub struct Repository {
    db: Surreal<Db>,
}

impl Repository {
    // [NEW] Constructor
    pub fn new(db: Surreal<Db>) -> Self {
        Self { db }
    }

    /// Exposes the underlying DB connection for testing/raw queries
    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }

    pub async fn create_node(&self, input: NodeInput) -> Result<String> {
        match input {
            NodeInput::Info(node) => {
                let created: Option<crate::domain::nodes::INode> =
                    self.db.create("inode").content(node).await?;
                let thing = created
                    .ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?
                    .id
                    .ok_or_else(|| anyhow::anyhow!("ID is missing from created node"))?;
                // Parse the "table:id" back to just "id"
                let (_, id) = thing.split_once(':').unwrap_or(("", &thing));
                info!("REPO: Created InfoNode with ID: {}", id); // [NEW]
                Ok(id.to_string())
            }
            NodeInput::Task(node) => {
                let created: Option<crate::domain::nodes::TaskNode> =
                    self.db.create("task_node").content(node).await?;
                let thing = created
                    .ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?
                    .id
                    .ok_or_else(|| anyhow::anyhow!("ID is missing from created node"))?;
                let (_, id) = thing.split_once(':').unwrap_or(("", &thing));
                info!("REPO: Created TaskNode with ID: {}", id); // [NEW]
                Ok(id.to_string())
            }
            NodeInput::Inter(node) => {
                let created: Option<crate::domain::nodes::InterNode> =
                    self.db.create("inter_node").content(node).await?;
                let thing = created
                    .ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?
                    .id
                    .ok_or_else(|| anyhow::anyhow!("ID is missing from created node"))?;
                let (_, id) = thing.split_once(':').unwrap_or(("", &thing));
                info!("REPO: Created InterNode with ID: {}", id); // [NEW]
                Ok(id.to_string())
            }
        }
    }

    pub async fn create_relation(&self, input: RelationInput) -> Result<String> {
        #[derive(Deserialize)]
        struct CreatedId {
            id: Thing,
        }

        let from = self.parse_record_id(&input.from)?;
        let to = self.parse_record_id(&input.to)?;

        let mut res = self
            .db
            .query(templates::CREATE_RELATION)
            .bind(("from", from.clone()))
            .bind(("to", to.clone()))
            .bind(("verb", input.props.verb.clone()))
            .bind(("aesthetics", input.props.aesthetics.clone()))
            .bind(("directionless", input.props.directionless))
            .bind(("layer", input.props.layer))
            .await
            .map_err(|e| {
                let err_msg = e.to_string();
                if err_msg.contains("unique") || err_msg.contains("index") {
                    tracing::warn!(
                        "REPO: Duplicate edge rejected by schema constraint ({} -> {})",
                        input.from,
                        input.to
                    );
                } else {
                    tracing::error!("REPO: Failed to create relation: {}", err_msg);
                }
                e
            })?;

        let created: Option<CreatedId> = res.take(0)?;
        let thing = created
            .ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?
            .id;

        let relation_id = thing.id.to_string();

        info!(
            "REPO: Created Relation {} -> {} [ID: {}]",
            input.from, input.to, relation_id
        ); // [NEW]

        // Trigger updates for both ends of the new connection
        self.trigger_significance_update(&input.from).await?;
        self.trigger_significance_update(&input.to).await?;

        Ok(relation_id)
    }

    pub async fn trigger_significance_update(&self, node_id: &str) -> Result<()> {
        let strategy = DecaySignificanceStrategy;
        // Run asynchronously to satisfy "Separate Response Packet" requirement
        let db_clone = self.db.clone();
        let id_clone = node_id.to_string();

        tokio::spawn(async move {
            if let Err(e) = strategy.recalculate_area(&db_clone, &id_clone).await {
                tracing::error!("Significance update failed: {}", e);
            }
            // TODO: Broadcast SignificanceUpdate packet via FFI Sink
        });

        Ok(())
    }

    // [FIXED] Uses Thing::from to bypass non-exhaustive struct restrictions
    fn parse_record_id(&self, s: &str) -> Result<Thing> {
        let (table, id) = s.split_once(':').ok_or_else(|| {
            anyhow::anyhow!("Invalid record ID format: {}. Expected 'table:id'", s)
        })?;

        Ok(Thing::from((table, id)))
    }

    pub async fn get_node(
        &self,
        table: String,
        id: String,
    ) -> Result<Option<crate::domain::nodes::NodeOutput>> {
        // [FIXED] Bind as a single Thing object
        let record_id = Thing::from((table.as_str(), id.as_str()));

        match table.as_str() {
            "inode" => {
                let mut res = self
                    .db
                    .query(templates::GET_NODE)
                    .bind(("id", record_id.clone()))
                    .await?;
                let node: Option<crate::domain::nodes::INode> = res.take(0)?;
                if node.is_none() {
                    tracing::trace!("REPO: get_node (inode) Miss for ID: {}", record_id);
                }
                Ok(node.map(crate::domain::nodes::NodeOutput::Info))
            }
            "task_node" => {
                let mut res = self
                    .db
                    .query(templates::GET_NODE)
                    .bind(("id", record_id.clone()))
                    .await?;
                let node: Option<crate::domain::nodes::TaskNode> = res.take(0)?;
                if node.is_none() {
                    tracing::trace!("REPO: get_node (task_node) Miss for ID: {}", record_id);
                }
                Ok(node.map(crate::domain::nodes::NodeOutput::Task))
            }
            "inter_node" => {
                let mut res = self
                    .db
                    .query(templates::GET_NODE)
                    .bind(("id", record_id.clone()))
                    .await?;
                let node: Option<crate::domain::nodes::InterNode> = res.take(0)?;
                if node.is_none() {
                    tracing::trace!("REPO: get_node (inter_node) Miss for ID: {}", record_id);
                }
                Ok(node.map(crate::domain::nodes::NodeOutput::Inter))
            }
            _ => {
                tracing::warn!("REPO: get_node failed: Unknown table type: {}", table);
                Err(anyhow::anyhow!("Unknown table type: {}", table))
            }
        }
    }

    pub async fn get_graph_snapshot(
        &self,
    ) -> Result<(
        Vec<crate::domain::nodes::NodeOutput>,
        Vec<crate::domain::relations::IRelation>,
        Option<MapConfig>,
    )> {
        // 1. Run all queries in parallel or batch
        let mut responses = self
            .db
            .query(templates::GET_ALL_INODES)
            .query(templates::GET_ALL_TASKS)
            .query(templates::GET_ALL_INTER_NODES)
            .query(templates::GET_ALL_RELATIONS)
            .query(templates::GET_MAP_METADATA)
            .await?;

        // 2. Unpack Results with granular error tracing
        let inodes: Vec<crate::domain::nodes::INode> = responses.take(0).map_err(|e| {
            error!("Failed to deserialize inodes (index 0): {}", e);
            e
        })?;
        let tasks: Vec<crate::domain::nodes::TaskNode> = responses.take(1).map_err(|e| {
            error!("Failed to deserialize tasks (index 1): {}", e);
            e
        })?;
        let inters: Vec<crate::domain::nodes::InterNode> = responses.take(2).map_err(|e| {
            error!("Failed to deserialize inter_nodes (index 2): {}", e);
            e
        })?;
        let relations: Vec<crate::domain::relations::IRelation> =
            responses.take(3).map_err(|e| {
                error!("Failed to deserialize relations (index 3): {}", e);
                e
            })?;
        let metadata: Option<MapConfig> = responses
            .take::<Vec<MapConfig>>(4)
            .map_err(|e| {
                error!("Failed to deserialize metadata (index 4): {}", e);
                e
            })?
            .pop();

        // 3. Combine Nodes into one Polymorphic Vector
        let mut all_nodes = Vec::new();
        for n in inodes {
            all_nodes.push(crate::domain::nodes::NodeOutput::Info(n));
        }
        for t in tasks {
            all_nodes.push(crate::domain::nodes::NodeOutput::Task(t));
        }
        for i in inters {
            all_nodes.push(crate::domain::nodes::NodeOutput::Inter(i));
        }

        Ok((all_nodes, relations, metadata))
    }

    pub async fn get_map_config(&self) -> Result<Option<MapConfig>> {
        let mut res = self.db.query("SELECT * FROM map_metadata LIMIT 1;").await?;
        let config: Option<MapConfig> = res.take(0)?;
        Ok(config)
    }

    // [NEW] Dynamic Patching for Nodes
    pub async fn patch_node(&self, table: String, id: String, patch: Value) -> Result<String> {
        debug!(
            "REPO: patch_node called for {}/{} with patch: {:?}",
            table, id, patch
        );

        // [VERIFICATION] Log the Thing being constructed
        let thing = Thing::from((table.as_str(), id.as_str()));
        debug!("REPO: Constructed Thing for update: {}", thing);

        let mut res = self
            .db
            .query("UPDATE $id MERGE $patch RETURN id")
            .bind(("id", thing.clone()))
            .bind(("patch", patch))
            .await?;

        let updated: Option<Thing> = res.take("id")?;

        match updated {
            Some(t) => {
                debug!(
                    "REPO: patch_node successful for {}. Result ID: {}",
                    thing, t
                );
                Ok(t.to_string())
            }
            None => {
                error!("REPO: patch_node failed for {}: Record not found", thing);
                Err(anyhow::anyhow!("Failed to patch node: Record not found"))
            }
        }
    }

    // [NEW] Cascading Delete for Nodes
    pub async fn delete_node(&self, table: String, id: String) -> Result<String> {
        let record_id = Thing::from((table.as_str(), id.as_str()));

        // Perform cleanup within a transaction to ensure integrity
        let query = "
            BEGIN TRANSACTION;
            DELETE relates_to WHERE in = $target OR out = $target;
            DELETE $target;
            COMMIT TRANSACTION;
        ";

        tracing::trace!(
            "REPO: BEGIN TRANSACTION for cascading delete of {}",
            record_id
        );
        self.db
            .query(query)
            .bind(("target", record_id.clone()))
            .await?;
        tracing::info!(
            "REPO: COMMIT TRANSACTION successful for cascading delete of {}",
            record_id
        );

        Ok("Node and connected edges deleted successfully".to_string())
    }

    // [NEW] Relation Operations
    pub async fn get_relation(
        &self,
        id: String,
    ) -> Result<Option<crate::domain::relations::IRelation>> {
        let record_id = self.parse_record_id(&id)?;
        let mut res = self
            .db
            .query("SELECT * FROM $id")
            .bind(("id", record_id.clone()))
            .await?;

        let relation: Option<crate::domain::relations::IRelation> = res.take(0)?;
        if relation.is_none() {
            tracing::trace!("REPO: get_relation Miss for ID: {}", record_id);
        }
        Ok(relation)
    }

    pub async fn delete_relation(&self, id: String) -> Result<String> {
        let record_id = self.parse_record_id(&id)?;
        self.db.query("DELETE $id").bind(("id", record_id)).await?;
        Ok("Relation deleted".to_string())
    }

    pub async fn update_relation_properties(&self, id: String, patch: Value) -> Result<String> {
        debug!(
            "REPO: update_relation_properties called for {} with patch: {:?}",
            id, patch
        );
        let record_id = self.parse_record_id(&id)?;
        debug!("REPO: Parsed relation RecordID: {}", record_id);

        let mut res = self
            .db
            .query("UPDATE $id MERGE $patch RETURN id")
            .bind(("id", record_id.clone()))
            .bind(("patch", patch))
            .await?;

        let updated: Option<Thing> = res.take("id")?;

        match updated {
            Some(thing) => {
                debug!("REPO: update_relation_properties successful for {}", thing);
                Ok(thing.to_string())
            }
            None => {
                error!(
                    "REPO: update_relation_properties failed for {}: Record not found",
                    record_id
                );
                Err(anyhow::anyhow!(
                    "Failed to update relation: Record not found"
                ))
            }
        }
    }

    pub async fn reroute_relation(
        &self,
        id: String,
        new_from: String,
        new_to: String,
    ) -> Result<String> {
        let record_id = self.parse_record_id(&id)?;
        let from_record = self.parse_record_id(&new_from)?;
        let to_record = self.parse_record_id(&new_to)?;

        self.db
            .query("UPDATE $id SET in = $from, out = $to")
            .bind(("id", record_id))
            .bind(("from", from_record))
            .bind(("to", to_record))
            .await?;

        Ok("Relation rerouted".to_string())
    }

    // [NEW] Smart Import Wrapper
    // This takes the raw list from the file and handles the table splitting logic internally.
    pub async fn import_dynamic_graph(
        &self,
        nodes: Vec<NodeOutput>,
        relations: Vec<crate::domain::relations::IRelation>,
        metadata: Option<MapConfig>,
    ) -> anyhow::Result<()> {
        let mut inodes = Vec::new();
        let mut tasks = Vec::new();
        let mut inters = Vec::new();

        // The "Sorting Hat" logic moves here, where it belongs (Data Layer)
        for node in nodes {
            match node {
                NodeOutput::Info(n) => inodes.push(n),
                NodeOutput::Task(n) => tasks.push(n),
                NodeOutput::Inter(n) => inters.push(n),
            }
        }

        // Delegate to the existing bulk insert
        self.import_graph_state(inodes, tasks, inters, relations, metadata)
            .await
    }

    pub async fn import_graph_state(
        &self,
        inodes: Vec<crate::domain::nodes::INode>,
        task_nodes: Vec<crate::domain::nodes::TaskNode>,
        inter_nodes: Vec<crate::domain::nodes::InterNode>,
        relations: Vec<crate::domain::relations::IRelation>,
        metadata: Option<MapConfig>,
    ) -> anyhow::Result<()> {
        tracing::warn!("REPO: Initiating destructive canvas wipe for bulk import."); // [NEW]
        tracing::info!(
            "REPO: Import Payload: {} nodes, {} relations",
            inodes.len() + task_nodes.len() + inter_nodes.len(),
            relations.len()
        ); // [NEW]

        tracing::trace!("REPO: BEGIN TRANSACTION for bulk import.");

        // TRANSACTION: "All or Nothing"
        // We delete everything then insert everything.
        // IDs are preserved because the Structs contain the `id: Option<Thing>` field,
        // and SurrealDB respects provided IDs on INSERT.
        let sql = "
            BEGIN TRANSACTION;

            -- 1. Wipe Canvas
            DELETE inode;
            DELETE task_node;
            DELETE inter_node;
            DELETE relates_to;
            DELETE map_metadata;

            -- 2. Bulk Insert
            -- Note: We use $vars to prevent injection and handle large datasets efficiently
            INSERT INTO inode $inodes;
            INSERT INTO task_node $task_nodes;
            INSERT INTO inter_node $inter_nodes;
            INSERT INTO relates_to $relations;
            INSERT INTO map_metadata $metadata;

            COMMIT TRANSACTION;
        ";

        self.db
            .query(sql)
            .bind(("inodes", inodes))
            .bind(("task_nodes", task_nodes))
            .bind(("inter_nodes", inter_nodes))
            .bind(("relations", relations))
            .bind(("metadata", metadata))
            .await?;

        tracing::info!("REPO: Bulk import transaction committed successfully."); // [NEW]
        Ok(())
    }
}
