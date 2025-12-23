use mycelium_core::persistence::{repo::Repository, schema::Schema};
use mycelium_core::domain::nodes::{NodeInput, INode, TaskNode, InterNode, NodeOutput};
use mycelium_core::domain::relations::{RelationInput, IRelation};
use mycelium_core::domain::config::{ThemeConfig, StyleProfile, resolve_node_style};
use mycelium_core::format::packager;
use surrealdb::Surreal;
use surrealdb::engine::local::Mem;
use tokio;
use tempfile::tempdir;
use std::time::{SystemTime, UNIX_EPOCH};
use std::fs::File;
use std::io::Read;
use std::collections::HashMap;
use serde_json::json; // Ensure this is available in your Cargo.toml
use mycelium_core::domain::config::MapConfig;
use surrealdb::sql::Thing;
use zip;

// Helper to get current timestamp
fn now() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64
}

// [NEW] Test Fixture: Returns a fully initialized Repository
// This abstracts away the TempDir and Schema Init details
async fn setup() -> Repository {
    // Use the in-memory engine for isolation and speed
    let db = Surreal::new::<Mem>(()).await.expect("Failed to init Mem DB");
    db.use_ns("test").use_db("test").await.expect("Failed to select DB");

    // Initialize Schema
    Schema::init(&db).await.expect("Failed to init Schema");

    Repository::new(db)
}

#[tokio::test]
async fn test_knowledge_graph_flow() {
    let repo = setup().await; // [CLEAN] 1-line setup

    let input_a = NodeInput::Info(INode {
        id: None,
        text: Some("A".into()),
        visual_formatting: None,
        layer: 1u8,
        locked: false,
        tags: vec!["test".to_string()],
        aliases: vec![],
        comments: vec![],
        attachment: None,
        created_at: 0,
        updated_at: 0,
    });

    // [CLEAN] Method calls on the object
    let id_a = repo.create_node(input_a).await.expect("Failed A");

    let fetched = repo.get_node("inode".to_string(), id_a).await;
    assert!(fetched.unwrap().is_some());
}

#[tokio::test]
async fn test_task_node_lifecycle() {
    let repo = setup().await; // [CLEAN] Isolated DB automatically

    let input = NodeInput::Task(TaskNode {
        id: None,
        text: Some("Complete Project Milestone".to_string()),
        due_date: Some(now() + 86400), // +1 day
        state: "TODO".to_string(),
        visual_formatting: None,
        created_at: now(),
        updated_at: now(),
    });

    let task_id = repo.create_node(input).await.expect("Failed Create");

    match repo.get_node("task_node".to_string(), task_id).await {
        Ok(Some(NodeOutput::Task(t))) => assert_eq!(t.state, "TODO"),
        _ => panic!("Failed to fetch"),
    }
}

#[tokio::test]
async fn test_internode_heavy_edge() {
    let repo = setup().await;

    let input_inter = NodeInput::Inter(InterNode {
        id: None,
        verb: "causes".to_string(),
        behavioral_features: Some("inhibiting".to_string()),
        visual_formatting: None,
        created_at: now(),
        updated_at: now(),
    });

    let inter_id = repo.create_node(input_inter).await.expect("Failed to create InterNode");

    match repo.get_node("inter_node".to_string(), inter_id).await {
        Ok(Some(NodeOutput::Inter(node))) => {
            assert_eq!(node.verb, "causes");
            assert_eq!(node.behavioral_features, Some("inhibiting".to_string()));
        },
        _ => panic!("Failed to fetch InterNode"),
    }
}

