use crate::common::setup_test_repo;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::theme::{FontWeight, MapTheme, ThemeFields};
use centrode_core::domain::traits::TableKind;
use centrode_core::repo::traits::{SnapshotRepository, ThemeRepository};

#[tokio::test]
async fn test_theme_crud_and_active_theme() {
    let repo = setup_test_repo().await;

    let theme_fields = ThemeFields {
        name: "My Dark Theme".to_string(),
        primary_color: 0x112233,
        secondary_color: 0x445566,
        tertiary_color: 0x556677,
        accent_color: 0x778899,
        canvas_accent_color: 0x2196F3,
        font_family: "Roboto".to_string(),
        body_font_size: 14.0,
        body_font_weight: FontWeight(3),
        border_radius: 8.0,
        app_bar_elevation: 4.0,
        app_bar_title_font_size: 18.0,
        app_bar_title_font_weight: FontWeight(6),
        use_material3: true,
    };

    let theme_id = TypedRecordId::new_v4(TableKind::MapTheme);
    let theme = MapTheme {
        key: theme_id,
        fields: theme_fields.clone(),
    };

    let saved = repo.themes.save_theme(theme).await.unwrap();
    assert_eq!(saved.key, theme_id);

    let fetched = repo
        .themes
        .get_theme_by_key(&theme_id.key.to_string())
        .await
        .unwrap();
    assert!(fetched.is_some());
    let fetched = fetched.unwrap();
    assert_eq!(fetched.fields.name, "My Dark Theme");
    assert_eq!(fetched.fields.primary_color, 0x112233);
    assert_eq!(fetched.fields.secondary_color, 0x445566);
    assert_eq!(fetched.fields.accent_color, 0x778899);

    let mut updated_fields = theme_fields.clone();
    updated_fields.name = "Updated Dark Theme".to_string();
    updated_fields.primary_color = 0x445566;
    let updated_theme = MapTheme {
        key: theme_id,
        fields: updated_fields,
    };
    repo.themes.save_theme(updated_theme).await.unwrap();

    let fetched_updated = repo
        .themes
        .get_theme_by_key(&theme_id.key.to_string())
        .await
        .unwrap()
        .unwrap();
    assert_eq!(fetched_updated.fields.name, "Updated Dark Theme");
    assert_eq!(fetched_updated.fields.primary_color, 0x445566);
    assert_eq!(fetched_updated.fields.secondary_color, 0x445566);
    assert_eq!(fetched_updated.fields.accent_color, 0x778899);

    let mut map_data = repo.snapshot.get_map_data().await.unwrap();
    map_data.active_theme_id = Some(theme_id.key.to_string());
    repo.snapshot.update_map_data(map_data).await.unwrap();

    let fetched_map_data = repo.snapshot.get_map_data().await.unwrap();
    assert_eq!(fetched_map_data.active_theme_id, Some(theme_id.key.to_string()));

    let themes = repo.themes.list_themes().await.unwrap();
    assert_eq!(themes.len(), 1);
    assert_eq!(themes[0].key, theme_id);
    assert_eq!(themes[0].fields.name, "Updated Dark Theme");
    assert_eq!(themes[0].fields.secondary_color, 0x445566);
    assert_eq!(themes[0].fields.accent_color, 0x778899);
}

#[tokio::test]
async fn test_delete_theme() {
    let repo = setup_test_repo().await;

    let theme_fields = ThemeFields {
        name: "Deletable Theme".to_string(),
        primary_color: 0x000000,
        secondary_color: 0x111111,
        tertiary_color: 0x1a1a1a,
        accent_color: 0x222222,
        canvas_accent_color: 0x333333,
        font_family: "Roboto".to_string(),
        body_font_size: 14.0,
        body_font_weight: FontWeight(4),
        border_radius: 8.0,
        app_bar_elevation: 4.0,
        app_bar_title_font_size: 18.0,
        app_bar_title_font_weight: FontWeight(6),
        use_material3: true,
    };

    let theme_id = TypedRecordId::new_v4(TableKind::MapTheme);
    let theme = MapTheme {
        key: theme_id,
        fields: theme_fields,
    };

    repo.themes.save_theme(theme).await.unwrap();

    let fetched = repo
        .themes
        .get_theme_by_key(&theme_id.key.to_string())
        .await
        .unwrap();
    assert!(fetched.is_some());

    let deleted = repo
        .themes
        .delete_theme(&theme_id.key.to_string())
        .await
        .unwrap();
    assert!(deleted);

    let fetched_after_delete = repo
        .themes
        .get_theme_by_key(&theme_id.key.to_string())
        .await
        .unwrap();
    assert!(fetched_after_delete.is_none());

    let deleted_again = repo
        .themes
        .delete_theme(&theme_id.key.to_string())
        .await
        .unwrap();
    assert!(!deleted_again);
}
