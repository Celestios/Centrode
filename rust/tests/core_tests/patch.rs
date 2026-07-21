use crate::common::setup_test_repo;
use rust_lib_mycelium::domain::base_models::{Coordinates, RecordStrings, Size};
use rust_lib_mycelium::domain::contents::Content;
use rust_lib_mycelium::domain::nodes::{INode, Nodes};
use rust_lib_mycelium::domain::patches::{EntityPatch, NodePatch, RelationPatch};
use rust_lib_mycelium::domain::relations::{IRelation, IRelationFields};
use rust_lib_mycelium::domain::styles::{NodeStyle, PortSide, RelationLayout, RelationStyle};
use rust_lib_mycelium::persistence::history::HistoryManager;
use surrealdb::types::{RecordId, SurrealValue};

#[tokio::test]
async fn test_targeted_patch_and_history() {
    use rust_lib_mycelium::domain::patches::SymmetricEntityPatch;

    let repo = setup_test_repo().await;
    let history = HistoryManager::new(repo.db(), 5);

    // 1. Create a node
    let inode = INode {
        id: RecordStrings {
            table: "INode".to_string(),
            key: "inode_patch_test".to_string(),
        },
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
        assert_eq!(n.position.x, 50);
        assert_eq!(n.position.y, 60);
        assert_eq!(n.is_expanded, true);
    } else {
        panic!("Incorrect node type");
    }

    // 4. Log to history
    let payload = SymmetricEntityPatch {
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

    let payload_undone = SymmetricEntityPatch::from_value(rec_undone.payload).unwrap();
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
        assert_eq!(n.position.x, 10);
        assert_eq!(n.position.y, 20);
        assert_eq!(n.is_expanded, false);
    } else {
        panic!("Incorrect node type");
    }

    // 6. Redo
    let redone = history.redo().await.unwrap();
    assert!(redone.is_some());
    let rec_redone = redone.unwrap();
    assert_eq!(rec_redone.action_type, "entity_patch");

    let payload_redone = SymmetricEntityPatch::from_value(rec_redone.payload).unwrap();
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
        assert_eq!(n.position.x, 50);
        assert_eq!(n.position.y, 60);
        assert_eq!(n.is_expanded, true);
    } else {
        panic!("Incorrect node type");
    }
}

