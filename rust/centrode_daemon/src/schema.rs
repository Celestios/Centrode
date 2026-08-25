use anyhow::Result;
use crate::domain::base_models::MapData;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub struct Schema;
impl Schema {
    pub async fn init(db: &Surreal<Db>) -> Result<()> {
        let surql = include_str!("map_schema.surql");
        tracing::info!("Applying schema from map_schema.surql...");
        db.query(surql).await.map_err(|e| {
            tracing::error!("Schema initialization failed: {}", e);
            anyhow::anyhow!("Schema initialization failed: {}", e)
        })?;
        tracing::info!("Map schema file applied successfully.");

        Ok(())
    }
}

pub struct Seeder;
impl Seeder {
    pub async fn seed_default_data(db: &Surreal<Db>, name: String) -> Result<()> {
        tracing::debug!("Checking for existing MapData...");
        let existing: Option<MapData> = db.select(MapData::record_id().to_record_id()).await?;

        if existing.is_none() {
            tracing::info!("First-time initialization: Creating MapData record '{}'", name);
            let mut metadata = MapData::default();
            metadata.map_name = name;

            let _: Option<MapData> = db
                .create(MapData::record_id().to_record_id())
                .content(metadata)
                .await?;
        }

        Ok(())
    }

    pub async fn seed_system_data(db: &Surreal<Db>) -> Result<()> {
        tracing::debug!("Seeding system default relations into centrode:system...");
        use crate::domain::relations::IRelationFields;
        use crate::domain::styles::{EndpointShape, RelationDirection, RelationStyle};
        use crate::domain::traits::TableKind;
        use surrealdb::types::{RecordId, RecordIdKey};

        let starter_relations = [
            ("contradicts", Some(EndpointShape::Arrow), Some(EndpointShape::Arrow), "solid", 0xFFFF3B30u32, "inward"),
            ("depends_on", None, Some(EndpointShape::Arrow), "dashed", 0xFFFF9500u32, "outward"),
            ("supports", None, Some(EndpointShape::Arrow), "solid", 0xFF34C759u32, "outward"),
            ("causes", None, Some(EndpointShape::Arrow), "solid", 0xFF007AFFu32, "outward"),
            ("part_of", Some(EndpointShape::Diamond), None, "solid", 0xFFAF52DEu32, "diamond"),
            ("leads_to", None, Some(EndpointShape::OpenArrow), "solid", 0xFF8E8E93u32, "open_arrow"),
            ("blocks", Some(EndpointShape::Square), Some(EndpointShape::Square), "solid", 0xFFFF2D55u32, "square"),
        ];

        let now = chrono::Utc::now().timestamp_millis();
        for (verb, start_shape, end_shape, line_style, stroke_color, arrow_type) in starter_relations {
            let rid = RecordId::new(TableKind::IRelation.table_name(), RecordIdKey::String(verb.to_string()));
            let existing: Option<IRelationFields> = db.select(rid.clone()).await.unwrap_or(None);
            if existing.is_none() {
                let style = RelationStyle {
                    bg_color: 0,
                    stroke_color,
                    stroke_width: 2,
                    font_family: "Inter".to_string(),
                    font_size: 13.0,
                    shape: "straight".to_string(),
                    arrow_type: arrow_type.to_string(),
                    arrow_size: 10.0,
                    start_shape,
                    end_shape,
                    width: 0,
                    height: 0,
                    text_color: 0xFFFFFFFF,
                    shadow_color: 0,
                    shadow_blur: 0.0,
                    shadow_offset_x: 0.0,
                    shadow_offset_y: 0.0,
                    strategy_type: "default".to_string(),
                    stroke_pattern: line_style.to_string(),
                    body_strategy: "default".to_string(),
                };

                let fields = IRelationFields {
                    verb: verb.to_string(),
                    style: Some(style),
                    resolved_style: None,
                    layout: None,
                    resolved_layout: None,
                    direction: RelationDirection::Forward,
                    layer: "default".to_string(),
                    created_at: now,
                    updated_at: now,
                };
                let _: Option<IRelationFields> = db.create(rid).content(fields).await?;
            }
        }

        Ok(())
    }
}
