use crate::common::setup_test_repo;
use mycelium_core::domain::analysis::{DecaySignificanceStrategy, GraphAnalysis};
use mycelium_core::domain::base_models::{
    BoundingBox, Coordinates, IsTable, MapData, RecordStrings, Size,
};
use mycelium_core::domain::contents::Content;
use mycelium_core::domain::nodes::{
    INode, INodeFields, InterNode, InterNodeFields, Nodes, TaskNode, TaskNodeFields,
};
use mycelium_core::domain::relations::{IRelation, IRelationFields};

async fn assert_significance_eventually(
    repo: &mycelium_core::persistence::repo::Repository,
    table: &str,
    key: &str,
    expected: u8,
) {
    let start = std::time::Instant::now();
    let timeout = std::time::Duration::from_millis(1000);
    let interval = std::time::Duration::from_millis(10);
    while start.elapsed() < timeout {
        if let Ok(Some(node)) = repo.get_node(table.to_string(), key.to_string()).await {
            let sig = match node {
                Nodes::INode(n) => n.fields.significance,
                Nodes::TaskNode(t) => t.fields.significance,
                Nodes::InterNode(_) => 0,
            };
            if sig == expected {
                return;
            }
        }
        tokio::time::sleep(interval).await;
    }
    let node = repo
        .get_node(table.to_string(), key.to_string())
        .await
        .unwrap()
        .unwrap();
    let sig = match node {
        Nodes::INode(n) => n.fields.significance,
        Nodes::TaskNode(t) => t.fields.significance,
        Nodes::InterNode(_) => 0,
    };
    assert_eq!(
        sig, expected,
        "Node {}/{} significance did not reach expected value",
        table, key
    );
}

