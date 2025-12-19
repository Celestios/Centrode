use anyhow::Result;
use surrealdb::Surreal;
use surrealdb::engine::local::Db;

pub struct Schema;

impl Schema {
    pub async fn init(db: &Surreal<Db>) -> Result<()> {

        // Define tables
        db.query("DEFINE TABLE inode SCHEMAFULL;").await?;
        db.query("DEFINE TABLE task_node SCHEMAFULL;").await?;
        db.query("DEFINE TABLE inter_node SCHEMAFULL;").await?;
        db.query("DEFINE TABLE relates_to SCHEMAFULL;").await?;
        db.query("DEFINE TABLE map_metadata SCHEMAFULL;").await?;

        // Define fields for inode
        db.query("DEFINE FIELD text ON TABLE inode TYPE option<string>;").await?;
        db.query("DEFINE FIELD layer ON TABLE inode TYPE int DEFAULT 1;").await?;
        db.query("DEFINE FIELD locked ON TABLE inode TYPE bool DEFAULT false;").await?;
        db.query("DEFINE FIELD tags ON TABLE inode TYPE array<string>;").await?;
        db.query("DEFINE FIELD position ON TABLE inode TYPE option<int>;").await?;
        db.query("DEFINE FIELD visual_formatting ON TABLE inode TYPE option<string>;").await?;
        db.query("DEFINE FIELD aliases ON TABLE inode TYPE array<string>;").await?;
        db.query("DEFINE FIELD comments ON TABLE inode TYPE array<string>;").await?;
        db.query("DEFINE FIELD attachment ON TABLE inode TYPE option<string>;").await?;
        db.query("DEFINE FIELD created_at ON TABLE inode TYPE datetime DEFAULT time::now();").await?;
        db.query("DEFINE FIELD updated_at ON TABLE inode TYPE datetime DEFAULT time::now();").await?;

        // Define fields for task_node
        db.query("DEFINE FIELD text ON TABLE task_node TYPE option<string>;").await?;
        db.query("DEFINE FIELD due_date ON TABLE task_node TYPE option<datetime>;").await?;
        db.query("DEFINE FIELD state ON TABLE task_node TYPE string;").await?;
        db.query("DEFINE FIELD visual_formatting ON TABLE task_node TYPE option<string>;").await?;
        db.query("DEFINE FIELD created_at ON TABLE task_node TYPE datetime DEFAULT time::now();").await?;
        db.query("DEFINE FIELD updated_at ON TABLE task_node TYPE datetime DEFAULT time::now();").await?;

        // Define fields for inter_node
        db.query("DEFINE FIELD verb ON TABLE inter_node TYPE string;").await?;
        db.query("DEFINE FIELD behavioral_features ON TABLE inter_node TYPE option<string>;").await?;
        db.query("DEFINE FIELD visual_formatting ON TABLE inter_node TYPE option<string>;").await?;
        db.query("DEFINE FIELD created_at ON TABLE inter_node TYPE datetime DEFAULT time::now();").await?;
        db.query("DEFINE FIELD updated_at ON TABLE inter_node TYPE datetime DEFAULT time::now();").await?;

        // Define fields for relates_to
        db.query("DEFINE FIELD in ON TABLE relates_to TYPE record<inode | task_node | inter_node>;").await?;
        db.query("DEFINE FIELD out ON TABLE relates_to TYPE record<inode | task_node | inter_node>;").await?;
        db.query("DEFINE FIELD verb ON TABLE relates_to TYPE string;").await?;
        db.query("DEFINE FIELD visual_formatting ON TABLE relates_to TYPE option<string>;").await?;
        db.query("DEFINE FIELD directionless ON TABLE relates_to TYPE bool;").await?;
        db.query("DEFINE FIELD layer ON TABLE relates_to TYPE int;").await?;
        db.query("DEFINE FIELD created_at ON TABLE relates_to TYPE datetime DEFAULT time::now();").await?;

        // Define fields for map_metadata
        db.query("DEFINE FIELD map_name ON TABLE map_metadata TYPE string;").await?;
        db.query("DEFINE FIELD created_at ON TABLE map_metadata TYPE datetime DEFAULT time::now();").await?;
        db.query("DEFINE FIELD author_id ON TABLE map_metadata TYPE record<user>;").await?;
        db.query("DEFINE FIELD viewport_state ON TABLE map_metadata TYPE object;").await?;
        db.query("DEFINE FIELD theme ON TABLE map_metadata TYPE object;").await?;

        // Indexes
        db.query("DEFINE INDEX node_tags ON TABLE inode FIELDS tags[*];").await?;
        db.query("DEFINE INDEX task_due_date ON TABLE task_node FIELDS due_date;").await?;
        db.query("DEFINE INDEX unique_relation ON TABLE relates_to FIELDS in, out, verb UNIQUE;").await?;

        Ok(())
    }
}