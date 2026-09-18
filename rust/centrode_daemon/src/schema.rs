use anyhow::Result;
use crate::domain::base_models::MapData;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub struct Schema;
impl Schema {
    pub async fn init(db: &Surreal<Db>) -> Result<()> {
        let surql = include_str!("map_schema.surql");
        tracing::info!("Applying schema from map_schema.surql...");
        db.query(surql).await?.check()?;
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
        let surql = include_str!("system_relations.surql");
        db.query(surql).await?.check()?;
        Ok(())
    }
}
