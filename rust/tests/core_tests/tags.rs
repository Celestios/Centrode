use crate::common::setup_test_repo;
use centrode_core::domain::base_models::{Coordinates, Size};
use centrode_core::domain::contents::Content;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::{INode, Nodes};
use centrode_core::domain::patches::{EntityPatch, NodePatch, TagOperation};
use centrode_core::domain::tags::{Tag, TagEdge, TagFields};
use centrode_core::domain::traits::TableKind;

#[tokio::test]
async fn test_tags_crud_and_patching() {
    let repo = setup_test_repo().await;

    let tag_id = TypedRecordId::new_v4(TableKind::Tag);

    // 1. Create a tag
    let tag = Tag {
        key: tag_id,
        fields: TagFields {
            name: "test_tag_rust".to_string(),
            color: 0xFF00FF,
            created_at: 100,
            updated_at: 100,
        },
    };
    repo.create_tag(tag.clone())
        .await
        .expect("Failed to create tag");

    // 2. Read the tag back
    let fetched_tag = repo
        .get_tag(tag_id.key.to_string())
        .await
        .expect("Failed to get tag");
    assert!(fetched_tag.is_some());
    let fetched_tag = fetched_tag.unwrap();
    assert_eq!(fetched_tag.key, tag_id);
    assert_eq!(fetched_tag.fields.name, "test_tag_rust");
    assert_eq!(fetched_tag.fields.color, 0xFF00FF);

    // 3. List all tags
    let all_tags = repo.get_all_tags().await.expect("Failed to get all tags");
    assert!(all_tags
        .iter()
        .any(|t| t.key == tag_id && t.fields.name == "test_tag_rust" && t.fields.color == 0xFF00FF));

    let inode_id = TypedRecordId::new_v4(TableKind::INode);

    // 4. Create an INode
    let inode = INode {
        id: inode_id,
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
    };
    repo.create_node(Nodes::INode(inode)).await.unwrap();

    let record_id = inode_id.to_record_id();

    // 5. Add tag to the INode using patch
    let add_patch = EntityPatch::Node(vec![NodePatch::TagOp(TagOperation::Add(tag_id))]);
    repo.patch_entity(record_id.clone(), &add_patch)
        .await
        .unwrap();

    // 6. Retrieve INode and verify tag is added & hydrated
    let fetched_node = repo
        .get_node(inode_id)
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched_node {
        assert_eq!(n.tags.len(), 1);
        match &n.tags[0] {
            TagEdge::Hydrated(t) => {
                assert_eq!(t.key, tag_id);
                assert_eq!(t.fields.name, "test_tag_rust");
                assert_eq!(t.fields.color, 0xFF00FF);
            }
            TagEdge::Pointer(p) => {
                panic!("Expected tag to be hydrated but got pointer: {:?}", p);
            }
            _ => panic!("Unexpected TagEdge variant"),
        }
    } else {
        panic!("Incorrect node type");
    }

    // 7. Remove tag from the INode using patch
    let remove_patch = EntityPatch::Node(vec![NodePatch::TagOp(TagOperation::Remove(tag_id))]);
    repo.patch_entity(record_id.clone(), &remove_patch)
        .await
        .unwrap();

    // 8. Retrieve INode and verify tag is removed
    let fetched_node_after_remove = repo
        .get_node(inode_id)
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched_node_after_remove {
        assert_eq!(n.tags.len(), 0);
    } else {
        panic!("Incorrect node type");
    }

    // 9. Cascading tag deletion test
    let tag2_id = TypedRecordId::new_v4(TableKind::Tag);
    let tag2 = Tag {
        key: tag2_id,
        fields: TagFields {
            name: "work".to_string(),
            color: 0x00FF00,
            created_at: 100,
            updated_at: 100,
        },
    };
    repo.create_tag(tag2.clone()).await.unwrap();

    let inode2_id = TypedRecordId::new_v4(TableKind::INode);
    let inode2 = INode {
        id: inode2_id,
        content: Content::from_plain_text("Node to be tagged"),
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
        attachment: None,
        significance: 0,
        created_at: 0,
        updated_at: 0,
    };
    repo.create_node(Nodes::INode(inode2)).await.unwrap();

    let add_patch = EntityPatch::Node(vec![NodePatch::TagOp(TagOperation::Add(tag2_id))]);
    repo.patch_entity(inode2_id.to_record_id(), &add_patch)
        .await
        .unwrap();

    // Delete tag2
    repo.delete_tag(tag2_id.key.to_string()).await.unwrap();

    // Verify tag2 is deleted from Repository
    let fetched_tag2 = repo.get_tag(tag2_id.key.to_string()).await.unwrap();
    assert!(fetched_tag2.is_none());

    // Verify tag2 is removed from INode's tags array
    let fetched_node2 = repo
        .get_node(inode2_id)
        .await
        .unwrap()
        .unwrap();
    if let Nodes::INode(n) = fetched_node2 {
        assert_eq!(n.tags.len(), 0);
    } else {
        panic!("Incorrect node type");
    }
}
