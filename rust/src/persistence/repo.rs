use std::sync::Mutex;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

use crate::domain::relation_engine::input::InputNode;
use crate::domain::relation_engine::engine::RelationEngine;

pub mod nodes;
pub mod relations;
pub mod tags;
pub mod templates;
pub mod patches;
pub mod analysis;

#[derive(Clone)]
pub struct Repository {
    db: Surreal<Db>,
    relation_engine: std::sync::Arc<Mutex<RelationEngine>>,
}

impl Repository {
    pub fn new(db: Surreal<Db>) -> Self {
        Self {
            db,
            relation_engine: std::sync::Arc::new(Mutex::new(RelationEngine::new())),
        }
    }

    pub fn db(&self) -> &Surreal<Db> {
        &self.db
    }

    pub fn relation_engine(&self) -> &std::sync::Arc<Mutex<RelationEngine>> {
        &self.relation_engine
    }

    pub fn update_node_cache(&self, node: InputNode) {
        if let Ok(mut engine) = self.relation_engine.lock() {
            engine.state.update_node(node, 45.0);
        }
    }

    pub fn remove_from_node_cache(&self, node_id: &str) {
        if let Ok(mut engine) = self.relation_engine.lock() {
            engine.state.remove_node(node_id);
            // Also invalidate from cache
            let to_remove: Vec<String> = engine.cache.routes.iter()
                .filter(|(_, r)| r.depends_on_nodes.contains(&node_id.to_string()))
                .map(|(id, _)| id.clone())
                .collect();
            for id in to_remove {
                engine.cache.remove(&id);
            }
        }
    }

    pub fn get_cached_nodes(&self) -> Vec<InputNode> {
        match self.relation_engine.lock() {
            Ok(engine) => engine.state.nodes.values().cloned().collect(),
            Err(_) => Vec::new(),
        }
    }

    pub fn clear_node_cache(&self) {
        if let Ok(mut engine) = self.relation_engine.lock() {
            engine.state.clear();
            engine.cache.clear();
        }
    }
}
