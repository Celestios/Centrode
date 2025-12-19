use super::db::Database;
use super::templates;
use crate::domain::nodes::NodeInput;
use crate::domain::relations::RelationInput;
use crate::domain::config::MapConfig;
use anyhow::Result;

pub struct Repository;

impl Repository {
    pub async fn create_node(id: String, input: NodeInput) -> Result<String> {
        let db = Database::get().await?;

        match input {
            NodeInput::Info(node) => {
                db.query(templates::CREATE_INODE)
                    .bind(("id", id.clone()))
                    .bind(("text", node.text))
                    .bind(("visual_formatting", node.visual_formatting))
                    .bind(("position", node.position))
                    .bind(("layer", node.layer))
                    .bind(("locked", node.locked))
                    .bind(("tags", node.tags))
                    .bind(("aliases", node.aliases))
                    .bind(("comments", node.comments))
                    .bind(("attachment", node.attachment))
                    .bind(("created_at", node.created_at))
                    .bind(("updated_at", node.updated_at))
                    .await?;
            },
            NodeInput::Task(node) => {
                db.query(templates::CREATE_TASK_NODE)
                    .bind(("id", id.clone()))
                    .bind(("text", node.text))
                    .bind(("due_date", node.due_date))
                    .bind(("state", node.state))
                    .bind(("visual_formatting", node.visual_formatting))
                    .bind(("created_at", node.created_at))
                    .bind(("updated_at", node.updated_at))
                    .await?;
            },
            NodeInput::Inter(node) => {
                // "Heavy Edges" are stored as nodes to allow them to be linked FROM
                db.query(templates::CREATE_INTER_NODE)
                    .bind(("id", id.clone()))
                    .bind(("verb", node.verb))
                    .bind(("behavioral_features", node.behavioral_features))
                    .bind(("visual_formatting", node.visual_formatting))
                    .bind(("created_at", node.created_at))
                    .bind(("updated_at", node.updated_at))
                    .await?;
            }
        }

        Ok(id)
    }

    pub async fn create_relation(input: RelationInput) -> Result<String> {
        let db = Database::get().await?;

        db.query(templates::CREATE_RELATION)
            .bind(("from", input.from))
            .bind(("to", input.to))
            .bind(("verb", input.props.verb))
            .bind(("visual_formatting", input.props.visual_formatting))
            .bind(("directionless", input.props.directionless))
            .bind(("layer", input.props.layer))
            .await?;

        // In a real scenario, you might return the Relation ID
        Ok("Relation Created".to_string())
    }

    pub async fn get_node(table: String, id: String) -> Result<Option<crate::domain::nodes::NodeOutput>> {
        let db = Database::get().await?;

        // 1. Fetch generic JSON first to determine structure, OR rely on the table name passed in.
        // relying on 'table' arg is more performant for now.

        match table.as_str() {
            "inode" => {
                let mut res = db.query(templates::GET_NODE).bind(("table", "inode")).bind(("id", id.clone())).await?;
                let node: Option<crate::domain::nodes::INode> = res.take(0)?;
                Ok(node.map(crate::domain::nodes::NodeOutput::Info))
            },
            "task_node" => {
                let mut res = db.query(templates::GET_NODE).bind(("table", "task_node")).bind(("id", id.clone())).await?;
                let node: Option<crate::domain::nodes::TaskNode> = res.take(0)?;
                Ok(node.map(crate::domain::nodes::NodeOutput::Task))
            },
            "inter_node" => {
                let mut res = db.query(templates::GET_NODE).bind(("table", "inter_node")).bind(("id", id.clone())).await?;
                let node: Option<crate::domain::nodes::InterNode> = res.take(0)?;
                Ok(node.map(crate::domain::nodes::NodeOutput::Inter))
            },
            _ => Err(anyhow::anyhow!("Unknown table type: {}", table))
        }
    }

    pub async fn get_graph_snapshot() -> Result<(Vec<crate::domain::nodes::NodeOutput>, Vec<crate::domain::relations::IRelation>, Option<MapConfig>)> {
        let db = Database::get().await?;

        // 1. Run all queries in parallel or batch
        let mut responses = db.query(templates::GET_ALL_INODES)
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

    pub async fn get_map_config() -> Result<Option<MapConfig>> {
        let db = Database::get().await?;

        let mut res = db.query("SELECT * FROM map_metadata LIMIT 1;").await?;
        let config: Option<MapConfig> = res.take(0)?;
        Ok(config)
    }
}