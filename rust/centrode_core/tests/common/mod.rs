use centrode_core::domain::base_models::{Coordinates, Size};
use centrode_core::domain::contents::Content;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::ContainerNode;
use centrode_core::domain::nodes::INode;
use centrode_core::domain::relations::IRelationFields;
use centrode_core::domain::styles::RelationDirection;
use centrode_core::repo::Repositories;
use centrode_daemon::schema::{Schema, Seeder};

use surrealdb::engine::local::Mem;
use surrealdb::Surreal;

pub async fn setup_test_repo() -> Repositories {
    // Initialize SurrealDB in-memory engine
    let db = Surreal::new::<Mem>(())
        .await
        .expect("Failed to initialize SurrealDB Mem engine");

    // Select test namespace and database
    db.use_ns("test_ns")
        .use_db("test_db")
        .await
        .expect("Failed to select test namespace and database");

    // Initialize Schema
    Schema::init(&db)
        .await
        .expect("Failed to initialize DB schema in tests");

    Seeder::seed_default_data(&db, "Test Map".to_string())
        .await
        .expect("Failed to seed default data in tests");

    Repositories::new(db)
}

pub fn make_inode(id: TypedRecordId, text: &str, x: i32, y: i32) -> INode {
    INode {
        id,
        parent_container_id: None,
        content: Content::from_plain_text(text),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x, y },
        size: Size {
            width: 100,
            height: 50,
        },
        line_count: 1,
        expandable: true,
        is_expanded: false,
        locked: false,
        tags: vec![],
        aliases: vec![],
        comments: vec![],
        attachments: vec![],
        significance: 0,
        created_at: 0,
        updated_at: 0,
    }
}

pub fn make_container_node(id: TypedRecordId, title: &str, x: i32, y: i32) -> ContainerNode {
    ContainerNode {
        id,
        parent_container_id: None,
        title: title.to_string(),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x, y },
        size: Size {
            width: 200,
            height: 150,
        },
        is_closed: true,
        child_count: 0,
        locked: false,
        tags: vec![],
        comments: vec![],
        significance: 0,
        created_at: 0,
        updated_at: 0,
    }
}

pub fn make_relation_fields(verb: &str) -> IRelationFields {
    IRelationFields {
        verb: verb.to_string(),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        direction: RelationDirection::default(),
        layer: "default".to_string(),
        created_at: 0,
        updated_at: 0,
    }
}
