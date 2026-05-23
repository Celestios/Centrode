mod common;

use common::setup_test_repo;
use mycelium_core::domain::analysis::{DecaySignificanceStrategy, GraphAnalysis};
use mycelium_core::domain::base_models::{BoundingBox, Coordinates, MapData, RecordStrings, Size};
use mycelium_core::domain::contents::Content;
use mycelium_core::domain::nodes::{
    INode, INodeFields, InterNode, InterNodeFields, Nodes, TaskNode, TaskNodeFields,
};
use mycelium_core::domain::relations::{IRelation, IRelationFields};
use mycelium_core::domain::tags::TagEdge;
use mycelium_core::persistence::history::HistoryManager;
use std::time::Duration;
use surrealdb::types::{RecordId, SurrealValue};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, SurrealValue)]
struct TestPayload {
    key: String,
}

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
    let node = repo.get_node(table.to_string(), key.to_string()).await.unwrap().unwrap();
    let sig = match node {
        Nodes::INode(n) => n.fields.significance,
        Nodes::TaskNode(t) => t.fields.significance,
        Nodes::InterNode(_) => 0,
    };
    assert_eq!(sig, expected, "Node {}/{} significance did not reach expected value", table, key);
}

#[tokio::test]
async fn test_repo_crud() {
    let repo = setup_test_repo().await;

    use mycelium_core::domain::tags::Tag;
    let tag = Tag {
        name: "tag1".to_string(),
        color: 0xFF00FF,
    };

    repo.create_tag(tag.clone())
        .await
        .expect("Failed to create tag");

    // 1. Create InfoNode (INode)
    let inode = INode {
        key: "inode_1".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("This is an Info Node"),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
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
            tags: vec![TagEdge::Pointer(RecordStrings {
                table: "Tag".to_string(),
                key: "tag1".to_string(),
            })],
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
            layout: None,
            resolved_layout: None,
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
            layout: None,
            resolved_layout: None,
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

    // Assert inode_1 is actually deleted
    let inode_after_delete = repo
        .get_node("INode".to_string(), "inode_1".to_string())
        .await
        .expect("Failed to query inode_1 after delete");
    assert!(inode_after_delete.is_none(), "INode inode_1 should have been deleted");

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
    let task_after_delete = repo
        .get_node("TaskNode".to_string(), "task_1".to_string())
        .await
        .expect("Failed to query task_1 after delete");
    assert!(task_after_delete.is_none(), "TaskNode task_1 should have been deleted");

    repo.delete_node("InterNode".to_string(), "inter_1".to_string())
        .await
        .expect("Failed to clean up InterNode");
    let inter_after_delete = repo
        .get_node("InterNode".to_string(), "inter_1".to_string())
        .await
        .expect("Failed to query inter_1 after delete");
    assert!(inter_after_delete.is_none(), "InterNode inter_1 should have been deleted");
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
        size: Size { width: 30, height: 30 },
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
        in_: "INode:new_inode_snap".to_string(),
        out: "TaskNode:new_task_snap".to_string(),
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

    repo.set_graph_snapshot(new_inodes, new_tasks, new_inters, new_relations, new_metadata)
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
    assert_eq!(relations_v2[0].in_, "INode:new_inode_snap");
    assert_eq!(relations_v2[0].out, "TaskNode:new_task_snap");
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
        .push_event(
            "add_node",
            TestPayload {
                key: "node_1".to_string(),
            }
            .into_value(),
        )
        .await
        .unwrap();
    history
        .push_event(
            "add_node",
            TestPayload {
                key: "node_2".to_string(),
            }
            .into_value(),
        )
        .await
        .unwrap();
    history
        .push_event(
            "add_node",
            TestPayload {
                key: "node_3".to_string(),
            }
            .into_value(),
        )
        .await
        .unwrap();
    history
        .push_event(
            "add_node",
            TestPayload {
                key: "node_4".to_string(),
            }
            .into_value(),
        )
        .await
        .unwrap();
    history
        .push_event(
            "add_node",
            TestPayload {
                key: "node_5".to_string(),
            }
            .into_value(),
        )
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
        .push_event(
            "add_node",
            TestPayload {
                key: "node_6".to_string(),
            }
            .into_value(),
        )
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
            in_: format!("INode:{}", from),
            out: format!("INode:{}", to),
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
        .recalculate_area(repo.db(), RecordId::new("INode", "A"))
        .await
        .expect("Failed to recalculate significance");

    // Fetch nodes and assert significance levels using our polling helper
    assert_significance_eventually(&repo, "INode", "B", 1).await;
    assert_significance_eventually(&repo, "INode", "C", 0).await;
}

#[tokio::test]
async fn test_targeted_patch_and_history() {
    use mycelium_core::domain::base_models::RecordStrings;
    use mycelium_core::domain::patches::{EntityPatch, NodePatch, PatchHistoryPayload};

    let repo = setup_test_repo().await;
    let history = HistoryManager::new(repo.db(), 5);

    // 1. Create a node
    let inode = INode {
        key: "inode_patch_test".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("Patch test node"),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            layer: "default".to_string(),
            position: Coordinates { x: 10, y: 20 },
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
    repo.create_node(Nodes::INode(inode)).await.unwrap();

    let record_id = RecordId::new("INode", "inode_patch_test");

    // 2. Define targeted patch mutations
    let forward_patch = EntityPatch::Node(vec![
        NodePatch::Position(Coordinates { x: 50, y: 60 }),
        NodePatch::IsExpanded(true),
    ]);
    let reverse_patch = EntityPatch::Node(vec![
        NodePatch::Position(Coordinates { x: 10, y: 20 }),
        NodePatch::IsExpanded(false),
    ]);

    // 3. Apply forward patch
    repo.patch_entity(record_id.clone(), &forward_patch)
        .await
        .unwrap();

    // Verify database is updated
    let fetched = repo
        .get_node("INode".to_string(), "inode_patch_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(ref n) = fetched {
        assert_eq!(n.fields.position.x, 50);
        assert_eq!(n.fields.position.y, 60);
        assert_eq!(n.fields.is_expanded, true);
    } else {
        panic!("Incorrect node type");
    }

    // 4. Log to history
    let payload = PatchHistoryPayload {
        id: RecordStrings {
            table: "INode".to_string(),
            key: "inode_patch_test".to_string(),
        },
        forward: forward_patch,
        reverse: reverse_patch,
    };
    history
        .push_event("entity_patch", payload.into_value())
        .await
        .unwrap();

    // 5. Undo
    let undone = history.undo().await.unwrap();
    assert!(undone.is_some());
    let rec_undone = undone.unwrap();
    assert_eq!(rec_undone.action_type, "entity_patch");

    let payload_undone = PatchHistoryPayload::from_value(rec_undone.payload).unwrap();
    let target_id = RecordId::new(
        payload_undone.id.table.as_str(),
        payload_undone.id.key.as_str(),
    );
    repo.patch_entity(target_id, &payload_undone.reverse)
        .await
        .unwrap();

    // Verify undone state
    let fetched_undone = repo
        .get_node("INode".to_string(), "inode_patch_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(ref n) = fetched_undone {
        assert_eq!(n.fields.position.x, 10);
        assert_eq!(n.fields.position.y, 20);
        assert_eq!(n.fields.is_expanded, false);
    } else {
        panic!("Incorrect node type");
    }

    // 6. Redo
    let redone = history.redo().await.unwrap();
    assert!(redone.is_some());
    let rec_redone = redone.unwrap();
    assert_eq!(rec_redone.action_type, "entity_patch");

    let payload_redone = PatchHistoryPayload::from_value(rec_redone.payload).unwrap();
    let target_id_redone = RecordId::new(
        payload_redone.id.table.as_str(),
        payload_redone.id.key.as_str(),
    );
    repo.patch_entity(target_id_redone, &payload_redone.forward)
        .await
        .unwrap();

    // Verify redone state
    let fetched_redone = repo
        .get_node("INode".to_string(), "inode_patch_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(ref n) = fetched_redone {
        assert_eq!(n.fields.position.x, 50);
        assert_eq!(n.fields.position.y, 60);
        assert_eq!(n.fields.is_expanded, true);
    } else {
        panic!("Incorrect node type");
    }
}

#[tokio::test]
async fn test_tags_crud_and_patching() {
    use mycelium_core::domain::patches::{EntityPatch, NodePatch, TagOperation};
    use mycelium_core::domain::tags::Tag;

    let repo = setup_test_repo().await;

    // 1. Create a tag
    let tag = Tag {
        name: "test_tag_rust".to_string(),
        color: 0xFF00FF,
    };
    repo.create_tag(tag.clone())
        .await
        .expect("Failed to create tag");

    // 2. Read the tag back
    let fetched_tag = repo
        .get_tag("test_tag_rust".to_string())
        .await
        .expect("Failed to get tag");
    assert!(fetched_tag.is_some());
    let fetched_tag = fetched_tag.unwrap();
    assert_eq!(fetched_tag.name, "test_tag_rust");
    assert_eq!(fetched_tag.color, 0xFF00FF);

    // 3. List all tags
    let all_tags = repo.get_all_tags().await.expect("Failed to get all tags");
    assert!(all_tags
        .iter()
        .any(|t| t.name == "test_tag_rust" && t.color == 0xFF00FF));

    // 4. Create an INode
    let inode = INode {
        key: "inode_tag_test".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("Tag test node"),
            style: None,
            resolved_style: None,
            layout: None,
            resolved_layout: None,
            layer: "default".to_string(),
            position: Coordinates { x: 10, y: 20 },
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
    repo.create_node(Nodes::INode(inode)).await.unwrap();

    let record_id = RecordId::new("INode", "inode_tag_test");

    // 5. Add tag to the INode using patch
    let add_patch = EntityPatch::Node(vec![NodePatch::TagOp(TagOperation::Add(
        "test_tag_rust".to_string(),
    ))]);
    repo.patch_entity(record_id.clone(), &add_patch)
        .await
        .unwrap();

    // 6. Retrieve INode and verify tag is added & hydrated
    let fetched_node = repo
        .get_node("INode".to_string(), "inode_tag_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched_node {
        assert_eq!(n.fields.tags.len(), 1);
        match &n.fields.tags[0] {
            TagEdge::Hydrated(t) => {
                assert_eq!(t.name, "test_tag_rust");
                assert_eq!(t.color, 0xFF00FF);
            }
            TagEdge::Pointer(p) => {
                panic!("Expected tag to be hydrated but got pointer: {:?}", p);
            }
        }
    } else {
        panic!("Incorrect node type");
    }

    // 7. Remove tag from the INode using patch
    let remove_patch = EntityPatch::Node(vec![NodePatch::TagOp(TagOperation::Remove(
        "test_tag_rust".to_string(),
    ))]);
    repo.patch_entity(record_id.clone(), &remove_patch)
        .await
        .unwrap();

    // 8. Retrieve INode and verify tag is removed
    let fetched_node_after_remove = repo
        .get_node("INode".to_string(), "inode_tag_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched_node_after_remove {
        assert_eq!(n.fields.tags.len(), 0);
    } else {
        panic!("Incorrect node type");
    }

    // 9. Delete the tag
    repo.delete_tag("test_tag_rust".to_string())
        .await
        .expect("Failed to delete tag");
    let fetched_tag_deleted = repo
        .get_tag("test_tag_rust".to_string())
        .await
        .expect("Failed to get tag");
    assert!(fetched_tag_deleted.is_none());
}

#[tokio::test]
async fn test_error_cases() {
    let repo = setup_test_repo().await;

    // 1. Query non-existent node
    let res = repo.get_node("INode".to_string(), "nonexistent".to_string()).await;
    assert!(res.is_ok());
    assert!(res.unwrap().is_none());

    // 2. Query non-existent relation
    let res = repo.get_relation("IRelation".to_string(), "nonexistent".to_string()).await;
    assert!(res.is_err());

    // 3. Duplicate relation (unique constraint)
    let node_fields = INodeFields {
        content: Content::from_plain_text("node"),
        style: None, resolved_style: None, layout: None, resolved_layout: None,
        layer: "default".to_string(), position: Coordinates { x: 0, y: 0 },
        size: Size { width: 10, height: 10 }, line_count: 1, expandable: false,
        is_expanded: false, locked: false, tags: vec![], aliases: vec![],
        comments: vec![], attachment: None, significance: 0, created_at: 0, updated_at: 0,
    };
    repo.create_node(Nodes::INode(INode { key: "n1".to_string(), fields: node_fields.clone() })).await.unwrap();
    repo.create_node(Nodes::INode(INode { key: "n2".to_string(), fields: node_fields.clone() })).await.unwrap();

    let rel = IRelation {
        key: "rel_dup_1".to_string(),
        in_: "INode:n1".to_string(),
        out: "INode:n2".to_string(),
        fields: IRelationFields {
            verb: "test_verb".to_string(),
            style: None, resolved_style: None, layout: None, resolved_layout: None,
            directionless: false, layer: "default".to_string(), created_at: 0, updated_at: 0,
        }
    };
    repo.create_relation(rel.clone()).await.unwrap();

    // Try to insert another relation with the same in, out, and verb
    let rel_dup = IRelation {
        key: "rel_dup_2".to_string(),
        ..rel.clone()
    };
    let res_dup = repo.create_relation(rel_dup).await;
    assert!(res_dup.is_err(), "Duplicate relation unique constraint should fail");
}

#[tokio::test]
async fn test_relation_rerouting_and_deletion() {
    let repo = setup_test_repo().await;

    let node_fields = INodeFields {
        content: Content::from_plain_text("node"),
        style: None, resolved_style: None, layout: None, resolved_layout: None,
        layer: "default".to_string(), position: Coordinates { x: 0, y: 0 },
        size: Size { width: 10, height: 10 }, line_count: 1, expandable: false,
        is_expanded: false, locked: false, tags: vec![], aliases: vec![],
        comments: vec![], attachment: None, significance: 0, created_at: 0, updated_at: 0,
    };
    repo.create_node(Nodes::INode(INode { key: "n1".to_string(), fields: node_fields.clone() })).await.unwrap();
    repo.create_node(Nodes::INode(INode { key: "n2".to_string(), fields: node_fields.clone() })).await.unwrap();
    repo.create_node(Nodes::INode(INode { key: "n3".to_string(), fields: node_fields.clone() })).await.unwrap();

    let rel = IRelation {
        key: "rel_route".to_string(),
        in_: "INode:n1".to_string(),
        out: "INode:n2".to_string(),
        fields: IRelationFields {
            verb: "relates".to_string(),
            style: None, resolved_style: None, layout: None, resolved_layout: None,
            directionless: false, layer: "default".to_string(), created_at: 0, updated_at: 0,
        }
    };
    repo.create_relation(rel.clone()).await.unwrap();

    // 1. Delete relation
    repo.delete_relation("IRelation".to_string(), "rel_route".to_string()).await.unwrap();
    let res = repo.get_relation("IRelation".to_string(), "rel_route".to_string()).await;
    assert!(res.is_err(), "Relation should be deleted");

    // Make sure endpoints still exist
    assert!(repo.get_node("INode".to_string(), "n1".to_string()).await.unwrap().is_some());
    assert!(repo.get_node("INode".to_string(), "n2".to_string()).await.unwrap().is_some());

    // 2. Re-create relation and test rerouting
    repo.create_relation(rel.clone()).await.unwrap();
    repo.reroute_relation(
        RecordStrings { table: "IRelation".to_string(), key: "rel_route".to_string() },
        RecordStrings { table: "INode".to_string(), key: "n1".to_string() },
        RecordStrings { table: "INode".to_string(), key: "n3".to_string() },
    ).await.unwrap();

    let fetched = repo.get_relation("IRelation".to_string(), "rel_route".to_string()).await.unwrap();
    assert_eq!(fetched.in_, "INode:n1");
    assert_eq!(fetched.out, "INode:n3");
}

#[tokio::test]
async fn test_remaining_patches() {
    use mycelium_core::domain::patches::{EntityPatch, NodePatch, RelationPatch};
    use mycelium_core::domain::styles::{NodeStyle, RelationStyle, RelationLayout};

    let repo = setup_test_repo().await;

    let inode = INode {
        key: "n_patch".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("original"),
            style: None, resolved_style: None, layout: None, resolved_layout: None,
            layer: "default".to_string(), position: Coordinates { x: 0, y: 0 },
            size: Size { width: 10, height: 10 }, line_count: 1, expandable: false,
            is_expanded: false, locked: false, tags: vec![], aliases: vec![],
            comments: vec![], attachment: None, significance: 0, created_at: 0, updated_at: 0,
        }
    };
    repo.create_node(Nodes::INode(inode)).await.unwrap();
    let node_id = RecordId::new("INode", "n_patch");

    let style = NodeStyle {
        bg_color: 0x123456, stroke_color: 0x789abc, stroke_width: 2,
        font_family: "Arial".to_string(), font_size: 14.0, shape: "circle".to_string(),
        width: 15, height: 15, text_color: 0xffffff, border_radius: 4.0,
        padding: 8.0, shadow_color: 0, shadow_blur: 0.0, shadow_spread: 0.0,
        shadow_offset_x: 0.0, shadow_offset_y: 0.0, strategy_type: "default".to_string(),
    };
    let content = Content::from_plain_text("patched content");

    let patch = EntityPatch::Node(vec![
        NodePatch::Size(Size { width: 42, height: 42 }),
        NodePatch::Content(content.clone()),
        NodePatch::Style(Some(style.clone())),
        NodePatch::Significance(3),
    ]);

    repo.patch_entity(node_id.clone(), &patch).await.unwrap();

    let fetched = repo.get_node("INode".to_string(), "n_patch".to_string()).await.unwrap().unwrap();
    if let Nodes::INode(n) = fetched {
        assert_eq!(n.fields.size.width, 42);
        assert_eq!(n.fields.size.height, 42);
        assert_eq!(n.fields.content.text, "patched content");
        assert_eq!(n.fields.style.as_ref().unwrap().bg_color, 0x123456);
        assert_eq!(n.fields.significance, 3);
    } else {
        panic!("Not an INode");
    }

    let target = INode {
        key: "n_patch_target".to_string(),
        fields: INodeFields {
            content: Content::from_plain_text("target"),
            style: None, resolved_style: None, layout: None, resolved_layout: None,
            layer: "default".to_string(), position: Coordinates { x: 50, y: 50 },
            size: Size { width: 10, height: 10 }, line_count: 1, expandable: false,
            is_expanded: false, locked: false, tags: vec![], aliases: vec![],
            comments: vec![], attachment: None, significance: 0, created_at: 0, updated_at: 0,
        }
    };
    repo.create_node(Nodes::INode(target)).await.unwrap();

    let rel = IRelation {
        key: "r_patch".to_string(),
        in_: "INode:n_patch".to_string(),
        out: "INode:n_patch_target".to_string(),
        fields: IRelationFields {
            verb: "relates".to_string(),
            style: None, resolved_style: None, layout: None, resolved_layout: None,
            directionless: false, layer: "default".to_string(), created_at: 0, updated_at: 0,
        }
    };
    repo.create_relation(rel).await.unwrap();
    let rel_id = RecordId::new("IRelation", "r_patch");

    let rel_style = RelationStyle {
        bg_color: 0x111111, stroke_color: 0x222222, stroke_width: 1,
        font_family: "Sans".to_string(), font_size: 10.0, shape: "line".to_string(),
        arrow_type: "arrow".to_string(), arrow_size: 5.0, width: 0, height: 0,
        text_color: 0x333333, shadow_color: 0, shadow_blur: 0.0,
        shadow_offset_x: 0.0, shadow_offset_y: 0.0, strategy_type: "default".to_string(),
    };
    let rel_layout = RelationLayout {
        from_side: "right".to_string(),
        to_side: "left".to_string(),
        strategy_type: "custom".to_string(),
    };

    let rel_patch = EntityPatch::Relation(vec![
        RelationPatch::Verb("patched_verb".to_string()),
        RelationPatch::Style(Some(rel_style.clone())),
        RelationPatch::Layout(Some(rel_layout.clone())),
        RelationPatch::Directionless(true),
    ]);

    repo.patch_entity(rel_id, &rel_patch).await.unwrap();

    let fetched_rel = repo.get_relation("IRelation".to_string(), "r_patch".to_string()).await.unwrap();
    assert_eq!(fetched_rel.fields.verb, "patched_verb");
    assert_eq!(fetched_rel.fields.style.as_ref().unwrap().stroke_color, 0x222222);
    assert_eq!(fetched_rel.fields.layout.as_ref().unwrap().from_side, "right");
    assert_eq!(fetched_rel.fields.directionless, true);
}

#[tokio::test]
async fn test_theme_crud_and_active_theme() {
    use mycelium_core::domain::theme::{ThemeFields, ThemeBrightness, FontWeight};

    let repo = setup_test_repo().await;

    let theme_fields = ThemeFields {
        name: "My Dark Theme".to_string(),
        primary_color: 0x112233,
        scaffold_background_color: 0x000000,
        card_color: 0x222222,
        divider_color: 0x333333,
        text_color: 0xffffff,
        font_family: "Roboto".to_string(),
        body_font_size: 14.0,
        body_font_weight: FontWeight(3),
        body_text_color: 0xdddddd,
        border_radius: 8.0,
        app_bar_background_color: 0x111111,
        app_bar_foreground_color: 0xeeeeee,
        app_bar_elevation: 4.0,
        app_bar_title_font_size: 18.0,
        app_bar_title_font_weight: FontWeight(6),
        use_material3: true,
        brightness: ThemeBrightness::Dark,
    };

    let theme_id = RecordId::new("MapTheme", "dark_theme");
    let _: Option<ThemeFields> = repo.db()
        .query("CREATE $record_id CONTENT $fields")
        .bind(("record_id", theme_id.clone()))
        .bind(("fields", theme_fields.clone()))
        .await
        .unwrap()
        .take(0)
        .unwrap();

    let fetched_fields: Option<ThemeFields> = repo.db().select(theme_id.clone()).await.unwrap();
    assert!(fetched_fields.is_some());
    let fetched_fields = fetched_fields.unwrap();
    assert_eq!(fetched_fields.name, "My Dark Theme");
    assert_eq!(fetched_fields.primary_color, 0x112233);

    let mut updated_fields = theme_fields.clone();
    updated_fields.name = "Updated Dark Theme".to_string();
    updated_fields.primary_color = 0x445566;
    let _: Option<ThemeFields> = repo.db()
        .query("UPDATE $record_id MERGE $fields")
        .bind(("record_id", theme_id.clone()))
        .bind(("fields", updated_fields))
        .await
        .unwrap()
        .take(0)
        .unwrap();

    let fetched_updated: ThemeFields = repo.db().select(theme_id.clone()).await.unwrap().unwrap();
    assert_eq!(fetched_updated.name, "Updated Dark Theme");
    assert_eq!(fetched_updated.primary_color, 0x445566);

    let map_data_id = RecordId::new("MapMetaData", "singleton");
    repo.db()
        .query("UPDATE $record SET active_theme_id = $theme_id")
        .bind(("record", map_data_id.clone()))
        .bind(("theme_id", "dark_theme".to_string()))
        .await
        .unwrap();

    let mut res = repo.db()
        .query("SELECT VALUE active_theme_id FROM $record")
        .bind(("record", map_data_id))
        .await
        .unwrap();
    let active_theme_id: Option<String> = res.take(0).unwrap();
    assert_eq!(active_theme_id, Some("dark_theme".to_string()));

    let themes: Vec<ThemeFields> = repo.db().select("MapTheme").await.unwrap();
    assert_eq!(themes.len(), 1);
    assert_eq!(themes[0].name, "Updated Dark Theme");
}
