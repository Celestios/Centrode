use centrode_daemon::engine::EngineManager;
use centrode_daemon::services::DaemonService;
use surrealdb::engine::local::SurrealKv;
use surrealdb::Surreal;
use tempfile::tempdir;

#[tokio::test]
async fn test_daemon_service_map_lifecycle() {
    let tmp = tempdir().expect("Failed to create tempdir");
    let storage_path = tmp.path().to_str().expect("Valid path");

    EngineManager::init(storage_path).await.expect("Failed to init EngineManager");
    let db = EngineManager::system_db().await.expect("Failed to get system DB");

    let service = DaemonService::with_db(db).await.expect("Failed to create DaemonService");

    // 1. Create a map
    let map = service.create_map("Project Alpha").await.expect("Failed to create map");
    assert_eq!(map.name, "Project Alpha");
    let map_id = map.id.clone();

    // Seed a node and a self-link relation into the source map DB
    let src_db = EngineManager::open_map_db(&map_id, "Project Alpha")
        .await
        .expect("Failed to open source map DB");
    src_db
        .query(
            "CREATE INode:node1 SET \
                layer = 'default', \
                position = { x: 10, y: 20 }, \
                size = { width: 100, height: 50 }, \
                content = { text: 'Node 1', blocks: [] }, \
                line_count = 1, \
                expandable = true, \
                is_expanded = false, \
                locked = false, \
                tags = [], \
                aliases = [], \
                comments = [], \
                attachments = [], \
                significance = 0;"
        )
        .await
        .expect("Query dispatch failed")
        .check()
        .expect("Insert node failed");
    src_db
        .query(
            "RELATE INode:node1 -> IRelation:rel1 -> INode:node1 SET \
                verb = 'self_link', \
                direction = 0, \
                layer = 'default', \
                created_at = 0;"
        )
        .await
        .expect("Query dispatch failed")
        .check()
        .expect("Insert relation failed");

    // 2. List maps
    let maps = service.list_maps().await.expect("Failed to list maps");
    assert!(maps.iter().any(|m| m.id == map_id));

    // 3. Rename map
    let renamed = service.rename_map(&map_id, "Project Omega").await.expect("Failed to rename map");
    assert_eq!(renamed.name, "Project Omega");

    // 4. Duplicate map (executes branch where EngineManager::is_initialized() is true)
    let duplicate = service.duplicate_map(&map_id, "Project Omega Copy").await.expect("Failed to duplicate map");
    assert_eq!(duplicate.name, "Project Omega Copy");
    assert_ne!(duplicate.id, map_id);

    // Verify duplicated map contains cloned nodes and relations from source map
    let dst_db = EngineManager::map_db(&duplicate.id).await.expect("Failed to get duplicate map DB");
    let mut res_nodes = dst_db
        .query("SELECT * FROM INode;")
        .await
        .expect("Query nodes failed");
    let nodes: Vec<serde_json::Value> = res_nodes.take(0).expect("Take nodes failed");
    assert_eq!(nodes.len(), 1, "Duplicate should contain cloned INode");

    let mut res_rels = dst_db
        .query("SELECT * FROM IRelation;")
        .await
        .expect("Query rels failed");
    let rels: Vec<serde_json::Value> = res_rels.take(0).expect("Take rels failed");
    assert_eq!(rels.len(), 1, "Duplicate should contain cloned IRelation");

    // 5. Touch map
    service.touch_map(&map_id).await.expect("Failed to touch map");

    // 6. Delete maps
    service.delete_map(&map_id).await.expect("Failed to delete map");
    service.delete_map(&duplicate.id).await.expect("Failed to delete duplicate map");

    let remaining = service.list_maps().await.expect("Failed to list maps after deletion");
    assert!(!remaining.iter().any(|m| m.id == map_id || m.id == duplicate.id));

    EngineManager::shutdown().await.expect("Failed to shutdown EngineManager");
}

#[tokio::test]
async fn test_daemon_service_settings() {
    let tmp = tempdir().expect("Failed to create tempdir");
    let db = Surreal::new::<SurrealKv>(tmp.path()).await.expect("Failed to init SurrealKV");
    db.use_ns("centrode").use_db("system").await.expect("Failed to use system db");

    let service = DaemonService::with_db(db).await.expect("Failed to create DaemonService");

    // 1. Set setting
    service.set_setting("theme", "midnight_dark").await.expect("Failed to set setting");

    // 2. Get setting
    let val = service.get_setting("theme").await.expect("Failed to get setting");
    assert_eq!(val.as_deref(), Some("midnight_dark"));

    // 3. Delete setting
    service.delete_setting("theme").await.expect("Failed to delete setting");
    let val_after = service.get_setting("theme").await.expect("Failed to get deleted setting");
    assert_eq!(val_after, None);
}
