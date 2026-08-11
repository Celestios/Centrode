use crate::common::setup_test_repo;
use centrode_core::domain::base_models::{Coordinates, Size};
use centrode_core::domain::contents::Content;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::{INode, Nodes, TaskNode, TaskState};
use centrode_core::domain::relations::{IRelation, IRelationFields};
use centrode_core::domain::styles::RelationDirection;
use centrode_core::domain::tags::{Tag, TagEdge, TagFields};
use centrode_core::domain::traits::TableKind;

#[tokio::test]
async fn test_templates_save_and_instantiate() {
    let repo = setup_test_repo().await;

    // 1. Create a tag
    let tag_id = TypedRecordId::new_v4(TableKind::Tag);
    let tag = Tag {
        key: tag_id,
        fields: TagFields {
            name: "test_tag".to_string(),
            color: 0x00FF00,
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_tag(tag.clone()).await.unwrap();

    let node1_id = TypedRecordId::new_v4(TableKind::INode);
    let node1 = INode {
        id: node1_id,
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
        tags: vec![TagEdge::Hydrated(tag)],
        aliases: vec![],
        comments: vec![centrode_core::domain::base_models::Comment {
            text: "test comment".to_string(),
            created_at: 0,
        }],
        attachment: None,
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };
    repo.create_node(Nodes::INode(node1.clone())).await.unwrap();

    let node2_id = TypedRecordId::new_v4(TableKind::TaskNode);
    let node2 = TaskNode {
        id: node2_id,
        content: Content::from_plain_text("Node 2 in template"),
        due_date: None,
        state: TaskState::Todo,
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
    repo.create_node(Nodes::TaskNode(node2.clone())).await.unwrap();

    // 2. Create relation between them
    let rel_id = TypedRecordId::new_v4(TableKind::IRelation);
    let relation = IRelation {
        key: rel_id,
        in_: node1_id,
        out: node2_id,
        fields: IRelationFields {
            verb: "relates".to_string(),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            direction: RelationDirection::default(),
            layer: "default".to_string(),
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_relation(relation.clone()).await.unwrap();

    // 3. Save selection as a Template
    let selection_nodes = vec![Nodes::INode(node1), Nodes::TaskNode(node2)];
    let selection_relations = vec![relation];

    let saved_template = repo.save_template(
        "Workflow Step Template".to_string(),
        selection_nodes,
        selection_relations,
    ).await.expect("Failed to save template");

    // 4. Retrieve templates and verify
    let templates = repo.list_templates().await.expect("Failed to list templates");
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
    let template_key_str = saved_template.key.key.to_string();
    repo.apply_template(template_key_str.clone(), 500.0, 600.0)
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
    let new_inode = inodes.iter().find(|n| n.id.key != node1_id.key).unwrap();
    assert_eq!(new_inode.position, Coordinates { x: 450, y: 550 });

    // Find the new tasknode (which has position (550, 650) = 500 + 50, 600 + 50)
    let new_tasknode = tasknodes.iter().find(|n| n.id.key != node2_id.key).unwrap();
    assert_eq!(new_tasknode.position, Coordinates { x: 550, y: 650 });

    // Find the new relation and check that it connects the new nodes
    let new_relation = relations.iter().find(|r| r.key != rel_id).unwrap();
    assert_eq!(new_relation.in_.key, new_inode.id.key);
    assert_eq!(new_relation.out.key, new_tasknode.id.key);

    // 7. Delete the template
    repo.delete_template(template_key_str).await.expect("Failed to delete template");
    let templates_after_delete = repo.list_templates().await.unwrap();
    assert_eq!(templates_after_delete.len(), 0);
}
