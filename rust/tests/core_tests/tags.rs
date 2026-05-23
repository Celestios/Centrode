use crate::common::setup_test_repo;
use mycelium_core::domain::base_models::{Coordinates, Size};
use mycelium_core::domain::contents::Content;
use mycelium_core::domain::nodes::{INode, INodeFields, Nodes};
use mycelium_core::domain::patches::{EntityPatch, NodePatch, TagOperation};
use mycelium_core::domain::tags::{Tag, TagEdge};
use surrealdb::types::RecordId;

#[tokio::test]
async fn test_tags_crud_and_patching() {
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
