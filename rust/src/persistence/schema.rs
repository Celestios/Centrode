use anyhow::Result;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub struct Schema;
impl Schema {
    pub async fn init(db: &Surreal<Db>) -> Result<()> {
        let surql = include_str!("schema.surql");
        tracing::info!("Applying schema from schema.surql...");
        db.query(surql).await.map_err(|e| {
            tracing::error!("Schema initialization failed: {}", e);
            anyhow::anyhow!("Schema initialization failed: {}", e)
        })?;
        tracing::info!("Schema file applied successfully.");

        Ok(())
    }
}

pub struct Seeder;
impl Seeder {
    pub async fn seed_default_data(db: &Surreal<Db>, name: String) -> Result<()> {
        use crate::domain::base_models::MapData;

        tracing::debug!("Checking for existing MapMetadata...");
        let existing: Option<MapData> = db.select((MapData::LABEL, MapData::KEY)).await?;

        if existing.is_none() {
            tracing::info!("First-time initialization: Creating MapMetadata record '{}'", name);
            let mut metadata = MapData::default();
            metadata.map_name = name;

            let _: Option<MapData> = db
                .create((MapData::LABEL, MapData::KEY))
                .content(metadata)
                .await?;
        }

        Ok(())
    }
}
