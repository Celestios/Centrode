use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub struct Schema;

impl Schema {
    pub async fn init(db: &Surreal<Db>) -> Result<()> {
        // Define tables
        db.query("DEFINE TABLE inode SCHEMAFULL;").await?;
        db.query("DEFINE TABLE task_node SCHEMAFULL;").await?;
        db.query("DEFINE TABLE inter_node SCHEMAFULL;").await?;
        db.query("DEFINE TABLE relates_to TYPE RELATION SCHEMAFULL;")
            .await?;
        db.query("DEFINE TABLE theme SCHEMAFULL;").await?;
        db.query("DEFINE TABLE map_metadata SCHEMALESS;").await?;

        // --- Shared Schema Definition Helpers ---
        let define_content = |table: &str| -> String {
            format!("
                DEFINE FIELD content ON TABLE {table} TYPE object;
                DEFINE FIELD content.text ON TABLE {table} TYPE string;
                DEFINE FIELD content.blocks ON TABLE {table} TYPE array<object>;
                DEFINE FIELD content.blocks[*] ON TABLE {table} TYPE object;
                DEFINE FIELD content.blocks[*].block_type ON TABLE {table} TYPE string;
                DEFINE FIELD content.blocks[*].content ON TABLE {table} TYPE array<object>;
                DEFINE FIELD content.blocks[*].content[*] ON TABLE {table} TYPE object;
                DEFINE FIELD content.blocks[*].content[*].inline_type ON TABLE {table} TYPE string;
                DEFINE FIELD content.blocks[*].content[*].text ON TABLE {table} TYPE string;
                DEFINE FIELD content.blocks[*].content[*].marks ON TABLE {table} TYPE option<array<object>>;
                DEFINE FIELD content.blocks[*].content[*].marks[*] ON TABLE {table} TYPE object;
                DEFINE FIELD content.blocks[*].content[*].marks[*].mark_type ON TABLE {table} TYPE string;
                DEFINE FIELD content.blocks[*].content[*].marks[*].attrs ON TABLE {table} TYPE option<object>;
                DEFINE FIELD content.blocks[*].content[*].marks[*].attrs.href ON TABLE {table} TYPE option<string>;
                DEFINE FIELD content.blocks[*].attrs ON TABLE {table} TYPE option<object>;
                DEFINE FIELD content.blocks[*].attrs.level ON TABLE {table} TYPE option<int>;
                DEFINE FIELD content.blocks[*].attrs.language ON TABLE {table} TYPE option<string>;
            ")
        };

        let define_position = |table: &str| -> String {
            format!(
                "
                DEFINE FIELD position ON TABLE {table} TYPE object;
                DEFINE FIELD position.x ON TABLE {table} TYPE int;
                DEFINE FIELD position.y ON TABLE {table} TYPE int;
                DEFINE FIELD position.z ON TABLE {table} TYPE int;
            "
            )
        };

        let define_comments = |table: &str| -> String {
            format!(
                "
                DEFINE FIELD comments ON TABLE {table} TYPE array<object>;
                DEFINE FIELD comments[*] ON TABLE {table} TYPE object;
                DEFINE FIELD comments[*].text ON TABLE {table} TYPE string;
                DEFINE FIELD comments[*].created_at ON TABLE {table} TYPE int;
            "
            )
        };

        db.query(define_content("inode")).await?;
        db.query(define_position("inode")).await?;
        db.query(define_comments("inode")).await?;
        db.query("DEFINE FIELD aesthetics ON TABLE inode TYPE option<string>;")
            .await?;
        db.query("DEFINE FIELD locked ON TABLE inode TYPE bool DEFAULT false;")
            .await?;
        db.query("DEFINE FIELD tags ON TABLE inode TYPE array<string>;")
            .await?;
        db.query("DEFINE FIELD aliases ON TABLE inode TYPE array<string>;")
            .await?;
        db.query("DEFINE FIELD attachment ON TABLE inode TYPE option<string>;")
            .await?;
        db.query("DEFINE FIELD created_at ON TABLE inode TYPE int;")
            .await?;
        db.query("DEFINE FIELD updated_at ON TABLE inode TYPE int;")
            .await?;

        // Define fields for task_node
        db.query(define_content("task_node")).await?;
        db.query(define_position("task_node")).await?;
        db.query("DEFINE FIELD aesthetics ON TABLE task_node TYPE option<string>;")
            .await?;
        db.query("DEFINE FIELD due_date ON TABLE task_node TYPE option<int>;")
            .await?;
        db.query("DEFINE FIELD state ON TABLE task_node TYPE string;")
            .await?;
        db.query("DEFINE FIELD created_at ON TABLE task_node TYPE int;")
            .await?;
        db.query("DEFINE FIELD updated_at ON TABLE task_node TYPE int;")
            .await?;

        // Define fields for inter_node
        db.query(define_position("inter_node")).await?;
        db.query("DEFINE FIELD aesthetics ON TABLE inter_node TYPE option<string>;")
            .await?;
        db.query("DEFINE FIELD verb ON TABLE inter_node TYPE string;")
            .await?;
        db.query("DEFINE FIELD behavioral_features ON TABLE inter_node TYPE option<string>;")
            .await?;
        db.query("DEFINE FIELD created_at ON TABLE inter_node TYPE int;")
            .await?;
        db.query("DEFINE FIELD updated_at ON TABLE inter_node TYPE int;")
            .await?;

        // Define fields for relates_to
        db.query(
            "DEFINE FIELD in ON TABLE relates_to TYPE record<inode | task_node | inter_node>;",
        )
        .await?;
        db.query(
            "DEFINE FIELD out ON TABLE relates_to TYPE record<inode | task_node | inter_node>;",
        )
        .await?;
        db.query("DEFINE FIELD verb ON TABLE relates_to TYPE string;")
            .await?;
        db.query("DEFINE FIELD aesthetics ON TABLE relates_to TYPE option<string>;")
            .await?;
        db.query("DEFINE FIELD directionless ON TABLE relates_to TYPE bool;")
            .await?;
        db.query("DEFINE FIELD layer ON TABLE relates_to TYPE int;")
            .await?;
        db.query("DEFINE FIELD created_at ON TABLE relates_to TYPE int;")
            .await?;
        db.query("DEFINE FIELD updated_at ON TABLE relates_to TYPE int;")
            .await?;

        // Define fields for map_metadata
        db.query("DEFINE FIELD map_name ON TABLE map_metadata TYPE string;")
            .await?;
        db.query("DEFINE FIELD created_at ON TABLE map_metadata TYPE int DEFAULT time::unix(time::now());").await?;

        // Viewport State
        db.query("DEFINE FIELD viewport_state ON TABLE map_metadata TYPE object;")
            .await?;
        db.query("DEFINE FIELD viewport_state.x_offset ON TABLE map_metadata TYPE float;")
            .await?;
        db.query("DEFINE FIELD viewport_state.y_offset ON TABLE map_metadata TYPE float;")
            .await?;
        db.query("DEFINE FIELD viewport_state.zoom_level ON TABLE map_metadata TYPE float;")
            .await?;
        db.query("DEFINE FIELD viewport_state.active_view ON TABLE map_metadata TYPE string;")
            .await?;

        // Theme Table Definition (Dumb Receiver)
        db.query("DEFINE FIELD name ON TABLE theme TYPE string;")
            .await?;
        db.query("DEFINE FIELD config ON TABLE theme TYPE string;")
            .await?;

        // Active Theme on Map Metadata
        db.query("DEFINE FIELD active_theme_id ON TABLE map_metadata TYPE option<record<theme>>;")
            .await?;

        // Indexes
        db.query("DEFINE INDEX node_tags ON TABLE inode FIELDS tags[*];")
            .await?;
        db.query("DEFINE INDEX task_due_date ON TABLE task_node FIELDS due_date;")
            .await?;
        db.query("DEFINE INDEX unique_relation ON TABLE relates_to FIELDS in, out, verb UNIQUE;")
            .await?;

        // -----------------------------------------------------------------------------
        // Content Property Schema (Native SurrealDB Objects)
        // -----------------------------------------------------------------------------

        // Content blocks array - allows querying inside the document model
        // Note: SurrealDB supports nested object queries natively

        // Indexes for common content queries
        // Find all nodes with bold text
        db.query(
            "
            DEFINE INDEX content_bold_marks ON TABLE inode 
            FIELDS content.blocks[*].content[*].marks[*].mark_type;
        ",
        )
        .await?;

        // Find all nodes with links
        db.query(
            "
            DEFINE INDEX content_links ON TABLE inode 
            FIELDS content.blocks[*].content[*].marks[*].attrs.href;
        ",
        )
        .await?;

        // Find all heading blocks
        db.query(
            "
            DEFINE INDEX content_headings ON TABLE inode 
            FIELDS content.blocks[*].block_type;
        ",
        )
        .await?;

        // Define the 'simple' analyzer for full-text search
        db.query("DEFINE ANALYZER simple TOKENIZERS blank, class FILTERS lowercase;")
            .await?;

        // Full-text search index on derived text
        db.query(
            "
            DEFINE INDEX content_text_search ON TABLE inode 
            FIELDS content.text 
            SEARCH ANALYZER simple BM25 HIGHLIGHTS;
        ",
        )
        .await?;

        // Same content indexes for task_node
        db.query(
            "
            DEFINE INDEX task_content_bold_marks ON TABLE task_node 
            FIELDS content.blocks[*].content[*].marks[*].mark_type;
        ",
        )
        .await?;

        db.query(
            "
            DEFINE INDEX task_content_links ON TABLE task_node 
            FIELDS content.blocks[*].content[*].marks[*].attrs.href;
        ",
        )
        .await?;

        db.query(
            "
            DEFINE INDEX task_content_headings ON TABLE task_node 
            FIELDS content.blocks[*].block_type;
        ",
        )
        .await?;

        db.query(
            "
            DEFINE INDEX task_content_text_search ON TABLE task_node 
            FIELDS content.text 
            SEARCH ANALYZER simple BM25 HIGHLIGHTS;
        ",
        )
        .await?;

        Ok(())
    }

    /// Migration helper to convert old content format to new block-based format
    /// Call this once during upgrade from older versions
    pub async fn migrate_content_format(db: &Surreal<Db>) -> Result<()> {
        // Migrate inode content from old format (text + document_ast string) to new format (blocks)
        db.query(
            "
            UPDATE inode SET content = {
                text: content.text,
                blocks: [{
                    block_type: 'paragraph',
                    content: [{
                        inline_type: 'text',
                        text: content.text,
                        marks: NONE
                    }],
                    attrs: NONE
                }]
            }
            WHERE content.blocks IS NONE;
        ",
        )
        .await?;

        // Migrate task_node content
        db.query(
            "
            UPDATE task_node SET content = {
                text: content.text,
                blocks: [{
                    block_type: 'paragraph',
                    content: [{
                        inline_type: 'text',
                        text: content.text,
                        marks: NONE
                    }],
                    attrs: NONE
                }]
            }
            WHERE content.blocks IS NONE;
        ",
        )
        .await?;

        Ok(())
    }
}

// -----------------------------------------------------------------------------
// SurrealQL Query Helpers
// -----------------------------------------------------------------------------

/// Helper functions for common content queries
pub mod content_queries {

    /// Find all nodes containing bold text
    pub const FIND_BOLD_NODES: &str = "
        SELECT id, content.blocks FROM inode 
        WHERE content.blocks[*].content[*].marks[*].mark_type = 'bold';
    ";

    /// Find all nodes containing links to a specific domain
    pub const FIND_LINKS_TO_DOMAIN: &str = "
        SELECT id, content.blocks FROM inode 
        WHERE content.blocks[*].content[*].marks[*].attrs.href CONTAINS $domain;
    ";

    /// Find all heading blocks across all nodes
    pub const FIND_ALL_HEADINGS: &str = "
        SELECT id, content.blocks FROM inode 
        WHERE content.blocks[*].block_type = 'heading';
    ";

    /// Full-text search across all node content
    pub const SEARCH_CONTENT: &str = "
        SELECT id, content.text FROM inode 
        WHERE content.text @@ $search_term;
    ";

    /// Extract plain text from content for indexing
    pub const EXTRACT_TEXT_FUNCTION: &str = "
        DEFINE FUNCTION fn::extract_text($content) {
            RETURN array::flatten($content.blocks[*].content[*].text).join(' ');
        }
    ";
}
