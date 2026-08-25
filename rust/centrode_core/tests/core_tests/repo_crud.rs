use crate::common::setup_test_repo;
use centrode_core::domain::base_models::{Coordinates, Size};
use centrode_core::domain::contents::Content;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::{INode, Nodes, TaskNode, TaskState};
use centrode_core::domain::relations::{IRelation, IRelationFields};
use centrode_core::domain::styles::RelationDirection;
use centrode_core::domain::tags::TagEdge;
use centrode_core::domain::traits::TableKind;
use centrode_core::repo::traits::{NodeRepository, RelationRepository};
use crate::common::make_container_node;

#[tokio::test]
async fn test_inode_crud() {
    let repo = setup_test_repo().await;

    let inode_id = TypedRecordId::new_v4(TableKind::INode);

    let inode = INode {
        id: inode_id,
        parent_container_id: None,
        content: Content::from_plain_text("Test INode Content"),
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
        tags: vec![TagEdge::Pointer(TypedRecordId::new_v4(TableKind::Tag))],
        aliases: vec![],
        comments: vec![],
        attachments: vec![],
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };

    // Create
    repo.nodes.create_node(Nodes::INode(inode.clone()))
        .await
        .expect("Failed to create INode");

    // Read
    let fetched = repo
        .nodes
        .get_node(inode_id)
        .await
        .expect("Failed to get INode")
        .expect("INode not found");

    if let Nodes::INode(fetched_inode) = fetched {
        assert_eq!(fetched_inode.id, inode_id);
        assert_eq!(
            fetched_inode.content.to_plain_text(),
            "Test INode Content"
        );
        assert_eq!(fetched_inode.position.x, 10);
        assert_eq!(fetched_inode.position.y, 20);
    } else {
        panic!("Fetched wrong node variant");
    }

    // Update
    let mut updated_inode = inode.clone();
    updated_inode.content = Content::from_plain_text("Updated INode Content");
    updated_inode.position = Coordinates { x: 50, y: 60 };

    repo.nodes.update_node(Nodes::INode(updated_inode))
        .await
        .expect("Failed to update INode");

    let fetched_updated = repo
        .nodes
        .get_node(inode_id)
        .await
        .expect("Failed to get updated INode")
        .expect("INode not found");

    if let Nodes::INode(fetched_inode) = fetched_updated {
        assert_eq!(
            fetched_inode.content.to_plain_text(),
            "Updated INode Content"
        );
        assert_eq!(fetched_inode.position.x, 50);
        assert_eq!(fetched_inode.position.y, 60);
    } else {
        panic!("Fetched wrong node variant");
    }

    // Delete
    repo.nodes.delete_node(inode_id)
        .await
        .expect("Failed to delete INode");

    let fetched_deleted = repo
        .nodes
        .get_node(inode_id)
        .await
        .expect("Query failed");

    assert!(fetched_deleted.is_none());
}

#[tokio::test]
async fn test_task_node_crud() {
    let repo = setup_test_repo().await;

    let task_id = TypedRecordId::new_v4(TableKind::TaskNode);

    let task_node = TaskNode {
        id: task_id,
        parent_container_id: None,
        content: Content::from_plain_text("Buy groceries"),
        due_date: Some(1700000000),
        state: TaskState::Todo,
        position: Coordinates { x: 100, y: 200 },
        size: Size {
            width: 200,
            height: 100,
        },
        expandable: true,
        is_expanded: false,
        layer: "default".to_string(),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        attachments: vec![],
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };

    // Create
    repo.nodes.create_node(Nodes::TaskNode(task_node.clone()))
        .await
        .expect("Failed to create TaskNode");

    // Read
    let fetched = repo
        .nodes
        .get_node(task_id)
        .await
        .expect("Failed to get TaskNode")
        .expect("TaskNode not found");

    if let Nodes::TaskNode(fetched_task) = fetched {
        assert_eq!(fetched_task.id, task_id);
        assert_eq!(fetched_task.content.to_plain_text(), "Buy groceries");
        assert_eq!(fetched_task.due_date, Some(1700000000));
        assert_eq!(fetched_task.state, TaskState::Todo);
    } else {
        panic!("Fetched wrong node variant");
    }

    // Update
    let mut updated_task = task_node.clone();
    updated_task.state = TaskState::Done;

    repo.nodes.update_node(Nodes::TaskNode(updated_task))
        .await
        .expect("Failed to update TaskNode");

    let fetched_updated = repo
        .nodes
        .get_node(task_id)
        .await
        .expect("Failed to get updated TaskNode")
        .expect("TaskNode not found");

    if let Nodes::TaskNode(fetched_task) = fetched_updated {
        assert_eq!(fetched_task.state, TaskState::Done);
    } else {
        panic!("Fetched wrong node variant");
    }

    // Delete
    repo.nodes.delete_node(task_id)
        .await
        .expect("Failed to delete TaskNode");

    let fetched_deleted = repo
        .nodes
        .get_node(task_id)
        .await
        .expect("Query failed");

    assert!(fetched_deleted.is_none());
}

