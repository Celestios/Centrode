use crate::domain::base_models::MapDescriptor;
use crate::domain::traits::TableKind;
use crate::engine::EngineManager;
use anyhow::Result;
use chrono::Utc;
use surrealdb::engine::local::Db;
use surrealdb::types::{RecordId, RecordIdKey, Value};
use surrealdb::Surreal;
use uuid::Uuid;

pub struct DaemonService {
    db: Surreal<Db>,
}

impl DaemonService {
    pub async fn new() -> Result<Self> {
        let db = EngineManager::system_db().await?;
        Self::init_schema(&db).await?;
        Ok(Self { db })
    }

    pub async fn with_db(db: Surreal<Db>) -> Result<Self> {
        Self::init_schema(&db).await?;
        Ok(Self { db })
    }

    async fn init_schema(db: &Surreal<Db>) -> Result<()> {
        let schema = include_str!("../system_schema.surql");
        db.query(schema).await?;
        Ok(())
    }

    pub async fn list_maps(&self) -> Result<Vec<MapDescriptor>> {
        let table = TableKind::MapRegistry.table_name();
        let query_str = format!("SELECT * FROM {} ORDER BY created_at_ms DESC;", table);
        let mut response = self.db.query(query_str).await?;
        let vals: Vec<Value> = response.take(0)?;
        Ok(vals.into_iter().filter_map(value_to_descriptor).collect())
    }

    pub async fn get_recent_maps(&self, limit: usize) -> Result<Vec<MapDescriptor>> {
        let table = TableKind::MapRegistry.table_name();
        let query_str = format!("SELECT * FROM {} ORDER BY accessed_at_ms DESC LIMIT $limit;", table);
        let mut response = self.db.query(query_str).bind(("limit", limit)).await?;
        let vals: Vec<Value> = response.take(0)?;
        Ok(vals.into_iter().filter_map(value_to_descriptor).collect())
    }

    pub async fn create_map(&self, name: &str) -> Result<MapDescriptor> {
        let now = Utc::now().timestamp_millis();
        let map_id = Uuid::new_v4().to_string();
        let storage_path = format!("maps/{}.db", map_id);
        let rid = RecordId::new(TableKind::MapRegistry.table_name(), RecordIdKey::String(map_id.clone()));

        let descriptor = MapDescriptor {
            id: map_id,
            name: name.to_string(),
            storage_path: storage_path.clone(),
            created_at_ms: now,
            modified_at_ms: now,
            accessed_at_ms: now,
        };

        self.db
            .query("CREATE $id SET name = $name, storage_path = $storage_path, created_at_ms = $created_at_ms, modified_at_ms = $modified_at_ms, accessed_at_ms = $accessed_at_ms;")
            .bind(("id", rid))
            .bind(("name", name.to_string()))
            .bind(("storage_path", storage_path))
            .bind(("created_at_ms", now))
            .bind(("modified_at_ms", now))
            .bind(("accessed_at_ms", now))
            .await?;

        Ok(descriptor)
    }

    pub async fn delete_map(&self, map_id: &str) -> Result<()> {
        if EngineManager::is_initialized() {
            EngineManager::delete_map_db(map_id).await?;
        }
        let rid = RecordId::new(TableKind::MapRegistry.table_name(), RecordIdKey::String(map_id.to_string()));
        self.db
            .query("DELETE $id;")
            .bind(("id", rid))
            .await?;
        Ok(())
    }

    pub async fn rename_map(&self, map_id: &str, new_name: &str) -> Result<MapDescriptor> {
        let now = Utc::now().timestamp_millis();
        let rid = RecordId::new(TableKind::MapRegistry.table_name(), RecordIdKey::String(map_id.to_string()));
        self.db
            .query("UPDATE $id SET name = $name, modified_at_ms = $now;")
            .bind(("id", rid))
            .bind(("name", new_name.to_string()))
            .bind(("now", now))
            .await?;

        self.get_map(map_id).await
    }

