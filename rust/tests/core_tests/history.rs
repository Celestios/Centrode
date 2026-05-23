use crate::common::setup_test_repo;
use mycelium_core::persistence::history::HistoryManager;
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, SurrealValue)]
struct TestPayload {
    key: String,
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
