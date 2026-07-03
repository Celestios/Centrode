use std::collections::HashMap;
use crate::domain::relation_engine::computed::ComputedRelation;

#[derive(Debug, Clone)]
pub struct RelationCache {
    pub routes: HashMap<String, ComputedRelation>,
}

impl RelationCache {
    pub fn new() -> Self {
        Self {
            routes: HashMap::new(),
        }
    }

    pub fn get(&self, relation_id: &str) -> Option<&ComputedRelation> {
        self.routes.get(relation_id)
    }

    pub fn insert(&mut self, relation_id: String, relation: ComputedRelation) {
        self.routes.insert(relation_id, relation);
    }

    pub fn remove(&mut self, relation_id: &str) {
        self.routes.remove(relation_id);
    }

    pub fn clear(&mut self) {
        self.routes.clear();
    }
}
