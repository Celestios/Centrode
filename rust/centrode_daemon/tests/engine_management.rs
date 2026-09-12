use centrode_daemon::engine::EngineManager;
use tempfile::tempdir;

#[tokio::test]
async fn test_engine_manager_lifecycle() {
    let tmp = tempdir().expect("Failed to create tempdir");
    let storage_path = tmp.path().to_str().expect("Valid path");

    // 1. Initialize engine
    EngineManager::init(storage_path).await.expect("Failed to init engine");

    // 2. Get system DB
    let system_db = EngineManager::system_db().await.expect("Failed to get system DB");
    let _info = system_db
        .query("INFO FOR DB;")
        .await
        .expect("Query failed");

    // 3. Open map DB (initializes schema and seeds metadata)
    let map_db = EngineManager::open_map_db("map_test_1", "Test Map 1")
        .await
        .expect("Failed to open map DB");
    let _map_info = map_db
        .query("INFO FOR DB;")
        .await
        .expect("Query failed");

    // 4. Delete map DB
    EngineManager::delete_map_db("map_test_1").await.expect("Failed to delete map DB");

    // 5. Open and delete map DB with UUID
    let uuid_map_id = "1dd0ac04-5c56-498f-82a8-693b0c3ac9be";
    let _uuid_map_db = EngineManager::open_map_db(uuid_map_id, "Test UUID Map")
        .await
        .expect("Failed to open map DB with uuid");
    EngineManager::delete_map_db(uuid_map_id)
        .await
        .expect("Failed to delete map DB with uuid");

    // 6. Shutdown engine
    EngineManager::shutdown().await.expect("Failed to shutdown EngineManager");
}

