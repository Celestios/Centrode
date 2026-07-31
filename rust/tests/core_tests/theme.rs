use crate::common::setup_test_repo;
use centrode_core::domain::theme::{FontWeight, ThemeBrightness, ThemeFields};
use surrealdb::types::RecordId;

#[tokio::test]
async fn test_theme_crud_and_active_theme() {
    let repo = setup_test_repo().await;

    let theme_fields = ThemeFields {
        name: "My Dark Theme".to_string(),
        primary_color: 0x112233,
        secondary_color: 0x445566,
        accent_color: 0x778899,
        scaffold_background_color: 0x000000,
        card_color: 0x222222,
        divider_color: 0x333333,
        text_color: 0xffffff,
        font_family: "Roboto".to_string(),
        body_font_size: 14.0,
        body_font_weight: FontWeight(3),
        body_text_color: 0xdddddd,
        border_radius: 8.0,
        app_bar_background_color: 0x111111,
        app_bar_foreground_color: 0xeeeeee,
        app_bar_elevation: 4.0,
        app_bar_title_font_size: 18.0,
        app_bar_title_font_weight: FontWeight(6),
        use_material3: true,
        brightness: ThemeBrightness::Dark,
    };

    let theme_id = RecordId::new("MapTheme", "dark_theme");
    let _: Option<ThemeFields> = repo.db()
        .query("CREATE $record_id CONTENT $fields")
        .bind(("record_id", theme_id.clone()))
        .bind(("fields", theme_fields.clone()))
        .await
        .unwrap()
        .take(0)
        .unwrap();

    let fetched_fields: Option<ThemeFields> = repo.db().select(theme_id.clone()).await.unwrap();
    assert!(fetched_fields.is_some());
    let fetched_fields = fetched_fields.unwrap();
    assert_eq!(fetched_fields.name, "My Dark Theme");
    assert_eq!(fetched_fields.primary_color, 0x112233);
    assert_eq!(fetched_fields.secondary_color, 0x445566);
    assert_eq!(fetched_fields.accent_color, 0x778899);

    let mut updated_fields = theme_fields.clone();
    updated_fields.name = "Updated Dark Theme".to_string();
    updated_fields.primary_color = 0x445566;
    let _: Option<ThemeFields> = repo.db()
        .query("UPDATE $record_id MERGE $fields")
        .bind(("record_id", theme_id.clone()))
        .bind(("fields", updated_fields))
        .await
        .unwrap()
        .take(0)
        .unwrap();

    let fetched_updated: ThemeFields = repo.db().select(theme_id.clone()).await.unwrap().unwrap();
    assert_eq!(fetched_updated.name, "Updated Dark Theme");
    assert_eq!(fetched_updated.primary_color, 0x445566);
    assert_eq!(fetched_updated.secondary_color, 0x445566);
    assert_eq!(fetched_updated.accent_color, 0x778899);

    let map_data_id = centrode_core::domain::base_models::MapData::record_id().to_record_id();
    repo.db()
        .query("UPDATE $record SET active_theme_id = $theme_id")
        .bind(("record", map_data_id.clone()))
        .bind(("theme_id", "dark_theme".to_string()))
        .await
        .unwrap();

    let mut res = repo.db()
        .query("SELECT VALUE active_theme_id FROM $record")
        .bind(("record", map_data_id))
        .await
        .unwrap();
    let active_theme_id: Option<String> = res.take(0).unwrap();
    assert_eq!(active_theme_id, Some("dark_theme".to_string()));

    let themes: Vec<ThemeFields> = repo.db().select("MapTheme").await.unwrap();
    assert_eq!(themes.len(), 1);
    assert_eq!(themes[0].name, "Updated Dark Theme");
    assert_eq!(themes[0].secondary_color, 0x445566);
    assert_eq!(themes[0].accent_color, 0x778899);
}

