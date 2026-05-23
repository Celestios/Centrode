use crate::common::setup_test_repo;
use mycelium_core::domain::base_models::{Coordinates, RecordStrings, Size};
use mycelium_core::domain::contents::Content;
use mycelium_core::domain::nodes::{
    INode, INodeFields, InterNode, InterNodeFields, Nodes, TaskNode, TaskNodeFields,
};
use mycelium_core::domain::relations::{IRelation, IRelationFields};
use mycelium_core::domain::tags::TagEdge;
use std::time::Duration;

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
