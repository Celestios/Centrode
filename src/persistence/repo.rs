use super::templates;
use crate::domain::nodes::NodeInput;
use crate::domain::relations::RelationInput;
use crate::domain::config::MapConfig;
use anyhow::Result;
use surrealdb::Surreal;
use surrealdb::engine::local::Db;
use surrealdb::sql::Thing;
use serde_json::Value; // Add this import

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
    // Update the method signature and implementation
    pub async fn create_node(&self, input: NodeInput) -> Result<String> {

        match input {
            NodeInput::Info(node) => {
                let mut res = self.db.query(templates::CREATE_INODE)
                    .bind(("text", node.text))
                    .bind(("visual_formatting", node.visual_formatting))
                    .bind(("layer", node.layer))
                    .bind(("locked", node.locked))
                    .bind(("tags", node.tags))
                    .bind(("aliases", node.aliases))
                    .bind(("comments", node.comments))
                    .bind(("attachment", node.attachment))
                    .bind(("created_at", node.created_at))
                    .bind(("updated_at", node.updated_at))
                    .await?;

                let created: Option<crate::domain::nodes::INode> = res.take(0)?;
                Ok(created.and_then(|n| n.id).ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?)
            },
            NodeInput::Task(node) => {
                let mut res = self.db.query(templates::CREATE_TASK_NODE)
                    .bind(("text", node.text))
                    .bind(("due_date", node.due_date))
                    .bind(("state", node.state))
                    .bind(("visual_formatting", node.visual_formatting))
                    .bind(("created_at", node.created_at))
                    .bind(("updated_at", node.updated_at))
                    .await?;

                let created: Option<crate::domain::nodes::TaskNode> = res.take(0)?;
                Ok(created.and_then(|n| n.id).ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?)
            },
            NodeInput::Inter(node) => {
                let mut res = self.db.query(templates::CREATE_INTER_NODE)
                    .bind(("verb", node.verb))
                    .bind(("behavioral_features", node.behavioral_features))
                    .bind(("visual_formatting", node.visual_formatting))
                    .bind(("created_at", node.created_at))
                    .bind(("updated_at", node.updated_at))
                    .await?;

                let created: Option<crate::domain::nodes::InterNode> = res.take(0)?;
                Ok(created.and_then(|n| n.id).ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?)
            }
        }
    }

    pub async fn create_relation(&self, input: RelationInput) -> Result<String> {
        // [FIXED] Parse "table:id" strings into SurrealDB Record IDs (Things)
        let from = self.parse_record_id(&input.from)?;
        let to = self.parse_record_id(&input.to)?;

        let mut res = self.db.query(templates::CREATE_RELATION)
            .bind(("from", from))
            .bind(("to", to))
            .bind(("verb", input.props.verb))
            .bind(("visual_formatting", input.props.visual_formatting))
            .bind(("directionless", input.props.directionless))
            .bind(("layer", input.props.layer))
            .await?;

        let created: Option<crate::domain::relations::IRelation> = res.take(0)?;
        Ok(created.and_then(|r| r.id).ok_or_else(|| anyhow::anyhow!("Failed to retrieve ID"))?)
    }

    // [FIXED] Uses Thing::from to bypass non-exhaustive struct restrictions
    fn parse_record_id(&self, s: &str) -> Result<Thing> {
        let (table, id) = s.split_once(':')
            .ok_or_else(|| anyhow::anyhow!("Invalid record ID format: {}. Expected 'table:id'", s))?;

        Ok(Thing::from((table, id)))
    }

    pub async fn get_node(&self, table: String, id: String) -> Result<Option<crate::domain::nodes::NodeOutput>> {
        // [FIXED] Bind as a single Thing object
        let record_id = Thing::from((table.as_str(), id.as_str()));

        match table.as_str() {
            "inode" => {
                let mut res = self.db.query(templates::GET_NODE).bind(("id", record_id)).await?;
                let node: Option<crate::domain::nodes::INode> = res.take(0)?;
                Ok(node.map(crate::domain::nodes::NodeOutput::Info))
            },
            "task_node" => {
                let mut res = self.db.query(templates::GET_NODE).bind(("id", record_id)).await?;
                let node: Option<crate::domain::nodes::TaskNode> = res.take(0)?;
                Ok(node.map(crate::domain::nodes::NodeOutput::Task))
            },
            "inter_node" => {
                let mut res = self.db.query(templates::GET_NODE).bind(("id", record_id)).await?;
                let node: Option<crate::domain::nodes::InterNode> = res.take(0)?;
                Ok(node.map(crate::domain::nodes::NodeOutput::Inter))
            },
            _ => Err(anyhow::anyhow!("Unknown table type: {}", table))
        }
    }

    pub async fn get_graph_snapshot(&self) -> Result<(Vec<crate::domain::nodes::NodeOutput>, Vec<crate::domain::relations::IRelation>, Option<MapConfig>)> {
        // 1. Run all queries in parallel or batch
        let mut responses = self.db.query(templates::GET_ALL_INODES)
            .query(templates::GET_ALL_TASKS)
            .query(templates::GET_ALL_INTER_NODES)
            .query(templates::GET_ALL_RELATIONS)
            .query(templates::GET_MAP_METADATA)
            .await?;

        // 2. Unpack Results (Indices match query order)
        let inodes: Vec<crate::domain::nodes::INode> = responses.take(0)?;
        let tasks: Vec<crate::domain::nodes::TaskNode> = responses.take(1)?;
        let inters: Vec<crate::domain::nodes::InterNode> = responses.take(2)?;
        let relations: Vec<crate::domain::relations::IRelation> = responses.take(3)?;
        let metadata: Option<MapConfig> = responses.take(4).ok().and_then(|mut v: Vec<MapConfig>| v.pop());

        // 3. Combine Nodes into one Polymorphic Vector
        let mut all_nodes = Vec::new();
        for n in inodes { all_nodes.push(crate::domain::nodes::NodeOutput::Info(n)); }
        for t in tasks { all_nodes.push(crate::domain::nodes::NodeOutput::Task(t)); }
        for i in inters { all_nodes.push(crate::domain::nodes::NodeOutput::Inter(i)); }

        Ok((all_nodes, relations, metadata))
    }

    pub async fn get_map_config(&self) -> Result<Option<MapConfig>> {
        let mut res = self.db.query("SELECT * FROM map_metadata LIMIT 1;").await?;
        let config: Option<MapConfig> = res.take(0)?;
        Ok(config)
    }

    // [NEW] Dynamic Patching for Nodes
    pub async fn patch_node(&self, table: String, id: String, patch: Value) -> Result<String> {
        let record_id = Thing::from((table.as_str(), id.as_str()));

        // Uses SurrealDB's MERGE to update partial fields
        let mut res = self.db.query("UPDATE $id MERGE $patch RETURN id")
            .bind(("id", record_id))
            .bind(("patch", patch))
            .await?;

        // We expect a record ID back if successful
        let updated: Option<Thing> = res.take("id")?;
        Ok(updated.ok_or_else(|| anyhow::anyhow!("Failed to patch node: Record not found"))?.to_string())
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

        self.db.query(query)
            .bind(("target", record_id))
            .await?;

        Ok("Node and connected edges deleted successfully".to_string())
    }

    // [NEW] Relation Operations
    pub async fn get_relation(&self, id: String) -> Result<Option<crate::domain::relations::IRelation>> {
        let record_id = self.parse_record_id(&id)?;
        let mut res = self.db.query("SELECT * FROM $id").bind(("id", record_id)).await?;
        Ok(res.take(0)?)
    }

    pub async fn delete_relation(&self, id: String) -> Result<String> {
        let record_id = self.parse_record_id(&id)?;
        self.db.query("DELETE $id").bind(("id", record_id)).await?;
        Ok("Relation deleted".to_string())
    }

    pub async fn update_relation_properties(&self, id: String, patch: Value) -> Result<String> {
        let record_id = self.parse_record_id(&id)?;
        let mut res = self.db.query("UPDATE $id MERGE $patch RETURN id")
            .bind(("id", record_id))
            .bind(("patch", patch))
            .await?;

        let updated: Option<Thing> = res.take("id")?;
        Ok(updated.ok_or_else(|| anyhow::anyhow!("Failed to update relation"))?.to_string())
    }

    pub async fn reroute_relation(&self, id: String, new_from: String, new_to: String) -> Result<String> {
        let record_id = self.parse_record_id(&id)?;
        let from_record = self.parse_record_id(&new_from)?;
        let to_record = self.parse_record_id(&new_to)?;

        self.db.query("UPDATE $id SET in = $from, out = $to")
            .bind(("id", record_id))
            .bind(("from", from_record))
            .bind(("to", to_record))
            .await?;

        Ok("Relation rerouted".to_string())
    }
}