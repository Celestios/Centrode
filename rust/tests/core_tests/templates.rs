use crate::common::setup_test_repo;
use rust_lib_mycelium::domain::base_models::{Coordinates, RecordStrings, Size};
use rust_lib_mycelium::domain::contents::Content;
use rust_lib_mycelium::domain::nodes::{INode, Nodes, TaskNode};
use rust_lib_mycelium::domain::relations::{IRelation, IRelationFields};

#[tokio::test]
async fn test_templates_save_and_instantiate() {
    let repo = setup_test_repo().await;

    // 1. Create a tag
    let tag = rust_lib_mycelium::domain::tags::Tag {
        key: "test_tag_uuid".to_string(),
        fields: rust_lib_mycelium::domain::tags::TagFields {
            name: "test_tag".to_string(),
            color: 0x00FF00,
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_tag(tag.clone()).await.unwrap();

    let node1_key = "node_1_uuid".to_string();
    let node1 = INode {
        id: RecordStrings { table: "INode".to_string(), key: node1_key.clone() },
        content: Content::from_plain_text("Node 1 in template"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 100, y: 200 },
        size: Size { width: 100, height: 50 },
        line_count: 1,
        expandable: true,
        is_expanded: false,
        locked: false,
        tags: vec![rust_lib_mycelium::domain::tags::TagEdge::Hydrated(tag)],
        aliases: vec![],
        comments: vec![rust_lib_mycelium::domain::base_models::Comment {
            text: "test comment".to_string(),
            created_at: 0,
        }],
        attachment: None,
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };
    repo.create_node(Nodes::INode(node1)).await.unwrap();

    let node2_key = "node_2_uuid".to_string();
    let node2 = TaskNode {
        id: RecordStrings { table: "TaskNode".to_string(), key: node2_key.clone() },
        content: Content::from_plain_text("Node 2 in template"),
        due_date: None,
        state: "todo".to_string(),
        position: Coordinates { x: 200, y: 300 },
        size: Size { width: 100, height: 50 },
        expandable: true,
        is_expanded: false,
        layer: "default".to_string(),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };
    repo.create_node(Nodes::TaskNode(node2)).await.unwrap();

    // 2. Create relation between them
    let rel_key = "rel_uuid".to_string();
    let relation = IRelation {
        key: rel_key.clone(),
        in_: RecordStrings { table: "INode".to_string(), key: node1_key.clone() },
        out: RecordStrings { table: "TaskNode".to_string(), key: node2_key.clone() },
        fields: IRelationFields {
            verb: "relates".to_string(),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            directionless: false,
            layer: "default".to_string(),
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_relation(relation).await.unwrap();

    // 3. Save selection as a Template
    let selection_nodes = vec![
        RecordStrings { table: "INode".to_string(), key: node1_key.clone() },
        RecordStrings { table: "TaskNode".to_string(), key: node2_key.clone() },
    ];
    let selection_relations = vec![
        RecordStrings { table: "IRelation".to_string(), key: rel_key.clone() },
    ];

    repo.save_template_from_selection(
        "Workflow Step Template".to_string(),
        selection_nodes,
        selection_relations,
    ).await.expect("Failed to save template");

    // 4. Retrieve templates and verify
    let templates = repo.get_all_templates().await.expect("Failed to list templates");
    assert_eq!(templates.len(), 1);
    let template = &templates[0];
    assert_eq!(template.name, "Workflow Step Template");
    assert_eq!(template.nodes.len(), 2);
    assert_eq!(template.relations.len(), 1);

    // Verify coordinates are normalized relative to centroid (150, 250)
    // Node 1: (100, 200) -> (-50, -50)
    // Node 2: (200, 300) -> (50, 50)
    for node in &template.nodes {
        match node {
            Nodes::INode(n) => {
                assert_eq!(n.position, Coordinates { x: -50, y: -50 });
            }
            Nodes::TaskNode(n) => {
                assert_eq!(n.position, Coordinates { x: 50, y: 50 });
            }
            _ => panic!("Unexpected node type"),
        }
    }

    // 5. Instantiate template at (500, 600)
    let template_key = template.key.clone();
    repo.instantiate_template(template_key.clone(), 500.0, 600.0)
        .await
        .expect("Failed to instantiate template");

    // 6. Get all graph data and verify instantiated nodes and relations
    let snapshot = repo.get_graph_snapshot().await.unwrap();
    let inodes: Vec<INode> = snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::INode(inode) => Some(inode.clone()),
        _ => None,
    }).collect();
    let tasknodes: Vec<TaskNode> = snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::TaskNode(tn) => Some(tn.clone()),
        _ => None,
    }).collect();
    let relations = snapshot.relations;
    
    // We expect 2 original inodes/tasknodes + 1 new for each
    assert_eq!(inodes.len(), 2); // original + new
    assert_eq!(tasknodes.len(), 2); // original + new
    assert_eq!(relations.len(), 2); // original + new

    // Find the new inode (which has position (450, 550) = 500 - 50, 600 - 50)
    let new_inode = inodes.iter().find(|n| n.id.key != node1_key).unwrap();
    assert_eq!(new_inode.position, Coordinates { x: 450, y: 550 });

    // Find the new tasknode (which has position (550, 650) = 500 + 50, 600 + 50)
    let new_tasknode = tasknodes.iter().find(|n| n.id.key != node2_key).unwrap();
    assert_eq!(new_tasknode.position, Coordinates { x: 550, y: 650 });

    // Find the new relation and check that it connects the new nodes
    let new_relation = relations.iter().find(|r| r.key != rel_key).unwrap();
    assert_eq!(new_relation.in_.key, new_inode.id.key);
    assert_eq!(new_relation.out.key, new_tasknode.id.key);

    // 7. Delete the template
    repo.delete_template(template_key).await.expect("Failed to delete template");
    let templates_after_delete = repo.get_all_templates().await.unwrap();
    assert_eq!(templates_after_delete.len(), 0);
}