#[tokio::test]
async fn test_full_graph_snapshot() {
    let repo = setup().await;

    // Populate DB with mixed types
    let id_a = repo.create_node(NodeInput::Info(INode {
        id: None,
        text: Some("Info Node".to_string()),
        layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![],
        attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    let id_b = repo.create_node(NodeInput::Task(TaskNode {
        id: None,
        text: Some("Task Node".to_string()),
        due_date: None, state: "DONE".to_string(),
        visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    let rel_input = RelationInput {
        from: format!("inode:{}", id_a),
        to: format!("task_node:{}", id_b),
        props: IRelation {
            id: None,
            verb: "blocks".to_string(),
            visual_formatting: None,
            directionless: false,
            layer: 1,
        },
    };
    repo.create_relation(rel_input).await.unwrap();

    let (nodes, relations, _config) = repo.get_graph_snapshot().await.unwrap();

    assert_eq!(nodes.len(), 2, "Should have retrieved exactly 2 nodes");
    assert_eq!(relations.len(), 1, "Should have retrieved exactly 1 relation");

    let has_task = nodes.iter().any(|n| matches!(n, NodeOutput::Task(_)));
    let has_info = nodes.iter().any(|n| matches!(n, NodeOutput::Info(_)));

    assert!(has_task, "Snapshot missing TaskNode");
    assert!(has_info, "Snapshot missing INode");
}

#[tokio::test]
async fn test_relation_uniqueness_constraint() {
    let repo = setup().await;

    let dummy_input = NodeInput::Info(INode {
        id: None,
        text: Some("x".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![],
        attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    });
    let id_a = repo.create_node(dummy_input.clone()).await.unwrap();
    let id_b = repo.create_node(dummy_input).await.unwrap();

    let rel_input = RelationInput {
        from: format!("inode:{}", id_a),
        to: format!("inode:{}", id_b),
        props: IRelation {
            id: None,
            verb: "relates_to".to_string(),
            visual_formatting: None,
            directionless: false,
            layer: 1,
        },
    };

    let first_attempt = repo.create_relation(rel_input.clone()).await;
    assert!(first_attempt.is_ok(), "First relation creation should succeed");

    let second_attempt = repo.create_relation(rel_input).await;
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
    let nodes: Vec<NodeOutput> = vec![]; // Empty graph is valid
    let relations: Vec<IRelation> = vec![];

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


#[tokio::test]
async fn test_node_patching() {
    let repo = setup().await;

    // 1. Create a Node
    let input = NodeInput::Info(INode {
        id: None,
        text: Some("Original Text".into()),
        visual_formatting: None,
        layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![],
        attachment: None, created_at: now(), updated_at: now(),
    });
    let id = repo.create_node(input).await.expect("Create failed");

    // 2. Apply Dynamic Patch (Update 'text' and 'locked' status)
    let patch = json!({
        "text": "Patched Text",
        "locked": true
    });

    // We expect the 'inode' table prefix based on the input type
    repo.patch_node("inode".to_string(), id.clone(), patch).await.expect("Patch failed");

    // 3. Verify Updates
    let fetched = repo.get_node("inode".to_string(), id).await.expect("Fetch failed");
    if let Some(NodeOutput::Info(node)) = fetched {
        assert_eq!(node.text, Some("Patched Text".to_string()));
        assert_eq!(node.locked, true);
    } else {
        panic!("Node not found or wrong type");
    }
}

#[tokio::test]
async fn test_cascading_delete() {
    let repo = setup().await;

    // 1. Create Graph: Node A -> [Relation] -> Node B
    let id_a = repo.create_node(NodeInput::Info(INode {
        id: None, text: Some("A".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![], attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    let id_b = repo.create_node(NodeInput::Info(INode {
        id: None, text: Some("B".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![], attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    let rel_id = repo.create_relation(RelationInput {
        from: format!("inode:{}", id_a),
        to: format!("inode:{}", id_b),
        props: IRelation { id: None, verb: "links".to_string(), visual_formatting: None, directionless: false, layer: 1 }
    }).await.unwrap();

    // 2. Delete Node A (Should cascade to Relation)
    repo.delete_node("inode".to_string(), id_a.clone()).await.expect("Delete failed");

    // 3. Verify Node A is gone
    let node_a = repo.get_node("inode".to_string(), id_a).await.unwrap();
    assert!(node_a.is_none(), "Node A should be deleted");

    // 4. Verify Relation is gone
    // We need to parse the ID string "relates_to:uuid" to check
    let relation = repo.get_relation(format!("relates_to:{}", rel_id)).await.unwrap();
    assert!(relation.is_none(), "Relation should be deleted via cascade");

    // 5. Verify Node B still exists (Should NOT be deleted)
    let node_b = repo.get_node("inode".to_string(), id_b).await.unwrap();
    assert!(node_b.is_some(), "Node B should persist");
}

#[tokio::test]
async fn test_relation_operations() {
    let repo = setup().await;

    // Setup Nodes
    let id_a = repo.create_node(NodeInput::Info(INode {
        id: None, text: Some("A".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![], attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();
    let id_b = repo.create_node(NodeInput::Info(INode {
        id: None, text: Some("B".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![], attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();
    let id_c = repo.create_node(NodeInput::Info(INode {
        id: None, text: Some("C".into()), layer: 1, locked: false, tags: vec![], aliases: vec![], comments: vec![], attachment: None, visual_formatting: None, created_at: 0, updated_at: 0
    })).await.unwrap();

    // 1. Create Relation A -> B
    let rel_id_raw = repo.create_relation(RelationInput {
        from: format!("inode:{}", id_a),
        to: format!("inode:{}", id_b),
        props: IRelation { id: None, verb: "original".to_string(), visual_formatting: None, directionless: false, layer: 1 }
    }).await.unwrap();

    let rel_id = format!("relates_to:{}", rel_id_raw);

    // 2. Patch Relation (Change Verb)
    repo.update_relation_properties(rel_id.clone(), json!({ "verb": "patched" })).await.expect("Patch failed");

    let fetched = repo.get_relation(rel_id.clone()).await.unwrap().expect("Relation not found");
    assert_eq!(fetched.verb, "patched");

    // 3. Reroute Relation (A -> C)
    repo.reroute_relation(
        rel_id.clone(),
        format!("inode:{}", id_a),
        format!("inode:{}", id_c)
    ).await.expect("Reroute failed");

    // Verify Reroute (Manual DB check since IRelation struct doesn't expose in/out)
    // Note: We need to access the inner DB or rely on the fact that no error occurred.
    // Ideally, we'd verify the 'out' field equals 'inode:id_c'.

    // 4. Delete Relation
    repo.delete_relation(rel_id.clone()).await.expect("Delete failed");
    let deleted = repo.get_relation(rel_id).await.unwrap();
    assert!(deleted.is_none());
}

#[tokio::test]
async fn test_map_metadata_persistence() {
    let repo = setup().await;

    // 1. Seed Metadata via Raw SQL (Simulating a "Save Settings" event)
    let seed_query = r##"
        CREATE map_metadata:settings CONTENT {
            "map_name": "Project Alpha",
            "viewport_state": {
                "x_offset": 100.0,
                "y_offset": 200.0,
                "zoom_level": 1.5,
                "active_view": "graph"
            },
            "theme": {
                "name": "Cyberpunk",
                "global_default": {
                    "shape": "circle",
                    "bg_color": "#000",
                    "stroke_color": "#ff00ff",
                    "stroke_width": 2.0,
                    "font_family": "Roboto"
                },
                "type_definitions": {}
            }
        };
    "##;

    // Uses the new public accessor
    repo.db().query(seed_query).await.expect("Failed to seed metadata");

    // 2. Fetch via Graph Snapshot
    let (_, _, metadata) = repo.get_graph_snapshot().await.expect("Snapshot failed");

    // 3. Verify Persistence
    let config = metadata.expect("Metadata should be present");
    assert_eq!(config.map_name, "Project Alpha");
    assert_eq!(config.theme.name, "Cyberpunk");
    assert_eq!(config.viewport_state.zoom_level, 1.5);
}

#[test]
fn test_packager_real_io_integrity() {
    // 1. Setup Filesystem
    let dir = tempdir().expect("Failed to make temp dir");
    let out_path = dir.path().join("export_test.celi");
    let attach_dir = dir.path().join("data");
    std::fs::create_dir(&attach_dir).expect("Failed to make attach dir");

    // 2. Create Dummy Attachment
    let dummy_file = attach_dir.join("notes.txt");
    std::fs::write(&dummy_file, "Secret Project Data").expect("Failed to write dummy file");

    // 3. Mock Graph Data
    let nodes = vec![
        NodeOutput::Task(TaskNode {
            id: Some(Thing::from(("task_node", "t1"))),
            text: Some("Critical Task".into()),
            due_date: None, state: "TODO".into(), visual_formatting: None,
            created_at: 0, updated_at: 0
        })
    ];
    let relations = vec![];

    // 4. Run Export
    let result = packager::save_project_to_celi(
        out_path.to_str().unwrap(),
        attach_dir.to_str().unwrap(),
        nodes,
        relations,
        None
    );
    assert!(result.is_ok(), "Export failed");

    // 5. Verify Content (Unzip & Inspect)
    let file = File::open(&out_path).expect("Failed to open exported file");
    let mut archive = zip::ZipArchive::new(file).expect("Failed to read zip");

    // Check Graph JSON
    {
        let mut graph_file = archive.by_name("graph.json").expect("graph.json missing");
        let mut json_content = String::new();
        graph_file.read_to_string(&mut json_content).expect("Failed to read graph.json");

        assert!(json_content.contains("Critical Task"), "JSON data corrupted or missing");
    }

    // Check Attachment
    {
        let mut attach_file = archive.by_name("data/notes.txt").expect("Attachment missing");
        let mut attach_content = String::new();
        attach_file.read_to_string(&mut attach_content).expect("Failed to read attachment");

        assert_eq!(attach_content, "Secret Project Data", "Attachment content corrupted");
    }
}

#[tokio::test]
async fn test_error_handling_edge_cases() {
    let repo = setup().await;

    // 1. Fetching Non-Existent Node
    let missing = repo.get_node("inode".into(), "non_existent_id".into()).await;
    assert!(missing.is_ok());
    assert!(missing.unwrap().is_none(), "Should return None for missing ID");

    // 2. Patching Non-Existent Node
    // Should return Err because the record to MERGE into doesn't exist
    let patch_res = repo.patch_node(
        "inode".into(),
        "ghost_id".into(),
        json!({"text": "Boo"})
    ).await;

    assert!(patch_res.is_err(), "Patching a ghost node should fail");
}