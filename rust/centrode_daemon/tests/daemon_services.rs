use centrode_daemon::services::DaemonService;
use surrealdb::engine::local::SurrealKv;
use surrealdb::Surreal;
use tempfile::tempdir;

#[tokio::test]
async fn test_daemon_service_map_lifecycle() {
    let tmp = tempdir().expect("Failed to create tempdir");
    let db = Surreal::new::<SurrealKv>(tmp.path()).await.expect("Failed to init SurrealKV");
    db.use_ns("centrode").use_db("system").await.expect("Failed to use system db");

    let service = DaemonService::with_db(db).await.expect("Failed to create DaemonService");

    // 1. Create a map
    let map = service.create_map("Project Alpha").await.expect("Failed to create map");
    assert_eq!(map.name, "Project Alpha");
    let map_id = map.id.clone();

    // 2. List maps
    let maps = service.list_maps().await.expect("Failed to list maps");
    assert!(maps.iter().any(|m| m.id == map_id));

    // 3. Rename map
    let renamed = service.rename_map(&map_id, "Project Omega").await.expect("Failed to rename map");
    assert_eq!(renamed.name, "Project Omega");

    // 4. Duplicate map
    let duplicate = service.duplicate_map(&map_id, "Project Omega Copy").await.expect("Failed to duplicate map");
    assert_eq!(duplicate.name, "Project Omega Copy");
    assert_ne!(duplicate.id, map_id);

    // 5. Touch map
    service.touch_map(&map_id).await.expect("Failed to touch map");

    // 6. Delete maps
    service.delete_map(&map_id).await.expect("Failed to delete map");
    service.delete_map(&duplicate.id).await.expect("Failed to delete duplicate map");

    let remaining = service.list_maps().await.expect("Failed to list maps after deletion");
    assert!(!remaining.iter().any(|m| m.id == map_id || m.id == duplicate.id));
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
