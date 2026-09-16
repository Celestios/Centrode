use centrode_daemon::engine::EngineManager;
use tempfile::tempdir;

#[tokio::test]
async fn test_engine_manager_lifecycle() {
    let tmp = tempdir().expect("Failed to create tempdir");
    let storage_path = tmp.path().to_str().expect("Valid path");

    // Pre-condition: not initialized
    assert!(!EngineManager::is_initialized());

    // 1. Initialize engine
    EngineManager::init(storage_path).await.expect("Failed to init engine");
    assert!(EngineManager::is_initialized());

    // 2. Get system DB and assert return results from queries
    let system_db = EngineManager::system_db().await.expect("Failed to get system DB");
    let mut res = system_db
        .query("count(SELECT id FROM IRelation);")
        .await
        .expect("Query failed");
    let count: Option<i64> = res.take(0).expect("Take count failed");
    assert!(count.unwrap_or(0) > 0, "Expected system relations to be seeded");

    // 3. Open map DB (initializes schema and seeds metadata)
    let map_db = EngineManager::open_map_db("map_test_1", "Test Map 1")
        .await
        .expect("Failed to open map DB");
    let mut map_res = map_db
        .query("SELECT * FROM MapData;")
        .await
        .expect("Query MapData failed");
    let map_data: Vec<surrealdb::types::Value> = map_res.take(0).expect("Take MapData failed");
    assert_eq!(map_data.len(), 1);

    // 4. Delete map DB and verify it is removed
    let del_res = EngineManager::delete_map_db("map_test_1").await;
    assert!(del_res.is_ok());

    let root = EngineManager::root_db().await.expect("Failed to get root DB");
    root.use_ns("centrode").await.expect("Failed to use NS");
    let mut ns_info = root.query("INFO FOR NS;").await.expect("INFO FOR NS query failed");
    let val: surrealdb::types::Value = ns_info.take(0).expect("Failed to get NS info");
    if let surrealdb::types::Value::Object(map) = val {
        if let Some(surrealdb::types::Value::Object(dbs)) = map.get("databases") {
            assert!(!dbs.contains_key("map_test_1"), "Database map_test_1 should be removed");
        }
    }

    // Protected system database cannot be deleted
    let prot_res = EngineManager::delete_map_db("system").await;
    assert!(prot_res.is_err());

    // 5. Open and delete map DB with UUID
    let uuid_map_id = "1dd0ac04-5c56-498f-82a8-693b0c3ac9be";
    let _uuid_map_db = EngineManager::open_map_db(uuid_map_id, "Test UUID Map")
        .await
        .expect("Failed to open map DB with uuid");
    let uuid_del_res = EngineManager::delete_map_db(uuid_map_id).await;
    assert!(uuid_del_res.is_ok());

    // 6. Shutdown engine and assert is_initialized resets to false
    EngineManager::shutdown().await.expect("Failed to shutdown EngineManager");
    assert!(!EngineManager::is_initialized());
}