    pub async fn duplicate_map(&self, map_id: &str, new_name: &str) -> Result<MapDescriptor> {
        let new_map = self.create_map(new_name).await?;
        if EngineManager::is_initialized() {
            let src_db = EngineManager::map_db(map_id).await?;
            let dst_db = EngineManager::open_map_db(&new_map.id, new_name).await?;
            let mut src_nodes = src_db.query("SELECT * FROM INode;").await?;
            let nodes: Vec<Value> = src_nodes.take(0)?;
            for node in nodes {
                if let Value::Object(obj) = node {
                    if let Some(id) = obj.get("id") {
                        dst_db.query("CREATE $id CONTENT $data;").bind(("id", id.clone())).bind(("data", Value::Object(obj))).await?;
                    }
                }
            }
            let mut src_relations = src_db.query("SELECT * FROM IRelation;").await?;
            let relations: Vec<Value> = src_relations.take(0)?;
            for rel in relations {
                if let Value::Object(obj) = rel {
                    if let Some(id) = obj.get("id") {
                        dst_db.query("CREATE $id CONTENT $data;").bind(("id", id.clone())).bind(("data", Value::Object(obj))).await?;
                    }
                }
            }
        }
        Ok(new_map)
    }

    pub async fn touch_map(&self, map_id: &str) -> Result<()> {
        let now = Utc::now().timestamp_millis();
        let rid = RecordId::new(TableKind::MapRegistry.table_name(), RecordIdKey::String(map_id.to_string()));
        self.db
            .query("UPDATE $id SET accessed_at_ms = $now;")
            .bind(("id", rid))
            .bind(("now", now))
            .await?;
        Ok(())
    }

    pub async fn get_map(&self, map_id: &str) -> Result<MapDescriptor> {
        let rid = RecordId::new(TableKind::MapRegistry.table_name(), RecordIdKey::String(map_id.to_string()));
        let mut response = self
            .db
            .query("SELECT * FROM ONLY $id;")
            .bind(("id", rid))
            .await?;
        let val: Option<Value> = response.take(0)?;
        val.and_then(value_to_descriptor)
            .ok_or_else(|| anyhow::anyhow!("Map not found: {}", map_id))
    }

    pub async fn get_setting(&self, key: &str) -> Result<Option<String>> {
        let rid = RecordId::new(TableKind::SystemSetting.table_name(), RecordIdKey::String(key.to_string()));
        let mut response = self
            .db
            .query("SELECT * FROM ONLY $id;")
            .bind(("id", rid))
            .await?;
        let val: Option<Value> = response.take(0)?;
        if let Some(Value::Object(obj)) = val {
            if let Some(Value::String(s)) = obj.get("value") {
                return Ok(Some(s.clone()));
            }
        }
        Ok(None)
    }

    pub async fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        let rid = RecordId::new(TableKind::SystemSetting.table_name(), RecordIdKey::String(key.to_string()));
        self.db
            .query("UPSERT $id SET value = $value;")
            .bind(("id", rid))
            .bind(("value", value.to_string()))
            .await?;
        Ok(())
    }

    pub async fn delete_setting(&self, key: &str) -> Result<()> {
        let rid = RecordId::new(TableKind::SystemSetting.table_name(), RecordIdKey::String(key.to_string()));
        self.db
            .query("DELETE $id;")
            .bind(("id", rid))
            .await?;
        Ok(())
    }
}

fn value_to_descriptor(val: Value) -> Option<MapDescriptor> {
    if let Value::Object(obj) = val {
        let id = match obj.get("id") {
            Some(Value::RecordId(rid)) => match &rid.key {
                RecordIdKey::String(s) => s.clone(),
                RecordIdKey::Uuid(u) => u.to_string(),
                RecordIdKey::Number(n) => n.to_string(),
                _ => format!("{:?}", rid.key),
            },
            Some(Value::String(s)) => s.clone(),
            _ => return None,
        };
        let name = match obj.get("name") {
            Some(Value::String(s)) => s.clone(),
            _ => "Untitled Map".to_string(),
        };
        let storage_path = match obj.get("storage_path") {
            Some(Value::String(s)) => s.clone(),
            _ => format!("maps/{}.db", id),
        };
        let created_at_ms = match obj.get("created_at_ms") {
            Some(Value::Number(surrealdb::types::Number::Int(n))) => *n,
            Some(Value::Number(surrealdb::types::Number::Float(f))) => *f as i64,
            _ => 0,
        };
        let modified_at_ms = match obj.get("modified_at_ms") {
            Some(Value::Number(surrealdb::types::Number::Int(n))) => *n,
            Some(Value::Number(surrealdb::types::Number::Float(f))) => *f as i64,
            _ => 0,
        };
        let accessed_at_ms = match obj.get("accessed_at_ms") {
            Some(Value::Number(surrealdb::types::Number::Int(n))) => *n,
            Some(Value::Number(surrealdb::types::Number::Float(f))) => *f as i64,
            _ => 0,
        };

        Some(MapDescriptor {
            id,
            name,
            storage_path,
            created_at_ms,
            modified_at_ms,
            accessed_at_ms,
        })
    } else {
        None
    }
}