#[tokio::test]
async fn test_remaining_patches() {
    let repo = setup_test_repo().await;

    let inode = INode {
        id: RecordStrings {
            table: "INode".to_string(),
            key: "n_patch".to_string(),
        },
        content: Content::from_plain_text("original"),
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
    };
    repo.create_node(Nodes::INode(inode)).await.unwrap();
    let node_id = RecordId::new("INode", "n_patch");

    let style = NodeStyle {
        bg_color: 0x123456,
        stroke_color: 0x789abc,
        stroke_width: 2,
        font_family: "Arial".to_string(),
        font_size: 14.0,
        shape: "circle".to_string(),
        width: 15,
        height: 15,
        text_color: 0xffffff,
        border_radius: 4.0,
        padding: 8.0,
        shadow_color: 0,
        shadow_blur: 0.0,
        shadow_spread: 0.0,
        shadow_offset_x: 0.0,
        shadow_offset_y: 0.0,
        strategy_type: "default".to_string(),
    };
    let content = Content::from_plain_text("patched content");

    let patch = EntityPatch::Node(vec![
        NodePatch::Size(Size {
            width: 42,
            height: 42,
        }),
        NodePatch::Content(content.clone()),
        NodePatch::Style(Some(style.clone())),
        NodePatch::Significance(3),
    ]);

    repo.patch_entity(node_id.clone(), &patch).await.unwrap();

    let fetched = repo
        .get_node("INode".to_string(), "n_patch".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched {
        assert_eq!(n.size.width, 42);
        assert_eq!(n.size.height, 42);
        assert_eq!(n.content.text, "patched content");
        assert_eq!(n.style.as_ref().unwrap().bg_color, 0x123456);
        assert_eq!(n.significance, 3);
    } else {
        panic!("Not an INode");
    }

    let target = INode {
        id: RecordStrings {
            table: "INode".to_string(),
            key: "n_patch_target".to_string(),
        },
        content: Content::from_plain_text("target"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 50, y: 50 },
        size: Size {
            width: 10,
            height: 10,
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
    };
    repo.create_node(Nodes::INode(target)).await.unwrap();

    let rel = IRelation {
        key: "r_patch".to_string(),
        in_: "INode:n_patch".into(),
        out: "INode:n_patch_target".into(),
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
    repo.create_relation(rel).await.unwrap();
    let rel_id = RecordId::new("IRelation", "r_patch");

    let rel_style = RelationStyle {
        bg_color: 0x111111,
        stroke_color: 0x222222,
        stroke_width: 1,
        font_family: "Sans".to_string(),
        font_size: 10.0,
        shape: "line".to_string(),
        arrow_type: "arrow".to_string(),
        arrow_size: 5.0,
        start_shape: None,
        end_shape: None,
        width: 0,
        height: 0,
        text_color: 0x333333,
        shadow_color: 0,
        shadow_blur: 0.0,
        shadow_offset_x: 0.0,
        shadow_offset_y: 0.0,
        strategy_type: "default".to_string(),
        stroke_pattern: "solid".to_string(),
        body_strategy: "none".to_string(),
    };
    let rel_layout = RelationLayout {
        from_side: Some(PortSide::Right),
        to_side: Some(PortSide::Left),
        strategy_type: "custom".to_string(),
        control_point_1: None,
        control_point_2: None,
    };

    let rel_patch = EntityPatch::Relation(vec![
        RelationPatch::Verb("patched_verb".to_string()),
        RelationPatch::Style(Some(rel_style.clone())),
        RelationPatch::Layout(Some(rel_layout.clone())),
        RelationPatch::Directionless(true),
    ]);

    repo.patch_entity(rel_id, &rel_patch).await.unwrap();

    let fetched_rel = repo
        .get_relation("IRelation".to_string(), "r_patch".to_string())
        .await
        .unwrap();
    assert_eq!(fetched_rel.fields.verb, "patched_verb");
    assert_eq!(
        fetched_rel.fields.style.as_ref().unwrap().stroke_color,
        0x222222
    );
    assert_eq!(
        fetched_rel.fields.layout.as_ref().unwrap().from_side,
        Some(PortSide::Right)
    );
    assert_eq!(fetched_rel.fields.directionless, true);
}

#[tokio::test]
async fn test_undo_redo_update_node_via_createnode_patch() {
    let repo = setup_test_repo().await;

    let inode = INode {
        id: RecordStrings {
            table: "INode".to_string(),
            key: "inode_upsert_test".to_string(),
        },
        content: Content::from_plain_text("Original content"),
        style: None,
        resolved_style: None,
        layout: None,
        resolved_layout: None,
        layer: "default".to_string(),
        position: Coordinates { x: 100, y: 100 },
        size: Size {
            width: 50,
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
    repo.create_node(Nodes::INode(inode.clone())).await.unwrap();

    let record_id = RecordId::new("INode", "inode_upsert_test");

    // 1. Re-create (upsert) node with updated fields
    let mut updated = inode.clone();
    updated.content = Content::from_plain_text("Updated content");
    updated.position.x = 200;

    // Apply the CreateNode patch to an EXISTING record (mimics update undo/redo)
    let patch = EntityPatch::CreateNode(Nodes::INode(updated.clone()), vec![]);
    repo.patch_entity(record_id.clone(), &patch).await.unwrap();

    // Verify it was successfully upserted
    let fetched = repo
        .get_node("INode".to_string(), "inode_upsert_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched {
        assert_eq!(n.content.text, "Updated content");
        assert_eq!(n.position.x, 200);
    } else {
        panic!("Incorrect node type");
    }

    // 2. Revert using the reverse CreateNode patch of the original node
    let patch_reverse = EntityPatch::CreateNode(Nodes::INode(inode), vec![]);
    repo.patch_entity(record_id, &patch_reverse).await.unwrap();

    // Verify it was successfully reverted
    let fetched_reverted = repo
        .get_node("INode".to_string(), "inode_upsert_test".to_string())
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched_reverted {
        assert_eq!(n.content.text, "Original content");
        assert_eq!(n.position.x, 100);
    } else {
        panic!("Incorrect node type");
    }
}

