// We use `type::thing` to force specific IDs provided by the client/UUID generator
pub const CREATE_INODE: &str = r#"
    CREATE type::thing('inode', $id) CONTENT {
        text: $text,
        visual_formatting: $visual_formatting,
        position: $position,
        layer: $layer,
        locked: $locked,
        tags: $tags,
        aliases: $aliases,
        comments: $comments,
        attachment: $attachment,
        created_at: time::now(),
        updated_at: time::now()
    } RETURN id;
"#;

pub const CREATE_TASK_NODE: &str = r#"
    CREATE type::thing('task_node', $id) CONTENT {
        text: $text,
        due_date: $due_date,
        state: $state,
        created_at: time::now(),
        updated_at: time::now()
    } RETURN id;
"#;

// Uses SurrealDB's RELATE statement to create a graph edge
pub const CREATE_RELATION: &str = r#"
    RELATE type::thing($from) -> relates_to -> type::thing($to) CONTENT {
        verb: $verb,
        visual_formatting: $visual_formatting,
        directionless: $directionless,
        layer: $layer,
        created_at: time::now()
    } RETURN id;
"#;

pub const GET_NODE: &str = r#"
    SELECT * FROM type::thing($table, $id);
"#;

// [NEW] Bulk Fetch Queries
pub const GET_ALL_INODES: &str = "SELECT * FROM inode;";
pub const GET_ALL_TASKS: &str = "SELECT * FROM task_node;";
pub const GET_ALL_RELATIONS: &str = "SELECT * FROM relates_to;";