#[tokio::test]
async fn test_irelation_crud() {
    let repo = setup_test_repo().await;

    let inode_id = TypedRecordId::new_v4(TableKind::INode);
    let task_id = TypedRecordId::new_v4(TableKind::TaskNode);
    let rel_id = TypedRecordId::new_v4(TableKind::IRelation);

    let relation = IRelation {
        key: rel_id,
        in_: inode_id,
        out: task_id,
        fields: IRelationFields {
            verb: "depends_on".to_string(),
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

    // Create
    repo.relations.create_relation(relation.clone())
        .await
        .expect("Failed to create IRelation");

    // Read
    let fetched_rel = repo
        .relations
        .get_relation(rel_id)
        .await
        .expect("Failed to get IRelation");

    assert_eq!(fetched_rel.key, rel_id);
    assert_eq!(fetched_rel.in_, inode_id);
    assert_eq!(fetched_rel.out, task_id);
    assert_eq!(fetched_rel.fields.verb, "depends_on");

    // Update
    let mut updated_fields = relation.fields.clone();
    updated_fields.verb = "blocks".to_string();

    repo.relations.update_relation(rel_id, updated_fields)
        .await
        .expect("Failed to update IRelation");

    let fetched_updated = repo
        .relations
        .get_relation(rel_id)
        .await
        .expect("Failed to get updated IRelation");

    assert_eq!(fetched_updated.fields.verb, "blocks");

    // Delete
    repo.relations.delete_relation(rel_id)
        .await
        .expect("Failed to delete IRelation");

    let fetched_deleted = repo
        .relations
        .get_relation(rel_id)
        .await;

    assert!(fetched_deleted.is_err());
}

#[tokio::test]
async fn test_unique_constraints() {
    let repo = setup_test_repo().await;

    let inode_id = TypedRecordId::new_v4(TableKind::INode);

    let inode = INode {
        id: inode_id,
        parent_container_id: None,
        content: Content::from_plain_text("INode 1"),
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
        attachments: vec![],
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };
    repo.nodes.create_node(Nodes::INode(inode)).await.unwrap();

    let n1_id = TypedRecordId::new_v4(TableKind::INode);
    let n2_id = TypedRecordId::new_v4(TableKind::INode);

    let rel = IRelation {
        key: TypedRecordId::new_v4(TableKind::IRelation),
        in_: n1_id,
        out: n2_id,
        fields: IRelationFields {
            verb: "relates_to".to_string(),
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
    repo.relations.create_relation(rel.clone()).await.unwrap();

    let rel_dup = IRelation {
        key: TypedRecordId::new_v4(TableKind::IRelation),
        ..rel.clone()
    };
    let res_dup = repo.relations.create_relation(rel_dup).await;
    assert!(
        res_dup.is_err(),
        "Duplicate relation unique constraint should fail"
    );
}

#[tokio::test]
async fn test_relation_rerouting_and_deletion() {
    let repo = setup_test_repo().await;

    let n1_id = TypedRecordId::new_v4(TableKind::INode);
    let n2_id = TypedRecordId::new_v4(TableKind::INode);
    let n3_id = TypedRecordId::new_v4(TableKind::INode);

    let node1 = INode {
        id: n1_id,
        parent_container_id: None,
        content: Content::from_plain_text("Node 1"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 0, y: 0 },
        size: Size {
            width: 10,
            height: 10,
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
    };
    let node2 = INode {
        id: n2_id,
        parent_container_id: None,
        content: Content::from_plain_text("Node 2"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 100, y: 0 },
        size: Size {
            width: 10,
            height: 10,
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
    };
    let node3 = INode {
        id: n3_id,
        parent_container_id: None,
        content: Content::from_plain_text("Node 3"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 200, y: 0 },
        size: Size {
            width: 10,
            height: 10,
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
    };

    repo.nodes.create_node(Nodes::INode(node1)).await.unwrap();
    repo.nodes.create_node(Nodes::INode(node2)).await.unwrap();
    repo.nodes.create_node(Nodes::INode(node3)).await.unwrap();

    let rel_id = TypedRecordId::new_v4(TableKind::IRelation);

    let rel = IRelation {
        key: rel_id,
        in_: n1_id,
        out: n2_id,
        fields: IRelationFields {
            verb: "connects".to_string(),
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

    repo.relations.create_relation(rel).await.unwrap();

    let updated = IRelation {
        key: rel_id,
        in_: n1_id,
        out: n3_id,
        fields: IRelationFields {
            verb: "connects".to_string(),
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
    repo.relations.reroute_relation(rel_id, updated)
        .await
        .unwrap();

    let fetched = repo
        .relations
        .get_relation(rel_id)
        .await
        .unwrap();

    assert_eq!(fetched.in_, n1_id);
    assert_eq!(fetched.out, n3_id);
}

#[tokio::test]
async fn test_container_node_crud() {
    let repo = setup_test_repo().await;

    let container_id = TypedRecordId::new_v4(TableKind::ContainerNode);
    let container = make_container_node(container_id, "Test Container", 100, 200);

    // Create
    repo.nodes.create_node(Nodes::ContainerNode(container.clone()))
        .await
        .expect("Failed to create ContainerNode");

    // Read
    let fetched = repo
        .nodes
        .get_node(container_id)
        .await
        .expect("Failed to get ContainerNode")
        .expect("ContainerNode not found");

    if let Nodes::ContainerNode(fetched_container) = fetched {
        assert_eq!(fetched_container.id, container_id);
        assert_eq!(fetched_container.title, "Test Container");
        assert_eq!(fetched_container.position.x, 100);
        assert_eq!(fetched_container.position.y, 200);
        assert_eq!(fetched_container.size.width, 200);
        assert_eq!(fetched_container.size.height, 150);
        assert!(fetched_container.is_closed);
        assert_eq!(fetched_container.child_count, 0);
    } else {
        panic!("Fetched wrong node variant");
    }

    // Update
    let mut updated_container = container.clone();
    updated_container.title = "Updated Container".to_string();
    updated_container.position = Coordinates { x: 300, y: 400 };
    updated_container.is_closed = false;
    updated_container.child_count = 5;

    repo.nodes.update_node(Nodes::ContainerNode(updated_container))
        .await
        .expect("Failed to update ContainerNode");

    let fetched_updated = repo
        .nodes
        .get_node(container_id)
        .await
        .expect("Failed to get updated ContainerNode")
        .expect("ContainerNode not found");

    if let Nodes::ContainerNode(fetched_container) = fetched_updated {
        assert_eq!(fetched_container.title, "Updated Container");
        assert_eq!(fetched_container.position.x, 300);
        assert_eq!(fetched_container.position.y, 400);
        assert!(!fetched_container.is_closed);
        assert_eq!(fetched_container.child_count, 5);
    } else {
        panic!("Fetched wrong node variant");
    }

    // Delete
    repo.nodes.delete_node(container_id)
        .await
        .expect("Failed to delete ContainerNode");

    let fetched_deleted = repo
        .nodes
        .get_node(container_id)
        .await
        .expect("Failed to fetch deleted ContainerNode");

    assert!(fetched_deleted.is_none(), "ContainerNode should be deleted");
}
