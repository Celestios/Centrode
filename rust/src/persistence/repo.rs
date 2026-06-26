use std::collections::HashMap;
use std::sync::Mutex;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

use crate::domain::relation_engine::engine::InputNode;

pub mod nodes;
pub mod relations;
pub mod tags;
pub mod templates;
pub mod patches;
pub mod analysis;

#[derive(Clone)]
pub struct Repository {
    db: Surreal<Db>,
    node_cache: std::sync::Arc<Mutex<HashMap<String, InputNode>>>,
}

impl Repository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self {
            db,
            node_cache: std::sync::Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }

    pub fn node_cache(&self) -> &std::sync::Arc<Mutex<HashMap<String, InputNode>>> {
        &self.node_cache
    }

    pub fn update_node_cache(&self, node: InputNode) {
        if let Ok(mut cache) = self.node_cache.lock() {
            cache.insert(node.id.clone(), node);
        }
    }

    pub fn remove_from_node_cache(&self, node_id: &str) {
        if let Ok(mut cache) = self.node_cache.lock() {
            cache.remove(node_id);
        }
    }

    pub fn get_cached_nodes(&self) -> Vec<InputNode> {
        match self.node_cache.lock() {
            Ok(cache) => cache.values().cloned().collect(),
            Err(_) => Vec::new(),
        }
    }

    pub fn clear_node_cache(&self) {
        if let Ok(mut cache) = self.node_cache.lock() {
            cache.clear();
        }
    }
}
