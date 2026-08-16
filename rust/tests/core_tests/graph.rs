use crate::common::setup_test_repo;
use centrode_core::domain::base_models::{
    BoundingBox, Coordinates, MapData, Size,
};
use centrode_core::domain::contents::Content;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::{
    INode, InterNode, Nodes, TaskNode, TaskState,
};
use centrode_core::domain::relations::{IRelation, IRelationFields};
use centrode_core::domain::snapshot::GraphSnapshot;
use centrode_core::domain::styles::RelationDirection;
use centrode_core::domain::traits::TableKind;

async fn assert_significance_eventually(
    repo: &centrode_core::persistence::repo::Repository,
    table: &str,
    key: &str,
    expected: u8,
) {
    let start = std::time::Instant::now();
    let timeout = std::time::Duration::from_millis(1000);
    let interval = std::time::Duration::from_millis(10);
    let typed_id = TypedRecordId::from(format!("{}:{}", table, key).as_str());
    while start.elapsed() < timeout {
        if let Ok(Some(node)) = repo.get_node(typed_id).await {
            let sig = match node {
                Nodes::INode(n) => n.significance,
                Nodes::TaskNode(t) => t.significance,
                Nodes::ContainerNode(c) => c.significance,
                _ => 0,
            };
            if sig == expected {
                return;
            }
        }
        tokio::time::sleep(interval).await;
    }
    let node = repo
        .get_node(typed_id)
        .await
        .unwrap()
        .unwrap();
    let sig = match node {
        Nodes::INode(n) => n.significance,
        Nodes::TaskNode(t) => t.significance,
        Nodes::ContainerNode(c) => c.significance,
        _ => 0,
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

    let inode_id = TypedRecordId::new_v4(TableKind::INode);

    // Create initial nodes
    let inode = INode {
        id: inode_id,
        parent_container_id: None,
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
    };
    repo.create_node(Nodes::INode(inode.clone()))
        .await
        .expect("Failed to seed snapshot test node");

    // Verify snapshot query
    let snapshot = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch graph snapshot");
    let inodes: Vec<INode> = snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::INode(inode) => Some(inode.clone()),
        _ => None,
    }).collect();
    let tasks: Vec<TaskNode> = snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::TaskNode(tn) => Some(tn.clone()),
        _ => None,
    }).collect();
    let inters: Vec<InterNode> = snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::InterNode(in_) => Some(in_.clone()),
        _ => None,
    }).collect();
    let relations = snapshot.relations;
    let metadata = snapshot.metadata;
    assert_eq!(inodes.len(), 1);
    assert_eq!(inodes[0].id, inode_id);
    assert_eq!(tasks.len(), 0);
    assert_eq!(inters.len(), 0);
    assert_eq!(relations.len(), 0);
    assert_eq!(metadata.map_name, "Test Map");

    let new_inode_id = TypedRecordId::new_v4(TableKind::INode);
    let new_task_id = TypedRecordId::new_v4(TableKind::TaskNode);
    let new_inter_id = TypedRecordId::new_v4(TableKind::InterNode);
    let rel_id = TypedRecordId::new_v4(TableKind::IRelation);

    // Overwrite snapshot atomically with all entity types
    let new_inodes = vec![INode {
        id: new_inode_id,
        parent_container_id: None,
        content: inode.content.clone(),
        style: inode.style.clone(),
        resolved_style: inode.resolved_style.clone(),
        layout: inode.layout.clone(),
        resolved_layout: inode.resolved_layout.clone(),
        layer: inode.layer.clone(),
        position: inode.position.clone(),
        size: inode.size.clone(),
        line_count: inode.line_count,
        expandable: inode.expandable,
        is_expanded: inode.is_expanded,
        locked: inode.locked,
        tags: inode.tags.clone(),
        aliases: inode.aliases.clone(),
        comments: inode.comments.clone(),
        attachment: inode.attachment.clone(),
        significance: inode.significance,
        created_at: inode.created_at,
        updated_at: inode.updated_at,
    }];
    let new_tasks = vec![TaskNode {
        id: new_task_id,
        parent_container_id: None,
        content: Content::from_plain_text("Snapshot Task Node"),
        due_date: None,
        state: TaskState::Todo,
        position: Coordinates { x: 200, y: 200 },
        size: Size {
            width: 100,
            height: 50,
        },
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
    }];
    let new_inters = vec![InterNode {
        id: new_inter_id,
        parent_container_id: None,
        verb: "connects".to_string(),
        position: Coordinates { x: 300, y: 300 },
        layer: "default".to_string(),
        style: None,
        behavioral_features: None,
        created_at: 0,
        updated_at: 0,
    }];
    let new_relations = vec![IRelation {
        key: rel_id,
        in_: new_inode_id,
        out: new_task_id,
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
    }];

    let mut new_nodes = Vec::new();
    new_nodes.extend(new_inodes.into_iter().map(Nodes::INode));
    new_nodes.extend(new_tasks.into_iter().map(Nodes::TaskNode));
    new_nodes.extend(new_inters.into_iter().map(Nodes::InterNode));

    let new_snapshot = GraphSnapshot {
        nodes: new_nodes,
        relations: new_relations,
        metadata: MapData {
            map_name: "Overwritten Map".to_string(),
            viewport_state: centrode_core::domain::base_models::ViewportState {
                x_offset: 10.0,
                y_offset: 20.0,
                zoom_level: 1.5,
                active_view: "canvas".to_string(),
            },
            active_theme_id: None,
            display_mode: centrode_core::domain::base_models::DisplayMode::Importance,
            opt_area: None,
        },
    };

    repo.set_graph_snapshot(new_snapshot)
        .await
        .expect("Failed to set graph snapshot");

    // Verify overwritten snapshot
    let restored_snapshot = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch restored snapshot");
    let restored_inodes: Vec<INode> = restored_snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::INode(inode) => Some(inode.clone()),
        _ => None,
    }).collect();
    let restored_tasks: Vec<TaskNode> = restored_snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::TaskNode(tn) => Some(tn.clone()),
        _ => None,
    }).collect();
    let restored_inters: Vec<InterNode> = restored_snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::InterNode(in_) => Some(in_.clone()),
        _ => None,
    }).collect();
    let restored_relations = restored_snapshot.relations;
    let restored_metadata = restored_snapshot.metadata;

    assert_eq!(restored_inodes.len(), 1);
    assert_eq!(restored_inodes[0].id, new_inode_id);
    assert_eq!(restored_tasks.len(), 1);
    assert_eq!(restored_tasks[0].id, new_task_id);
    assert_eq!(restored_inters.len(), 1);
    assert_eq!(restored_inters[0].id, new_inter_id);
    assert_eq!(restored_relations.len(), 1);
    assert_eq!(restored_relations[0].key, rel_id);
    assert_eq!(restored_metadata.map_name, "Overwritten Map");

    // Ensure old INode was deleted during clear_graph
    let old_inode = repo
        .get_node(inode_id)
        .await
        .expect("Query failed");
    assert!(old_inode.is_none());
}

