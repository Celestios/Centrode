use crate::common::setup_test_repo;
use centrode_core::domain::base_models::Coordinates;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::nodes::Nodes;
use centrode_core::domain::patches::{EntityPatch, NodePatch, SymmetricEntityPatch};
use centrode_core::domain::traits::TableKind;
use centrode_core::repo::history::HistoryManager;
use centrode_core::repo::traits::{HistoryRepository, NodeRepository};
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, SurrealValue)]
struct TestPayload {
    key: String,
}

#[tokio::test]
async fn test_history_manager() {
    let repo = setup_test_repo().await;

    // Use a strict threshold of 3 for testing
    let history = HistoryManager::new(repo.history.db(), 3);

    // Clear history to start fresh
    let _: Vec<surrealdb::types::Value> = repo
        .history
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
        .history
        .db()
        .query("SELECT VALUE count() FROM History WHERE status = 0 GROUP ALL")
        .await
        .unwrap();
    let count_vec: Vec<i64> = count_response.take(0).unwrap();
    let count = count_vec.first().copied().unwrap_or(0);
    assert_eq!(count, 3);

    // Undo cycle
    let undone = history.undo().await.unwrap();
    assert!(undone.is_some());
    let undone_rec = undone.unwrap();
    assert_eq!(undone_rec.action_type, "add_node");

    let payload_val = TestPayload::from_value(undone_rec.payload).unwrap();
    assert_eq!(payload_val.key, "node_5");

    // Verify non-zero undone count query returns successfully
    let mut undone_count_response = repo
        .history
        .db()
        .query("SELECT VALUE count() FROM History WHERE status = 1 GROUP ALL")
        .await
        .unwrap();
    let undone_count_vec: Vec<i64> = undone_count_response.take(0).unwrap();
    let undone_count = undone_count_vec.first().copied().unwrap_or(0);
    assert_eq!(undone_count, 1);

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
        .history
        .db()
        .query("SELECT VALUE count() FROM History WHERE status = 1 GROUP ALL")
        .await
        .unwrap();
    let undone_count_vec: Vec<i64> = undone_query.take(0).unwrap();
    let undone_count = undone_count_vec.first().copied().unwrap_or(0);
    assert_eq!(undone_count, 0);
}

#[tokio::test]
async fn test_history_lifo_undo_redo_sequence() {
    let repo = setup_test_repo().await;
    let history = HistoryManager::new(repo.history.db(), 10);

    let _: Vec<surrealdb::types::Value> = repo
        .history
        .db()
        .query("DELETE History")
        .await
        .unwrap()
        .take(0)
        .unwrap();

    // Push A at t=1000, B at t=2000, C at t=3000
    history
        .push_event_with_time("event", TestPayload { key: "A".to_string() }.into_value(), 1000)
        .await
        .unwrap();
    history
        .push_event_with_time("event", TestPayload { key: "B".to_string() }.into_value(), 2000)
        .await
        .unwrap();
    history
        .push_event_with_time("event", TestPayload { key: "C".to_string() }.into_value(), 3000)
        .await
        .unwrap();

    // Undo C
    let u1 = history.undo().await.unwrap().unwrap();
    assert_eq!(TestPayload::from_value(u1.payload).unwrap().key, "C");

    // Undo B
    let u2 = history.undo().await.unwrap().unwrap();
    assert_eq!(TestPayload::from_value(u2.payload).unwrap().key, "B");

    // Redo should restore B first (the last one undone)
    let r1 = history.redo().await.unwrap().unwrap();
    assert_eq!(TestPayload::from_value(r1.payload).unwrap().key, "B");

    // Redo should restore C second
    let r2 = history.redo().await.unwrap().unwrap();
    assert_eq!(TestPayload::from_value(r2.payload).unwrap().key, "C");

    // No more redos
    let r3 = history.redo().await.unwrap();
    assert!(r3.is_none());
}

#[tokio::test]
async fn test_history_repository_patch_undo_redo() {
    let repo = setup_test_repo().await;

    let inode_id = TypedRecordId::new_v4(TableKind::INode);
    let inode = crate::common::make_inode(inode_id, "History Trait Node", 10, 20);
    repo.nodes.create_node(Nodes::INode(inode)).await.unwrap();

    let forward_patch = EntityPatch::Node(vec![
        NodePatch::Position(Coordinates { x: 150, y: 250 }),
    ]);
    let reverse_patch = EntityPatch::Node(vec![
        NodePatch::Position(Coordinates { x: 10, y: 20 }),
    ]);

    // 1. Apply forward patch
    repo.nodes
        .patch_entity(inode_id.to_record_id(), &forward_patch)
        .await
        .unwrap();

    // 2. Record patch history using HistoryRepository trait
    repo.history
        .record_patch_history(inode_id, forward_patch, reverse_patch)
        .await
        .unwrap();

    assert_eq!(repo.history.undo_count().await.unwrap(), 1);
    assert_eq!(repo.history.redo_count().await.unwrap(), 0);

    // Verify forward state
    let fetched = repo.nodes.get_node(inode_id).await.unwrap().unwrap();
    if let Nodes::INode(n) = fetched {
        assert_eq!(n.position.x, 150);
        assert_eq!(n.position.y, 250);
    } else {
        panic!("Wrong node variant");
    }

    // 3. Undo event via HistoryRepository
    let undone = repo.history.undo_event().await.unwrap();
    assert!(undone.is_some());
    let undone_rec = undone.unwrap();
    assert_eq!(undone_rec.action_type, "entity_patch");

    let patch_payload = SymmetricEntityPatch::from_value(undone_rec.payload).unwrap();
    assert_eq!(patch_payload.id, inode_id);
    // Apply reverse patch to DB
    repo.nodes
        .patch_entity(patch_payload.id.to_record_id(), &patch_payload.reverse)
        .await
        .unwrap();

    // Verify undone state
    let fetched_undone = repo.nodes.get_node(inode_id).await.unwrap().unwrap();
    if let Nodes::INode(n) = fetched_undone {
        assert_eq!(n.position.x, 10);
        assert_eq!(n.position.y, 20);
    } else {
        panic!("Wrong node variant");
    }

    assert_eq!(repo.history.undo_count().await.unwrap(), 0);
    assert_eq!(repo.history.redo_count().await.unwrap(), 1);

    // 4. Redo event via HistoryRepository
    let redone = repo.history.redo_event().await.unwrap();
    assert!(redone.is_some());
    let redone_rec = redone.unwrap();
    assert_eq!(redone_rec.action_type, "entity_patch");

    let redo_payload = SymmetricEntityPatch::from_value(redone_rec.payload).unwrap();
    assert_eq!(redo_payload.id, inode_id);
    // Apply forward patch to DB
    repo.nodes
        .patch_entity(redo_payload.id.to_record_id(), &redo_payload.forward)
        .await
        .unwrap();

    // Verify redone state
    let fetched_redone = repo.nodes.get_node(inode_id).await.unwrap().unwrap();
    if let Nodes::INode(n) = fetched_redone {
        assert_eq!(n.position.x, 150);
        assert_eq!(n.position.y, 250);
    } else {
        panic!("Wrong node variant");
    }

    assert_eq!(repo.history.undo_count().await.unwrap(), 1);
    assert_eq!(repo.history.redo_count().await.unwrap(), 0);
}
