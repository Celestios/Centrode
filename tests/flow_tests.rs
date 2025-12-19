use mycelium_core::bridge::api;
use mycelium_core::domain::nodes::{NodeInput, INode, TaskNode, InterNode, NodeOutput};
use mycelium_core::domain::relations::{RelationInput, IRelation};
use mycelium_core::domain::config::{ThemeConfig, StyleProfile, resolve_node_style};
use mycelium_core::format::packager;
use tokio;
use tempfile::tempdir;
use std::time::{SystemTime, UNIX_EPOCH};
use std::fs::File;
use std::io::Read;
use std::collections::HashMap;

// Helper to get current timestamp
fn now() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64
}

#[tokio::test]
async fn test_knowledge_graph_flow() {
    // 1. Setup: Use a temp directory so we don't pollute the actual disk
    let dir = tempdir().expect("Failed to create temp dir");
    let db_path = dir.path().to_str().unwrap().to_string();

    // Initialize the DB (Architecture Layer 1 & 3)
    api::init_app(db_path).await.expect("Failed to init app");

    // 2. Create Node A (Source)
    let node_a_id = "node_a_uuid".to_string();
    let input_a = NodeInput::Info(INode {
        text: Some("Source Node".to_string()),
        visual_formatting: None,
        position: None,
        layer: 1u8,
        locked: false,
        tags: vec!["test".to_string()],
        aliases: vec![],
        comments: vec![],
        attachment: None,
        created_at: 0,
        updated_at: 0,
    });

    // 3. Create Node B (Target)
    let node_b_id = "node_b_uuid".to_string();
    let input_b = NodeInput::Info(INode {
        text: Some("Target Node".to_string()),
        visual_formatting: None,
        position: None,
        layer: 1u8,
        locked: false,
        tags: vec![],
        aliases: vec![],
        comments: vec![],
        attachment: None,
        created_at: 0,
        updated_at: 0,
    });

    api::create_node(node_a_id.clone(), input_a).await.expect("Failed to create Node A");
    api::create_node(node_b_id.clone(), input_b).await.expect("Failed to create Node B");

    // 4. Create Relation: A -> relates_to -> B
    let rel_input = RelationInput {
        from: format!("inode:{}", node_a_id), // SurrealDB ID format matches templates.rs
        to: format!("inode:{}", node_b_id),
        props: IRelation {
            verb: "relates_to".to_string(),
            visual_formatting: None,
            directionless: false,
            layer: 1,
        },
    };

    let rel_result = api::create_relation(rel_input).await;
    assert!(rel_result.is_ok(), "Failed to create relation");

    // 5. Verify Persistence (Read Operation)
    let fetched_node = api::get_node("inode".to_string(), node_a_id.clone()).await;

    match fetched_node {
        Ok(Some(mycelium_core::domain::nodes::NodeOutput::Info(inode))) => {
            assert_eq!(inode.text, Some("Source Node".to_string()));
            // In a real graph test, we would also query the relation here
            // to ensure the edge actually exists in the DB.
        },
        Ok(Some(_)) => panic!("Fetched wrong node type"),
        Ok(None) => panic!("Node A was created but could not be found!"),
        Err(e) => panic!("Database error fetching Node A: {:?}", e),
    }
}

#[tokio::test]
async fn test_task_node_lifecycle() {
    // 1. Setup
    let dir = tempdir().expect("Failed to create temp dir");
    let db_path = dir.path().to_str().unwrap().to_string();
    api::init_app(db_path).await.expect("Failed to init app");

    // 2. Create Task Node
    let task_id = "task_uuid_1".to_string();
    let input_task = NodeInput::Task(TaskNode {
        text: Some("Complete Project Milestone".to_string()),
        due_date: Some(now() + 86400), // +1 day
        state: "TODO".to_string(),
        visual_formatting: None,
        created_at: now(),
        updated_at: now(),
    });

    api::create_node(task_id.clone(), input_task).await.expect("Failed to create Task");

    // 3. Verify Persistence (Specific Table Query)
    let fetched = api::get_node("task_node".to_string(), task_id.clone()).await;

    match fetched {
        Ok(Some(NodeOutput::Task(task))) => {
            assert_eq!(task.state, "TODO");
            assert!(task.text.unwrap().contains("Milestone"));
        },
        _ => panic!("Failed to fetch Task Node correctly"),
    }
}

