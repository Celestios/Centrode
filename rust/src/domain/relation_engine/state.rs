use std::collections::{HashMap, HashSet};
use super::computed::ComputedRelation;
use super::geometry::Rect;
use super::input::InputNode;

#[derive(Debug, Clone)]
pub struct CanvasState {
    /// Active nodes on the canvas: node_id -> InputNode
    pub nodes: HashMap<String, InputNode>,
    /// Active computed relations: relation_id -> ComputedRelation
    pub relations: HashMap<String, ComputedRelation>,
    /// Set of relation IDs currently marked dirty/needing recomputation
    pub dirty_relations: HashSet<String>,
}

impl CanvasState {
    pub fn new() -> Self {
        Self {
            nodes: HashMap::new(),
            relations: HashMap::new(),
            dirty_relations: HashSet::new(),
        }
    }

    /// Update a node's position and invalidate any overlapping relation paths
    pub fn update_node(&mut self, node: InputNode, margin: f64) {
        let old_node = self.nodes.insert(node.id.clone(), node.clone());
        let new_rect = node.rect();

        let mut to_invalidate = Vec::new();
        for (rel_id, rel) in &self.relations {
            let is_endpoint = rel.depends_on_nodes.contains(&node.id);
            let intersects_old = old_node.as_ref().map_or(false, |old| {
                rects_overlap(&rel.bbox, &old.rect().expand(margin))
            });
            let intersects_new = rects_overlap(&rel.bbox, &new_rect.expand(margin));

            if is_endpoint || intersects_old || intersects_new {
                to_invalidate.push(rel_id.clone());
            }
        }

        for rel_id in to_invalidate {
            self.relations.remove(&rel_id);
            self.dirty_relations.insert(rel_id);
        }
    }

    /// Remove a node and invalidate dependent relations
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
            self.dirty_relations.insert(rel_id);
        }
    }

    /// Clear all state
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.relations.clear();
        self.dirty_relations.clear();
    }
}

fn rects_overlap(a: &Rect, b: &Rect) -> bool {
    a.left() <= b.right() && a.right() >= b.left() && a.top() <= b.bottom() && a.bottom() >= b.top()
}
