mod common;

use common::setup_test_repo;
use mycelium_core::domain::analysis::{DecaySignificanceStrategy, GraphAnalysis};
use mycelium_core::domain::base_models::{BoundingBox, Coordinates, MapData, Size};
use mycelium_core::domain::contents::Content;
use mycelium_core::domain::nodes::{
    INode, INodeFields, InterNode, InterNodeFields, Nodes, TaskNode, TaskNodeFields,
};
use mycelium_core::domain::relations::{IRelation, IRelationFields};
use mycelium_core::persistence::history::HistoryManager;
use std::time::Duration;
use surrealdb::types::{RecordId, SurrealValue};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, SurrealValue)]
struct TestPayload {
    key: String,
}

#[tokio::test]
async fn test_repo_crud() {
    let repo = setup_test_repo().await;

    // 1. Create InfoNode (INode)
    let inode = INode {
        key: "inode_1".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("This is an Info Node"),
            style: None,
            resolved_style: None,
            layer: "default".to_string(),
            position: Coordinates { x: 100, y: 150 },
            size: Size {
                width: 10,
                height: 10,
            },
            line_count: 1,
            expandable: true,
            is_expanded: false,
            locked: false,
            tags: vec!["tag1".to_string()],
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
        .expect("Failed to create INode");

    // Fetch and check INode
    let fetched = repo
        .get_node("INode".to_string(), "inode_1".to_string())
        .await
        .expect("Failed to fetch INode");
    assert!(fetched.is_some());
    if let Some(Nodes::INode(n)) = fetched {
        assert_eq!(n.key, "inode_1");
        assert_eq!(n.fields.content.text, "This is an Info Node");
        assert_eq!(n.fields.position.x, 100);
    } else {
        panic!("Fetched node was not an INode");
    }

    // Update INode
    let mut updated_inode = inode.clone();
    updated_inode.fields.content = Content::from_plain_text("Updated Info Node");
    updated_inode.fields.position.x = 200;
    repo.update_node(Nodes::INode(updated_inode))
        .await
        .expect("Failed to update INode");

    let fetched_updated = repo
        .get_node("INode".to_string(), "inode_1".to_string())
        .await
        .expect("Failed to fetch updated INode");
    if let Some(Nodes::INode(n)) = fetched_updated {
        assert_eq!(n.fields.content.text, "Updated Info Node");
        assert_eq!(n.fields.position.x, 200);
    } else {
        panic!("Updated node not found or incorrect type");
    }

    // 2. Create TaskNode
    let tasknode = TaskNode {
        key: "task_1".to_string(),
        fields: TaskNodeFields {
            content: Content::from_plain_text("Test Task"),
            due_date: Some(123456789),
            state: "todo".to_string(),
            position: Coordinates { x: -50, y: -50 },
            size: Size {
                width: 20,
                height: 20,
            },
            expandable: false,
            is_expanded: false,
            layer: "default".to_string(),
            style: None,
            resolved_style: None,
            significance: 1,
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_node(Nodes::TaskNode(tasknode.clone()))
        .await
        .expect("Failed to create TaskNode");

    // Fetch and check TaskNode
    let fetched_task = repo
        .get_node("TaskNode".to_string(), "task_1".to_string())
        .await
        .expect("Failed to fetch TaskNode");
    assert!(fetched_task.is_some());
    if let Some(Nodes::TaskNode(t)) = fetched_task {
        assert_eq!(t.key, "task_1");
        assert_eq!(t.fields.state, "todo");
    } else {
        panic!("Fetched node was not a TaskNode");
    }

    // 3. Create InterNode
    let internode = InterNode {
        key: "inter_1".to_string(),
        fields: InterNodeFields {
            verb: "implies".to_string(),
            behavioral_features: None,
            position: Coordinates { x: 25, y: 50 },
            style: None,
            layer: "default".to_string(),
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_node(Nodes::InterNode(internode.clone()))
        .await
        .expect("Failed to create InterNode");

    // Fetch and check InterNode
    let fetched_inter = repo
        .get_node("InterNode".to_string(), "inter_1".to_string())
        .await
        .expect("Failed to fetch InterNode");
    assert!(fetched_inter.is_some());
    if let Some(Nodes::InterNode(i)) = fetched_inter {
        assert_eq!(i.key, "inter_1");
        assert_eq!(i.fields.verb, "implies");
    } else {
        panic!("Fetched node was not an InterNode");
    }

    // 4. Create Relation linking inode_1 to task_1
    let relation = IRelation {
        key: "rel_1".to_string(),
        in_: "INode:inode_1".to_string(),
        out: "TaskNode:task_1".to_string(),
        fields: IRelationFields {
            verb: "depends_on".to_string(),
            style: None,
            resolved_style: None,
            directionless: false,
            layer: "default".to_string(),
            created_at: 0,
            updated_at: 0,
        },
    };
    repo.create_relation(relation.clone())
        .await
        .expect("Failed to create relation");

    // Give background significance update a moment to trigger/log
    tokio::time::sleep(Duration::from_millis(50)).await;

    // Fetch Relation
    let fetched_rel = repo
        .get_relation("IRelation".to_string(), "rel_1".to_string())
        .await
        .expect("Failed to get relation");
    assert_eq!(fetched_rel.key, "rel_1");
    assert_eq!(fetched_rel.in_, "INode:inode_1");
    assert_eq!(fetched_rel.out, "TaskNode:task_1");
    assert_eq!(fetched_rel.fields.verb, "depends_on");

    // Update Relation
    let mut updated_fields = relation.fields.clone();
    updated_fields.verb = "supports".to_string();
    repo.update_relation("IRelation".to_string(), "rel_1".to_string(), updated_fields)
        .await
        .expect("Failed to update relation");

    let fetched_updated_rel = repo
        .get_relation("IRelation".to_string(), "rel_1".to_string())
        .await
        .expect("Failed to get updated relation");
    assert_eq!(fetched_updated_rel.fields.verb, "supports");

    // 5. Test cascading delete: Delete node 'inode_1' and verify 'rel_1' is cascading deleted
    repo.delete_node("INode".to_string(), "inode_1".to_string())
        .await
        .expect("Failed to delete INode");

    let relation_after_delete = repo
        .get_relation("IRelation".to_string(), "rel_1".to_string())
        .await;
    assert!(
        relation_after_delete.is_err(),
        "Relation should have been cascading deleted when its endpoint was deleted"
    );

    // Clean up remaining nodes
    repo.delete_node("TaskNode".to_string(), "task_1".to_string())
        .await
        .expect("Failed to clean up TaskNode");
    repo.delete_node("InterNode".to_string(), "inter_1".to_string())
        .await
        .expect("Failed to clean up InterNode");
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

    // Overwrite snapshot atomically
    let new_inodes = vec![INode {
        key: "new_inode_snap".to_string(),
        fields: inode.fields.clone(),
    }];
    let new_metadata = MapData {
        map_name: "Overwritten Map".to_string(),
        ..Default::default()
    };

    repo.set_graph_snapshot(new_inodes, vec![], vec![], vec![], new_metadata)
        .await
        .expect("Failed to write new graph snapshot");

    // Retrieve again and verify state has changed completely
    let (inodes_v2, tasks_v2, inters_v2, relations_v2, metadata_v2) = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch overwritten graph snapshot");
    assert_eq!(inodes_v2.len(), 1);
    assert_eq!(inodes_v2[0].key, "new_inode_snap");
    assert_eq!(tasks_v2.len(), 0);
    assert_eq!(inters_v2.len(), 0);
    assert_eq!(relations_v2.len(), 0);
    assert_eq!(metadata_v2.map_name, "Overwritten Map");
}

#[tokio::test]
async fn test_history_manager() {
    let repo = setup_test_repo().await;

    // Use a strict threshold of 3 for testing
    let history = HistoryManager::new(repo.db(), 3);

    // Clear history to start fresh
    let _: Vec<surrealdb::types::Value> = repo
        .db()
        .query("DELETE History")
        .await
        .unwrap()
        .take(0)
        .unwrap();

    // Push 5 events
    history
        .push_event("add_node", TestPayload { key: "node_1".to_string() }.into_value())
        .await
        .unwrap();
    history
        .push_event("add_node", TestPayload { key: "node_2".to_string() }.into_value())
        .await
        .unwrap();
    history
        .push_event("add_node", TestPayload { key: "node_3".to_string() }.into_value())
        .await
        .unwrap();
    history
        .push_event("add_node", TestPayload { key: "node_4".to_string() }.into_value())
        .await
        .unwrap();
    history
        .push_event("add_node", TestPayload { key: "node_5".to_string() }.into_value())
        .await
        .unwrap();


    // Check threshold pruning (max 3 applied events should remain)
    let mut count_response = repo
        .db()
        .query("RETURN count(SELECT * FROM History WHERE status = 'applied')")
        .await
        .unwrap();
    let count: Option<i64> = count_response.take(0).unwrap();
    assert_eq!(count.unwrap_or(0), 3);

    // Undo cycle
    let undone = history.undo().await.unwrap();
    assert!(undone.is_some());
    let undone_rec = undone.unwrap();
    assert_eq!(undone_rec.action_type, "add_node");

    let payload_val = TestPayload::from_value(undone_rec.payload).unwrap();
    assert_eq!(payload_val.key, "node_5");

    // Redo cycle
    let redone = history.redo().await.unwrap();
    assert!(redone.is_some());
    let redone_rec = redone.unwrap();
    assert_eq!(redone_rec.action_type, "add_node");

    let redone_payload = TestPayload::from_value(redone_rec.payload).unwrap();
    assert_eq!(redone_payload.key, "node_5");

    // Undo again
    let _ = history.undo().await.unwrap();

    // Pushing a new event after undo should clear the redo (undone) stack
    history
        .push_event("add_node", TestPayload { key: "node_6".to_string() }.into_value())
        .await
        .unwrap();

    let mut undone_query = repo
        .db()
        .query("SELECT count() FROM History WHERE status = 'undone'")
        .await
        .unwrap();
    let undone_count: Option<i64> = undone_query.take(0).unwrap();
    assert_eq!(undone_count.unwrap_or(0), 0);
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
        directionless: false,
        layer: "default".to_string(),
        created_at: 0,
        updated_at: 0,
    };

    let connections = vec![("A", "B"), ("B", "C"), ("B", "D"), ("C", "E")];
    for (idx, (from, to)) in connections.iter().enumerate() {
        repo.create_relation(IRelation {
            key: format!("rel_{}", idx),
            in_: format!("INode:{}", from),
            out: format!("INode:{}", to),
            fields: rel_fields.clone(),
        })
        .await
        .unwrap();
    }

    // Wait for the spawned background tasks of create_relation to finish so they don't interfere
    tokio::time::sleep(Duration::from_millis(100)).await;

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
        .recalculate_area(repo.db(), RecordId::new("INode", "A"))
        .await
        .expect("Failed to recalculate significance");

    // Fetch nodes and assert significance levels
    if let Some(Nodes::INode(n_b)) = repo
        .get_node("INode".to_string(), "B".to_string())
        .await
        .unwrap()
    {
        assert_eq!(n_b.fields.significance, 1);
    } else {
        panic!("Failed to retrieve Node B");
    }

    // Node C is also a neighbor of A (via A -> B -> C)?
    // Wait, the traversal is `->IRelation->(INode, TaskNode)`. This is a single hop traversal.
    // Let's trace line 25 of analysis.rs:
    // `LET $targets = (SELECT id FROM (SELECT ->{0}->({1}, {2}) AS neighbors FROM $center).neighbors);`
    // Yes! This selects ONLY direct neighbors of the center node (1 step away).
    // So target is B. B gets updated.
    // Node C (which is 2 steps away) is NOT in `$targets`, so its significance is NOT updated.
    // Let's verify Node C significance is still 0 (since it was never in targets).
    if let Some(Nodes::INode(n_c)) = repo
        .get_node("INode".to_string(), "C".to_string())
        .await
        .unwrap()
    {
        assert_eq!(n_c.fields.significance, 0);
    } else {
        panic!("Failed to retrieve Node C");
    }
}
