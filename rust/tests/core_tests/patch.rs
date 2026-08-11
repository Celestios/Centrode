use crate::common::setup_test_repo;
use centrode_core::domain::base_models::{Coordinates, Size};
use centrode_core::domain::contents::Content;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::{INode, Nodes};
use centrode_core::domain::patches::{EntityPatch, NodePatch, RelationPatch, SymmetricEntityPatch};
use centrode_core::domain::relations::{IRelation, IRelationFields};
use centrode_core::domain::styles::{NodeStyle, PortSide, RelationDirection, RelationLayout, RelationStyle};
use centrode_core::domain::traits::TableKind;
use centrode_core::persistence::history::HistoryManager;
use surrealdb::types::SurrealValue;

#[tokio::test]
async fn test_targeted_patch_and_history() {
    let repo = setup_test_repo().await;
    let history = HistoryManager::new(repo.db(), 5);

    let inode_id = TypedRecordId::new_v4(TableKind::INode);

    // 1. Create a node
    let inode = INode {
        id: inode_id,
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

    let record_id = inode_id.to_record_id();

    // 2. Prepare forward and reverse patches
    let forward_patch = EntityPatch::Node(vec![
        NodePatch::Position(Coordinates { x: 100, y: 200 }),
        NodePatch::IsExpanded(true),
        NodePatch::Style(Some(NodeStyle {
            bg_color: 0xFF0000,
            stroke_color: 0x000000,
            stroke_width: 1,
            font_family: "Roboto".to_string(),
            font_size: 14.0,
            shape: "rect".to_string(),
            width: 100,
            height: 50,
            text_color: 0xFFFFFF,
            border_radius: 4.0,
            padding: 8.0,
            shadow_color: 0x000000,
            shadow_blur: 2.0,
            shadow_spread: 0.0,
            shadow_offset_x: 0.0,
            shadow_offset_y: 0.0,
            strategy_type: "default".to_string(),
        })),
    ]);

    let reverse_patch = EntityPatch::Node(vec![
        NodePatch::Position(Coordinates { x: 10, y: 20 }),
        NodePatch::IsExpanded(false),
        NodePatch::Style(None),
    ]);

    // 3. Apply forward patch
    repo.patch_entity(record_id.clone(), &forward_patch)
        .await
        .unwrap();

    // Verify forward state
    let fetched = repo
        .get_node(inode_id)
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(ref n) = fetched {
        assert_eq!(n.position.x, 100);
        assert_eq!(n.position.y, 200);
        assert_eq!(n.is_expanded, true);
        assert!(n.style.is_some());
        assert_eq!(n.style.as_ref().unwrap().bg_color, 0xFF0000);
    } else {
        panic!("Incorrect node type");
    }

    // 4. Log to history
    let payload = SymmetricEntityPatch {
        id: inode_id,
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
    let target_id = payload_undone.id.to_record_id();
    repo.patch_entity(target_id, &payload_undone.reverse)
        .await
        .unwrap();

    // Verify undone state
    let fetched_undone = repo
        .get_node(inode_id)
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
    let target_id_redo = payload_redone.id.to_record_id();
    repo.patch_entity(target_id_redo, &payload_redone.forward)
        .await
        .unwrap();

    // Verify redone state
    let fetched_redone = repo
        .get_node(inode_id)
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(ref n) = fetched_redone {
        assert_eq!(n.position.x, 100);
        assert_eq!(n.position.y, 200);
        assert_eq!(n.is_expanded, true);
        assert!(n.style.is_some());
    } else {
        panic!("Incorrect node type");
    }
}

#[tokio::test]
async fn test_relation_patching() {
    let repo = setup_test_repo().await;

    let in_id = TypedRecordId::new_v4(TableKind::INode);
    let out_id = TypedRecordId::new_v4(TableKind::INode);

    let n1 = INode {
        id: in_id,
        content: Content::from_plain_text("N1"),
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
    let n2 = INode {
        id: out_id,
        content: Content::from_plain_text("N2"),
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
    repo.create_node(Nodes::INode(n1)).await.unwrap();
    repo.create_node(Nodes::INode(n2)).await.unwrap();

    let rel_id = TypedRecordId::new_v4(TableKind::IRelation);

    let rel = IRelation {
        key: rel_id,
        in_: in_id,
        out: out_id,
        fields: IRelationFields {
            verb: "initial_verb".to_string(),
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
    repo.create_relation(rel).await.unwrap();

    let record_id = rel_id.to_record_id();

    // 1. Patch verb and style
    let patch = EntityPatch::Relation(vec![
        RelationPatch::Verb("patched_verb".to_string()),
        RelationPatch::Style(Some(RelationStyle {
            bg_color: 0x000000,
            stroke_color: 0x0000FF,
            stroke_width: 2,
            font_family: "Roboto".to_string(),
            font_size: 12.0,
            shape: "line".to_string(),
            arrow_type: "arrow".to_string(),
            arrow_size: 6.0,
            start_shape: None,
            end_shape: None,
            width: 0,
            height: 0,
            text_color: 0xFFFFFF,
            shadow_color: 0x000000,
            shadow_blur: 0.0,
            shadow_offset_x: 0.0,
            shadow_offset_y: 0.0,
            strategy_type: "default".to_string(),
            stroke_pattern: "solid".to_string(),
            body_strategy: "direct".to_string(),
        })),
        RelationPatch::Layout(Some(RelationLayout {
            strategy_type: "orthogonal".to_string(),
            from_side: Some(PortSide::Right),
            to_side: Some(PortSide::Left),
            control_point_1: None,
            control_point_2: None,
        })),
        RelationPatch::Direction(RelationDirection::Undirected),
    ]);

    repo.patch_entity(record_id.clone(), &patch)
        .await
        .unwrap();

    let fetched = repo
        .get_relation(rel_id)
        .await
        .unwrap();
    assert_eq!(fetched.fields.verb, "patched_verb");
    assert!(fetched.fields.style.is_some());
    assert_eq!(
        fetched.fields.style.as_ref().unwrap().stroke_color,
        0x0000FF
    );
    assert_eq!(
        fetched.fields.style.as_ref().unwrap().stroke_width,
        2
    );
    assert!(fetched.fields.layout.is_some());
    assert_eq!(
        fetched.fields.layout.as_ref().unwrap().from_side,
        Some(PortSide::Right)
    );
    assert_eq!(
        fetched.fields.layout.as_ref().unwrap().to_side,
        Some(PortSide::Left)
    );
    assert_eq!(fetched.fields.direction, RelationDirection::Undirected);
}

#[tokio::test]
async fn test_create_and_delete_entity_patches() {
    let repo = setup_test_repo().await;

    let in_id = TypedRecordId::new_v4(TableKind::INode);
    let out_id = TypedRecordId::new_v4(TableKind::INode);

    let n1 = INode {
        id: in_id,
        content: Content::from_plain_text("A"),
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

    let rel_id = TypedRecordId::new_v4(TableKind::IRelation);

    let rel = IRelation {
        key: rel_id,
        in_: in_id,
        out: out_id,
        fields: IRelationFields {
            verb: "link".to_string(),
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

    // 1. Create node and relations via CreateNode patch
    let create_patch = EntityPatch::CreateNode(Nodes::INode(n1.clone()), vec![rel.clone()]);
    repo.patch_entity(n1.id.to_record_id(), &create_patch)
        .await
        .unwrap();

    // Verify node and relation were created
    assert!(repo
        .get_node(in_id)
        .await
        .unwrap()
        .is_some());
    assert!(repo
        .get_relation(rel_id)
        .await
        .is_ok());

    // 2. Delete relation via DeleteRelation patch
    let delete_rel_patch = EntityPatch::DeleteRelation(rel.clone());
    repo.patch_entity(rel_id.to_record_id(), &delete_rel_patch)
        .await
        .unwrap();
    assert!(repo
        .get_relation(rel_id)
        .await
        .is_err());

    // 3. Create relation via CreateRelation patch
    let create_rel_patch = EntityPatch::CreateRelation(rel.clone());
    repo.patch_entity(rel_id.to_record_id(), &create_rel_patch)
        .await
        .unwrap();
    assert!(repo
        .get_relation(rel_id)
        .await
        .is_ok());

    // 4. Delete node via DeleteNode patch
    let delete_node_patch = EntityPatch::DeleteNode(Nodes::INode(n1.clone()), vec![]);
    repo.patch_entity(n1.id.to_record_id(), &delete_node_patch)
        .await
        .unwrap();
    assert!(repo
        .get_node(in_id)
        .await
        .unwrap()
        .is_none());
}
