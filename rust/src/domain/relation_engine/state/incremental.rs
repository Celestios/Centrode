use std::collections::{HashMap, HashSet};

use crate::domain::relation_engine::geometry::Rect;

/// Tracks which relations need recomputation after mutations.
///
/// Uses dependency tracking (which nodes each relation depends on)
/// and spatial bbox filtering to minimize the set of affected relations.
pub struct IncrementalState {
    /// relation_id -> set of node IDs it depends on
    dependencies: HashMap<String, Vec<String>>,
    /// relation_id -> bounding box of last computed path
    bboxes: HashMap<String, Rect>,
    /// set of node IDs that have changed since last flush
    dirty_nodes: HashSet<String>,
    /// relation IDs explicitly marked dirty
    dirty_relations: HashSet<String>,
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

    /// Register a relation's dependencies and bbox after computation.
    pub fn register(
        &mut self,
        relation_id: String,
        depends_on_nodes: Vec<String>,
        bbox: Rect,
    ) {
        self.dependencies.insert(relation_id.clone(), depends_on_nodes);
        self.bboxes.insert(relation_id, bbox);
    }

    /// Remove a relation from tracking.
    pub fn unregister(&mut self, relation_id: &str) {
        self.dependencies.remove(relation_id);
        self.bboxes.remove(relation_id);
    }

    /// Mark a node as changed.
    pub fn mark_node_dirty(&mut self, node_id: &str) {
        self.dirty_nodes.insert(node_id.to_string());
    }

    /// Mark a specific relation as dirty.
    pub fn mark_relation_dirty(&mut self, relation_id: &str) {
        self.dirty_relations.insert(relation_id.to_string());
    }

    /// Mark all relations as dirty (e.g., on config change).
    pub fn mark_all_dirty(&mut self) {
        self.dirty_relations.extend(self.dependencies.keys().cloned());
    }

    /// Returns the set of relation IDs that need recomputation.
    ///
    /// Uses two filters:
    /// 1. Dependency filter: relation depends on a dirty node
    /// 2. Spatial filter: relation's bbox intersects the dirty region
    pub fn dirty_relation_ids(&self, dirty_node_positions: &HashMap<String, Rect>, margin: f64) -> Vec<String> {
        let mut affected: HashSet<String> = HashSet::new();

        // Direct dirty relations
        affected.extend(self.dirty_relations.iter().cloned());

        // Relations depending on dirty nodes
        for dirty_node in &self.dirty_nodes {
            for (rel_id, deps) in &self.dependencies {
                if deps.contains(dirty_node) {
                    affected.insert(rel_id.clone());
                }
            }
        }

        // Spatial filter: if a dirty node's bbox intersects a relation's bbox
        for (rel_id, rel_bbox) in &self.bboxes {
            if affected.contains(rel_id.as_str()) {
                continue;
            }
            for (_node_id, node_bbox) in dirty_node_positions {
                // Expand node bbox by typical obstacle margin
                let expanded = node_bbox.expand(margin);
                if rects_overlap(&expanded, rel_bbox) {
                    affected.insert(rel_id.clone());
                }
            }
        }

        affected.into_iter().collect()
    }

    /// Clear dirty state after recomputation.
    pub fn clear_dirty(&mut self) {
        self.dirty_nodes.clear();
        self.dirty_relations.clear();
    }

    /// Check if there are any dirty relations.
    pub fn has_dirty(&self) -> bool {
        !self.dirty_nodes.is_empty() || !self.dirty_relations.is_empty()
    }

    /// Number of tracked relations.
    pub fn len(&self) -> usize {
        self.dependencies.len()
    }

    /// Whether tracking is empty.
    pub fn is_empty(&self) -> bool {
        self.dependencies.is_empty()
    }
}

fn rects_overlap(a: &Rect, b: &Rect) -> bool {
    a.left() <= b.right()
        && a.right() >= b.left()
        && a.top() <= b.bottom()
        && a.bottom() >= b.top()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_register_and_dirty_detection() {
        let mut state = IncrementalState::new();
        state.register(
            "r1".into(),
            vec!["n1".into(), "n2".into()],
            Rect::new(0.0, 0.0, 100.0, 50.0),
        );
        state.register(
            "r2".into(),
            vec!["n3".into()],
            Rect::new(200.0, 200.0, 100.0, 50.0),
        );

        state.mark_node_dirty("n1");
        let dirty = state.dirty_relation_ids(&HashMap::new(), 45.0);
        assert!(dirty.contains(&"r1".to_string()));
        assert!(!dirty.contains(&"r2".to_string()));
    }

    #[test]
    fn test_spatial_filter() {
        let mut state = IncrementalState::new();
        // Relation far away
        state.register(
            "r1".into(),
            vec!["n1".into()],
            Rect::new(500.0, 500.0, 100.0, 50.0),
        );

        // Dirty node near the relation
        let mut positions = HashMap::new();
        positions.insert("n1".into(), Rect::new(520.0, 520.0, 80.0, 40.0));

        state.mark_node_dirty("n1");
        let dirty = state.dirty_relation_ids(&positions, 45.0);
        assert!(dirty.contains(&"r1".to_string()));
    }

    #[test]
    fn test_clear_dirty() {
        let mut state = IncrementalState::new();
        state.register("r1".into(), vec!["n1".into()], Rect::new(0.0, 0.0, 10.0, 10.0));
        state.mark_node_dirty("n1");
        assert!(state.has_dirty());
        state.clear_dirty();
        assert!(!state.has_dirty());
    }
}
