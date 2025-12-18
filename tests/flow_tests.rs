use mycelium_core::bridge::api;
use mycelium_core::domain::nodes::{NodeInput, INode};
use mycelium_core::domain::relations::{RelationInput, IRelation};
use tokio;
use tempfile::tempdir;

#[tokio::test]
async fn test_knowledge_graph_flow() {
    // 1. Setup: Use a temp directory so we don't pollute the actual disk
    let dir = tempdir().expect("Failed to create temp dir");
    let db_path = dir.path().join("mycelium.db").to_str().unwrap().to_string();

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
        Ok(Some(node)) => {
            assert_eq!(node.text, Some("Source Node".to_string()));
            // In a real graph test, we would also query the relation here
            // to ensure the edge actually exists in the DB.
        },
        Ok(None) => panic!("Node A was created but could not be found!"),
        Err(e) => panic!("Database error fetching Node A: {:?}", e),
    }
}