#[tokio::test]
async fn test_container_node_snapshot() {
    let repo = setup_test_repo().await;

    let container_id = TypedRecordId::new_v4(TableKind::ContainerNode);
    let container = crate::common::make_container_node(container_id, "Snapshot Container", 50, 50);

    // Create ContainerNode
    repo.create_node(Nodes::ContainerNode(container.clone()))
        .await
        .expect("Failed to create ContainerNode for snapshot test");

    // Verify snapshot includes ContainerNode
    let snapshot = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch graph snapshot");
    let containers: Vec<centrode_core::domain::nodes::ContainerNode> = snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::ContainerNode(c) => Some(c.clone()),
        _ => None,
    }).collect();
    assert_eq!(containers.len(), 1);
    assert_eq!(containers[0].id, container_id);
    assert_eq!(containers[0].title, "Snapshot Container");

    // Overwrite snapshot with ContainerNode
    let new_container_id = TypedRecordId::new_v4(TableKind::ContainerNode);
    let new_container = crate::common::make_container_node(new_container_id, "New Container", 100, 100);
    let new_nodes = vec![Nodes::ContainerNode(new_container)];
    let new_snapshot = GraphSnapshot {
        nodes: new_nodes,
        relations: vec![],
        metadata: centrode_core::domain::base_models::MapData {
            map_name: "Container Test Map".to_string(),
            viewport_state: centrode_core::domain::base_models::ViewportState {
                x_offset: 0.0,
                y_offset: 0.0,
                zoom_level: 1.0,
                active_view: "canvas".to_string(),
            },
            active_theme_id: None,
            display_mode: centrode_core::domain::base_models::DisplayMode::Importance,
            opt_area: None,
        },
    };

    repo.set_graph_snapshot(new_snapshot)
        .await
        .expect("Failed to set graph snapshot with ContainerNode");

    // Verify overwritten snapshot
    let restored_snapshot = repo
        .get_graph_snapshot()
        .await
        .expect("Failed to fetch restored snapshot");
    let restored_containers: Vec<centrode_core::domain::nodes::ContainerNode> = restored_snapshot.nodes.iter().filter_map(|n| match n {
        Nodes::ContainerNode(c) => Some(c.clone()),
        _ => None,
    }).collect();
    assert_eq!(restored_containers.len(), 1);
    assert_eq!(restored_containers[0].id, new_container_id);
    assert_eq!(restored_containers[0].title, "New Container");

    // Ensure old ContainerNode was deleted
    let old_container = repo
        .get_node(container_id)
        .await
        .expect("Query failed");
    assert!(old_container.is_none());
}

