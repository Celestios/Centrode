use std::collections::{HashMap, HashSet};
use crate::domain::relation_engine::geometry::Rect;
use crate::domain::relation_engine::types::InputNode;
use crate::domain::relation_engine::computed::ComputedRelation;

pub struct IncrementalState {
    pub dependencies: HashMap<String, Vec<String>>,
    pub bboxes: HashMap<String, Rect>,
    pub dirty_nodes: HashSet<String>,
    pub dirty_relations: HashSet<String>,
}

impl IncrementalState {
    pub fn new() -> Self {
        Self {
            dependencies: HashMap::new(),
            bboxes: HashMap::new(),
            dirty_nodes: HashSet::new(),
            dirty_relations: HashSet::new(),
        }
    }

    pub fn register(&mut self, relation_id: String, depends_on_nodes: Vec<String>, bbox: Rect) {
        self.dependencies.insert(relation_id.clone(), depends_on_nodes);
        self.bboxes.insert(relation_id, bbox);
    }

    pub fn unregister(&mut self, relation_id: &str) {
        self.dependencies.remove(relation_id);
        self.bboxes.remove(relation_id);
        self.dirty_relations.remove(relation_id);
    }

    pub fn mark_node_dirty(&mut self, node_id: String) {
        self.dirty_nodes.insert(node_id);
    }

    pub fn mark_relation_dirty(&mut self, relation_id: String) {
        self.dirty_relations.insert(relation_id);
    }

    pub fn mark_all_dirty(&mut self) {
        let keys: Vec<String> = self.dependencies.keys().cloned().collect();
        self.dirty_relations.extend(keys);
    }

    pub fn dirty_relation_ids(
        &self,
        dirty_node_positions: &HashMap<String, Rect>,
        margin: f64,
    ) -> Vec<String> {
        let mut affected = self.dirty_relations.clone();

        for dirty_node in &self.dirty_nodes {
            for (rel_id, deps) in &self.dependencies {
                if deps.contains(dirty_node) {
                    affected.insert(rel_id.clone());
                }
            }
        }

        for (rel_id, rel_bbox) in &self.bboxes {
            if affected.contains(rel_id) {
                continue;
            }
            for (node_id, node_bbox) in dirty_node_positions {
                if self.dirty_nodes.contains(node_id) {
                    let expanded = node_bbox.expand(margin);
                    if expanded.overlaps(*rel_bbox) {
                        affected.insert(rel_id.clone());
                        break;
                    }
                }
            }
        }

        affected.into_iter().collect()
    }

    pub fn clear_dirty(&mut self) {
        self.dirty_nodes.clear();
        self.dirty_relations.clear();
    }

    pub fn clear_dirty_id(&mut self, relation_id: &str) {
        self.dirty_relations.remove(relation_id);
    }

    pub fn has_dirty(&self) -> bool {
        !self.dirty_nodes.is_empty() || !self.dirty_relations.is_empty()
    }

    pub fn clear(&mut self) {
        self.dependencies.clear();
        self.bboxes.clear();
        self.dirty_nodes.clear();
        self.dirty_relations.clear();
    }
}

pub struct CanvasState {
    pub nodes: HashMap<String, InputNode>,
    pub relations: HashMap<String, ComputedRelation>,
    pub incremental: IncrementalState,
}

impl CanvasState {
    pub fn new() -> Self {
        Self {
            nodes: HashMap::new(),
            relations: HashMap::new(),
            incremental: IncrementalState::new(),
        }
    }

    pub fn update_node(&mut self, node: InputNode, margin: f64) {
        let old_node = self.nodes.insert(node.id.clone(), node.clone());

        let mut to_invalidate = Vec::new();
        for (rel_id, rel) in &self.relations {
            let is_endpoint = rel.depends_on_nodes.contains(&node.id);
            let intersects_old = old_node.as_ref().map(|o| o.bounding_box().expand(margin).overlaps(rel.bbox)).unwrap_or(false);
            let intersects_new = node.bounding_box().expand(margin).overlaps(rel.bbox);

            if is_endpoint || intersects_old || intersects_new {
                to_invalidate.push(rel_id.clone());
            }
        }

        for rel_id in to_invalidate {
            self.relations.remove(&rel_id);
            self.incremental.mark_relation_dirty(rel_id);
        }

        self.incremental.mark_node_dirty(node.id);
    }

    pub fn remove_node(&mut self, node_id: &str) {
        self.nodes.remove(node_id);

        let mut to_invalidate = Vec::new();
        for (rel_id, rel) in &self.relations {
            if rel.depends_on_nodes.iter().any(|id| id == node_id) {
                to_invalidate.push(rel_id.clone());
            }
        }

        for rel_id in to_invalidate {
            self.relations.remove(&rel_id);
            self.incremental.mark_relation_dirty(rel_id);
        }

        self.incremental.mark_node_dirty(node_id.to_string());
    }

    pub fn clear(&mut self) {
        self.nodes.clear();
        self.relations.clear();
        self.incremental.clear();
    }
}

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