#[tokio::test]
async fn test_graph_snapshot() {
    let repo = setup_test_repo().await;

    // Create initial nodes
    let inode = INode {
        key: "inode_snap".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("Snapshot Node"),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            layer: "default".to_string(),
            position: Coordinates { x: 10, y: 10 },
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
            attachment: None,
            significance: 0,
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_node(Nodes::INode(inode.clone()))
        .await
        .expect("Failed to seed snapshot test node");

    // Verify snapshot query
    let (inodes, tasks, inters, relations, metadata) = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch graph snapshot");
    assert_eq!(inodes.len(), 1);
    assert_eq!(inodes[0].key, "inode_snap");
    assert_eq!(tasks.len(), 0);
    assert_eq!(inters.len(), 0);
    assert_eq!(relations.len(), 0);
    assert_eq!(metadata.map_name, "Test Map");

    // Overwrite snapshot atomically with all entity types
    let new_inodes = vec![INode {
        key: "new_inode_snap".to_string(),
        fields: inode.fields.clone(),
    }];
    let task_fields = TaskNodeFields {
        content: Content::from_plain_text("Snapshot Task"),
        due_date: Some(99999),
        state: "todo".to_string(),
        position: Coordinates { x: 50, y: 50 },
        size: Size {
            width: 30,
            height: 30,
        },
        expandable: false,
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
    let new_tasks = vec![TaskNode {
        key: "new_task_snap".to_string(),
        fields: task_fields,
    }];
    let inter_fields = InterNodeFields {
        verb: "leads_to".to_string(),
        behavioral_features: None,
        position: Coordinates { x: 200, y: 200 },
        style: None,
        layer: "default".to_string(),
        created_at: 0,
        updated_at: 0,
    };
    let new_inters = vec![InterNode {
        key: "new_inter_snap".to_string(),
        fields: inter_fields,
    }];
    let new_relations = vec![IRelation {
        key: "new_rel_snap".to_string(),
        in_: RecordStrings {
            table: "INode".to_string(),
            key: "new_inode_snap".to_string(),
        },
        out: RecordStrings {
            table: "TaskNode".to_string(),
            key: "new_task_snap".to_string(),
        },
        fields: IRelationFields {
            verb: "references".to_string(),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            directionless: false,
            layer: "default".to_string(),
            created_at: 0,
            updated_at: 0,
        },
    }];
    let new_metadata = MapData {
        map_name: "Overwritten Map".to_string(),
        ..Default::default()
    };

    repo.set_graph_snapshot(
        new_inodes,
        new_tasks,
        new_inters,
        new_relations,
        new_metadata,
    )
    .await
    .expect("Failed to write new graph snapshot");

    // Retrieve again and verify state has changed completely and contains all types
    let (inodes_v2, tasks_v2, inters_v2, relations_v2, metadata_v2) = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch overwritten graph snapshot");
    assert_eq!(inodes_v2.len(), 1);
    assert_eq!(inodes_v2[0].key, "new_inode_snap");
    assert_eq!(tasks_v2.len(), 1);
    assert_eq!(tasks_v2[0].key, "new_task_snap");
    assert_eq!(inters_v2.len(), 1);
    assert_eq!(inters_v2[0].key, "new_inter_snap");
    assert_eq!(relations_v2.len(), 1);
    assert_eq!(relations_v2[0].key, "new_rel_snap");
    assert_eq!(relations_v2[0].in_.to_str(), "INode:new_inode_snap");
    assert_eq!(relations_v2[0].out.to_str(), "TaskNode:new_task_snap");
    assert_eq!(metadata_v2.map_name, "Overwritten Map");
}

#[tokio::test]
async fn test_graph_boundary_calculation() {
    let repo = setup_test_repo().await;

    // 1. Zero node fallback check
    let empty_bounds = GraphAnalysis::calculate_global_bounds(repo.db())
        .await
        .expect("Failed to calculate empty bounds");
    assert_eq!(empty_bounds, BoundingBox::default());

    // 2. Insert nodes at extremes
    let node_1 = INode {
        key: "n1".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("n1"),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            layer: "default".to_string(),
            position: Coordinates { x: -100, y: 300 },
            size: Size {
                width: 50,
                height: 50,
            },
            line_count: 1,
            expandable: false,
            is_expanded: false,
            locked: false,
            tags: vec![],
            aliases: vec![],
            comments: vec![],
            attachment: None,
            significance: 0,
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_node(Nodes::INode(node_1)).await.unwrap();

    let node_2 = INode {
        key: "n2".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("n2"),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            layer: "default".to_string(),
            position: Coordinates { x: 500, y: -200 },
            size: Size {
                width: 50,
                height: 50,
            },
            line_count: 1,
            expandable: false,
            is_expanded: false,
            locked: false,
            tags: vec![],
            aliases: vec![],
            comments: vec![],
            attachment: None,
            significance: 0,
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_node(Nodes::INode(node_2)).await.unwrap();

    // Verify calculated strict boundaries
    let bounds = GraphAnalysis::calculate_global_bounds(repo.db())
        .await
        .expect("Failed to calculate bounds");
    assert_eq!(bounds.min_x, -100.0);
    assert_eq!(bounds.max_x, 500.0);
    assert_eq!(bounds.min_y, -200.0);
    assert_eq!(bounds.max_y, 300.0);
}

#[tokio::test]
async fn test_decay_significance_propagation() {
    let repo = setup_test_repo().await;

    // Create 5 InfoNodes to form a linear graph:
    // A -> B -> C -> D -> E
    let fields = INodeFields {
        content: Content::from_plain_text("Node"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 0, y: 0 },
        size: Size {
            width: 50,
            height: 50,
        },
        line_count: 1,
        expandable: false,
        is_expanded: false,
        locked: false,
        tags: vec![],
        aliases: vec![],
        comments: vec![],
        attachment: None,
        significance: 0, // Starts at 0
        created_at: 0,
        updated_at: 0,
    };

    let keys = vec!["A", "B", "C", "D", "E"];
    for key in &keys {
        repo.create_node(Nodes::INode(INode {
            key: key.to_string(),
            fields: fields.clone(),
        }))
        .await
        .unwrap();
    }

    // Connect them: A -> B -> C -> D -> E
    let rel_fields = IRelationFields {
        verb: "links".to_string(),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        directionless: false,
        layer: "default".to_string(),
        created_at: 0,
        updated_at: 0,
    };

    let connections = vec![("A", "B"), ("B", "C"), ("B", "D"), ("C", "E")];
    for (idx, (from, to)) in connections.iter().enumerate() {
        repo.create_relation(IRelation {
            key: format!("rel_{}", idx),
            in_: RecordStrings {
                table: INode::LABEL.to_string(),
                key: from.to_string(),
            },
            out: RecordStrings {
                table: INode::LABEL.to_string(),
                key: to.to_string(),
            },
            fields: rel_fields.clone(),
        })
        .await
        .unwrap();
    }

    // Let's manually trigger recalculation on Center Node "A" synchronously so we can immediately assert.
    // Neighbors within 2-step radius of A:
    // A -> B (1 step) -> C (2 steps)
    // A -> B (1 step) -> D (2 steps)
    // A -> B -> C -> E (3 steps - should NOT be in targets of A's 2-step traversal)
    // Let's assert B's score:
    // Outgoing from B: B -> C and B -> D. So d1 = 2.
    // Outgoing from outgoing of B (C and D): C has C -> E (1 relation), D has 0. So d2 = 1.
    // B's raw score = d1 * 1.0 + d2 * 0.5 = 2.0 + 0.5 = 2.5.
    // B's level = min(4, floor(2.5 / 2.0)) = floor(1.25) = 1.
    let strategy = DecaySignificanceStrategy;
    strategy
        .recalculate_area(
            repo.db(),
            RecordStrings {
                table: "INode".to_string(),
                key: "A".to_string(),
            },
        )
        .await
        .expect("Failed to recalculate significance");

    // Fetch nodes and assert significance levels using our polling helper
    assert_significance_eventually(&repo, "INode", "B", 1).await;
    assert_significance_eventually(&repo, "INode", "C", 0).await;
}
