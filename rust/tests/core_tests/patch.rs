use crate::common::setup_test_repo;
use mycelium_core::domain::base_models::{Coordinates, RecordStrings, Size};
use mycelium_core::domain::contents::Content;
use mycelium_core::domain::nodes::{INode, INodeFields, Nodes};
use mycelium_core::domain::patches::{EntityPatch, NodePatch, RelationPatch};
use mycelium_core::domain::relations::{IRelation, IRelationFields};
use mycelium_core::domain::styles::{NodeStyle, RelationLayout, RelationStyle};
use mycelium_core::persistence::history::HistoryManager;
use surrealdb::types::{RecordId, SurrealValue};

#[tokio::test]
async fn test_targeted_patch_and_history() {
    use mycelium_core::domain::patches::PatchHistoryPayload;

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
async fn test_remaining_patches() {
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
