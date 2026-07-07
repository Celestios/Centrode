pub mod incremental;
pub mod cache;

use std::collections::HashMap;
use super::computed::ComputedRelation;
use super::input::InputNode;
use incremental::IncrementalState;

#[derive(Debug, Clone)]
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
        let new_rect = node.rect();

        let mut to_invalidate = Vec::new();
        for (rel_id, rel) in &self.relations {
            let is_endpoint = rel.depends_on_nodes.contains(&node.id);
            let intersects_old = old_node.as_ref().map_or(false, |old| {
                rel.bbox.overlaps(&old.rect().expand(margin))
            });
            let intersects_new = rel.bbox.overlaps(&new_rect.expand(margin));

            if is_endpoint || intersects_old || intersects_new {
                to_invalidate.push(rel_id.clone());
            }
        }

        for rel_id in to_invalidate {
            self.relations.remove(&rel_id);
            self.incremental.mark_dirty(&rel_id);
        }
    }

    pub fn remove_node(&mut self, node_id: &str) {
        self.nodes.remove(node_id);

        let mut to_invalidate = Vec::new();
        for (rel_id, rel) in &self.relations {
            if rel.depends_on_nodes.contains(&node_id.to_string()) {
                to_invalidate.push(rel_id.clone());
            }
        }

        for rel_id in to_invalidate {
            self.relations.remove(&rel_id);
            self.incremental.mark_dirty(&rel_id);
        }
    }

    pub fn clear(&mut self) {
        self.nodes.clear();
        self.relations.clear();
        self.incremental.clear();
    }
}