#[tokio::test]
async fn test_internode_heavy_edge() {
    // 1. Setup
    let dir = tempdir().expect("Failed to create temp dir");
    let db_path = dir.path().to_str().unwrap().to_string();
    api::init_app(db_path).await.expect("Failed to init app");

    // 2. Create InterNode (A node that acts as a heavy edge)
    let inter_id = "inter_uuid_99".to_string();
    let input_inter = NodeInput::Inter(InterNode {
        verb: "causes".to_string(),
        behavioral_features: Some("inhibiting".to_string()),
        visual_formatting: None,
        created_at: now(),
        updated_at: now(),
    });

    api::create_node(inter_id.clone(), input_inter).await.expect("Failed to create InterNode");

    // 3. Verify Persistence
    let fetched = api::get_node("inter_node".to_string(), inter_id).await;

    match fetched {
        Ok(Some(NodeOutput::Inter(node))) => {
            assert_eq!(node.verb, "causes");
            assert_eq!(node.behavioral_features, Some("inhibiting".to_string()));
        },
        _ => panic!("Failed to fetch InterNode"),
    }
}

#[tokio::test]
async fn test_full_graph_snapshot() {
    // 1. Setup
    let dir = tempdir().expect("Failed to create temp dir");
    let db_path = dir.path().to_str().unwrap().to_string();
    api::init_app(db_path).await.expect("Failed to init app");

    // 2. Populate DB with mixed types
    // Node A (Info)
    let id_a = "node_a".to_string();
    api::create_node(id_a.clone(), NodeInput::Info(INode {
        text: Some("Info Node".to_string()),
        layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![], 
        attachment: None, visual_formatting: None, position: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    // Node B (Task)
    let id_b = "node_b".to_string();
    api::create_node(id_b.clone(), NodeInput::Task(TaskNode {
        text: Some("Task Node".to_string()),
        due_date: None, state: "DONE".to_string(), 
        visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    // Relation A -> B
    let rel_input = RelationInput {
        from: format!("inode:{}", id_a),
        to: format!("task_node:{}", id_b), // Note: Connecting Info to Task
        props: IRelation {
            verb: "blocks".to_string(),
            visual_formatting: None,
            directionless: false,
            layer: 1,
        },
    };
    api::create_relation(rel_input).await.unwrap();

    // 3. Fetch Snapshot (The function used by save_map_to_file)
    let snapshot = api::get_graph_snapshot().await;

    assert!(snapshot.is_ok());
    let (nodes, relations, _config) = snapshot.unwrap();

    // 4. Assertions
    assert_eq!(nodes.len(), 2, "Should have retrieved exactly 2 nodes");
    assert_eq!(relations.len(), 1, "Should have retrieved exactly 1 relation");

    // Verify Polymorphism: Ensure we got 1 Task and 1 Info
    let has_task = nodes.iter().any(|n| matches!(n, NodeOutput::Task(_)));
    let has_info = nodes.iter().any(|n| matches!(n, NodeOutput::Info(_)));

    assert!(has_task, "Snapshot missing TaskNode");
    assert!(has_info, "Snapshot missing INode");
}

#[tokio::test]
async fn test_relation_uniqueness_constraint() {
    // 1. Setup
    let dir = tempdir().expect("Failed to create temp dir");
    let db_path = dir.path().to_str().unwrap().to_string();
    api::init_app(db_path).await.expect("Failed to init app");

    // 2. Create Nodes
    let id_a = "unique_a".to_string();
    let id_b = "unique_b".to_string();

    // Create dummy nodes (details irrelevant for this test)
    let dummy_input = NodeInput::Info(INode {
        text: Some("x".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![],
        attachment: None, visual_formatting: None, position: None, created_at: 0, updated_at: 0
    });
    api::create_node(id_a.clone(), dummy_input.clone()).await.unwrap();
    api::create_node(id_b.clone(), dummy_input).await.unwrap();

    // 3. Define Relation
    let rel_input = RelationInput {
        from: format!("inode:{}", id_a),
        to: format!("inode:{}", id_b),
        props: IRelation {
            verb: "relates_to".to_string(), // Crucial: Same verb
            visual_formatting: None,
            directionless: false,
            layer: 1,
        },
    };

    // 4. Create First Relation (Should Succeed)
    let first_attempt = api::create_relation(rel_input.clone()).await;
    assert!(first_attempt.is_ok(), "First relation creation should succeed");

    // 5. Create Duplicate Relation (Should Fail)
    let second_attempt = api::create_relation(rel_input).await;
    assert!(second_attempt.is_err(), "Duplicate relation should violate UNIQUE index");
}

#[test]
fn test_style_resolution_cascade() {
    // 1. Define Hierarchy
    let global_style = StyleProfile {
        shape: "circle".into(), bg_color: "white".into(), stroke_color: "black".into(),
        stroke_width: 1.0, font_family: "Arial".into()
    };

    let task_style = StyleProfile {
        shape: "rect".into(), bg_color: "green".into(), stroke_color: "black".into(),
        stroke_width: 1.0, font_family: "Arial".into()
    };

    let mut type_defs = HashMap::new();
    type_defs.insert("TaskNode".to_string(), task_style);

    let theme = ThemeConfig {
        name: "Test Theme".into(),
        global_default: global_style,
        type_definitions: type_defs,
    };

    // 2. Test: Type Definition should override Global
    // "TaskNode" has no instance overrides (None), so it should be Green/Rect
    let resolved_task = resolve_node_style(&theme, "TaskNode", &None).expect("Resolution failed");
    assert_eq!(resolved_task.bg_color, "green");
    assert_eq!(resolved_task.shape, "rect");

    // 3. Test: Instance Override should override Type Definition
    // User manually sets this specific node to "Red"
    let override_json = r#"{
        "layout": { "graph": null, "kanban": null, "timeline": null },
        "overrides": {
            "shape": "star",
            "bg_color": "red",
            "stroke_color": "",
            "stroke_width": 0.0,
            "font_family": ""
        }
    }"#.to_string();

    let resolved_override = resolve_node_style(&theme, "TaskNode", &Some(override_json)).expect("Resolution failed");

    assert_eq!(resolved_override.bg_color, "red", "Instance override color failed");
    assert_eq!(resolved_override.shape, "star", "Instance override shape failed");
    // Ensure untouched properties inherit from lower layers
    assert_eq!(resolved_override.font_family, "Arial", "Inheritance broken");
}

#[test] // Synchronous test (file I/O)
fn test_packager_integration() {
    // 1. Setup Temp Dirs
    let dir = tempdir().expect("Failed to create temp dir");
    let attachment_dir = dir.path().join("data");
    std::fs::create_dir(&attachment_dir).expect("Failed to create data dir");

    let archive_path = dir.path().join("output.celi");
    let archive_str = archive_path.to_str().unwrap();
    let attach_str = attachment_dir.to_str().unwrap();

    // 2. Mock Data
    let nodes = vec![]; // Empty graph is valid
    let relations = vec![];

    // 3. Execute Packager
    let result = packager::save_project_to_celi(archive_str, attach_str, nodes, relations, None);
    assert!(result.is_ok(), "Packager failed to create archive");

    // 4. Verify Output
    assert!(archive_path.exists(), ".celi file was not created");

    // Basic ZIP check: Read first 4 bytes for "PK" magic signature
    let mut file = File::open(&archive_path).expect("Failed to open archive");
    let mut buffer = [0u8; 4];
    file.read_exact(&mut buffer).expect("Failed to read header");

    assert_eq!(&buffer, &[0x50, 0x4b, 0x03, 0x04], "File is not a valid ZIP archive");
}