#[tokio::test]
async fn test_significance_calculation() {
    let repo = setup_test_repo().await;

    let center_id = TypedRecordId::new_v4(TableKind::INode);
    let n1_id = TypedRecordId::new_v4(TableKind::INode);

    let center_node = INode {
        id: center_id,
        parent_container_id: None,
        content: Content::from_plain_text("Center"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 0, y: 0 },
        size: Size { width: 10, height: 10 },
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
    };

    let node1 = INode {
        id: n1_id,
        parent_container_id: None,
        content: Content::from_plain_text("Neighbor 1"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 10, y: 10 },
        size: Size { width: 10, height: 10 },
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
    };

    repo.create_node(Nodes::INode(center_node)).await.unwrap();
    repo.create_node(Nodes::INode(node1)).await.unwrap();

    let rel1 = IRelation {
        key: TypedRecordId::new_v4(TableKind::IRelation),
        in_: center_id,
        out: n1_id,
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

    repo.create_relation(rel1).await.unwrap();

    assert_significance_eventually(&repo, "INode", &n1_id.key.to_string(), 0).await;
}

#[tokio::test]
async fn test_calculate_global_bounds() {
    let repo = setup_test_repo().await;

    let empty_bounds = repo.calculate_global_bounds().await.unwrap();
    assert_eq!(empty_bounds, BoundingBox::default());

    let inode = INode {
        id: TypedRecordId::new_v4(TableKind::INode),
        parent_container_id: None,
        content: Content::from_plain_text("N1"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: -100, y: 50 },
        size: Size { width: 10, height: 10 },
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
    };

    let tasknode = TaskNode {
        id: TypedRecordId::new_v4(TableKind::TaskNode),
        parent_container_id: None,
        content: Content::from_plain_text("N2"),
        due_date: None,
        state: TaskState::Todo,
        position: Coordinates { x: 300, y: -200 },
        size: Size { width: 10, height: 10 },
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

    repo.create_node(Nodes::INode(inode)).await.unwrap();
    repo.create_node(Nodes::TaskNode(tasknode)).await.unwrap();

    let bounds = repo.calculate_global_bounds().await.unwrap();
    assert_eq!(bounds.min_x, -100.0);
    assert_eq!(bounds.max_x, 310.0);
    assert_eq!(bounds.min_y, -200.0);
    assert_eq!(bounds.max_y, 60.0);
}
