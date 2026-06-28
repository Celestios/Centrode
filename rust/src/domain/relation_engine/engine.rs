use std::collections::HashMap;

use super::bundling::bundle_edges;
use super::buffers::RelationBuffers;
use super::computed::{ComputedRelation, LabelAnchor, PathType};
use super::config::{BodyType, EndpointShapeType, RelationEngineConfig, BundlingMode};
use super::crossing::minimize_crossings;

use super::geometry::{Point, Rect};
use super::state::incremental::IncrementalState;
use super::input::{InputEdge, InputNode};
use crate::domain::patches::{EntityPatch, NodePatch};
use super::label::compute_label_position;
use super::nudging::{nudge_edges, NudgeConfig};
use super::routing::{compute_bbox, route_relation};
use super::sections::compute_sections;
use super::sections::body as section_body;
use super::state::CanvasState;
use super::state::cache::RelationCache;

pub struct RelationEngine {
    pub state: CanvasState,
    pub cache: RelationCache,
    pub buffers: RelationBuffers,
}

impl RelationEngine {
    pub fn new() -> Self {
        Self {
            state: CanvasState::new(),
            cache: RelationCache::new(),
            buffers: RelationBuffers::with_capacity(256),
        }
    }

    /// Stateless static entry point (for backward compatibility and tests)
    pub fn compute_relations(
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        relation_ids: Option<&[String]>,
    ) -> Vec<ComputedRelation> {
        let mut engine = Self::new();
        engine.compute_relations_stateful(nodes, edges, config, relation_ids)
    }

    /// Stateless static entry point (for backward compatibility and tests)
    pub fn compute_incremental(
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        incremental: &mut IncrementalState,
    ) -> Vec<ComputedRelation> {
        let mut engine = Self::new();
        engine.compute_incremental_stateful(nodes, edges, config, incremental)
    }

    /// Stateful instance method for computing relations (caching & invalidation)
    pub fn compute_relations_stateful(
        &mut self,
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        relation_ids: Option<&[String]>,
    ) -> Vec<ComputedRelation> {
        // Sync canvas state nodes with the incoming list
        let current_node_ids: std::collections::HashSet<String> = nodes.iter().map(|n| n.id.clone()).collect();
        let removed_node_ids: Vec<String> = self.state.nodes.keys()
            .filter(|id| !current_node_ids.contains(*id))
            .cloned()
            .collect();
        for id in removed_node_ids {
            self.state.remove_node(&id);
        }
        for node in nodes {
            self.state.update_node(node.clone(), config.routing.obstacle_margin);
        }

        let node_map: HashMap<&str, &InputNode> =
            nodes.iter().map(|n| (n.id.as_str(), n)).collect();

        let obstacles: Vec<Rect> = nodes.iter().map(|n| n.rect()).collect();

        let edges_to_compute: Vec<&InputEdge> = if let Some(ids) = relation_ids {
            edges.iter().filter(|e| ids.contains(&e.id)).collect()
        } else {
            edges.iter().collect()
        };

        // Phase 1: Route each edge individually (with cache check)
        let mut results: Vec<ComputedRelation> = Vec::with_capacity(edges_to_compute.len());
        for edge in &edges_to_compute {
            if let Some(cached) = self.cache.get(&edge.id) {
                if !self.state.dirty_relations.contains(&edge.id) {
                    results.push(cached.clone());
                    continue;
                }
            }

            let computed = self.compute_single_relation(edge, &node_map, &obstacles, config);
            self.cache.insert(edge.id.clone(), computed.clone());
            self.state.relations.insert(edge.id.clone(), computed.clone());
            self.state.dirty_relations.remove(&edge.id);
            results.push(computed);
        }

        // Phase 2: Bundle edges sharing endpoints or proximity
        let has_bundled_edges = edges_to_compute.iter().any(|e| {
            e.bundling_mode.as_ref().map_or(false, |m| *m != BundlingMode::None)
        });

        let bundling_mode = if has_bundled_edges {
            edges_to_compute.iter()
                .filter_map(|e| e.bundling_mode)
                .find(|m| *m != BundlingMode::None)
                .unwrap_or(config.bundling.mode)
        } else {
            config.bundling.mode
        };

        if bundling_mode != BundlingMode::None && results.len() >= 2 {
            let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();
            let from_ids: Vec<String> = edges_to_compute.iter().map(|e| e.from_node_id.clone()).collect();
            let to_ids: Vec<String> = edges_to_compute.iter().map(|e| e.to_node_id.clone()).collect();

            let bundling_result = bundle_edges(
                &edge_ids,
                &paths,
                &from_ids,
                &to_ids,
                &bundling_mode,
                config.bundling.threshold,
                2.0,
            );

            // Apply bundle assignments to results
            for result in &mut results {
                if let Some((bundle_id, offset)) = bundling_result.edge_assignments.get(&result.id) {
                    result.bundle_id = Some(bundle_id.clone());
                    result.bundle_offset = Some(*offset);
                }
            }
        }

        // Phase 3: Nudge overlapping edges apart
        if config.nudging.enabled && results.len() >= 2 {
            let nudge_config = NudgeConfig {
                enabled: true,
                min_separation: config.nudging.distance,
                nudge_final_segments: true,
                decay_factor: config.nudging.decay_factor,
            };

            let mut paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();
            let from_ids: Vec<String> = edges_to_compute.iter().map(|e| e.from_node_id.clone()).collect();
            let to_ids: Vec<String> = edges_to_compute.iter().map(|e| e.to_node_id.clone()).collect();

            nudge_edges(&mut paths, &edge_ids, &from_ids, &to_ids, &nudge_config);

            // Update results with nudged paths
            for (i, result) in results.iter_mut().enumerate() {
                result.path_points = paths[i].clone();
                result.bbox = compute_bbox(&result.path_points);
            }
        }

        // Phase 4: Minimize crossings
        if config.crossing_minimization && results.len() >= 2 {
            let mut paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();

            let reordered_ids = minimize_crossings(&mut paths, &edge_ids, 20);

            // Rebuild results in the new order, recomputing tangents, endpoints, etc.
            let id_to_result: HashMap<String, ComputedRelation> =
                results.into_iter().map(|r| (r.id.clone(), r)).collect();

            results = reordered_ids
                .iter()
                .filter_map(|id| id_to_result.get(id).cloned())
                .collect();

            let edge_map: HashMap<&str, &InputEdge> =
                edges_to_compute.iter().map(|e| (e.id.as_str(), *e)).collect();

            for result in &mut results {
                if let Some(idx) = reordered_ids.iter().position(|rid| rid == &result.id) {
                    let untrimmed_path = paths[idx].clone();
                    let edge = edge_map.get(result.id.as_str()).copied();
                    self.finalize_relation(result, &untrimmed_path, edge, &node_map, config);
                }
            }
        }

        // Update cache with final computed/processed routes
        for result in &results {
            self.cache.insert(result.id.clone(), result.clone());
            self.state.relations.insert(result.id.clone(), result.clone());
            self.state.dirty_relations.remove(&result.id);
        }

        results
    }

    /// Stateful instance method for incremental computation
    pub fn compute_incremental_stateful(
        &mut self,
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        incremental: &mut IncrementalState,
    ) -> Vec<ComputedRelation> {
        if !incremental.has_dirty() {
            return Vec::new();
        }

        let dirty_ids = incremental.dirty_relation_ids(&HashMap::new(), config.routing.obstacle_margin);
        incremental.clear_dirty();

        if dirty_ids.is_empty() {
            return Vec::new();
        }

        let results = self.compute_relations_stateful(
            nodes,
            edges,
            config,
            Some(&dirty_ids),
        );

        // Update incremental state with new dependencies and bboxes
        for result in &results {
            incremental.register(
                result.id.clone(),
                result.depends_on_nodes.clone(),
                result.bbox.clone(),
            );
        }

        results
    }

    fn finalize_relation(
        &mut self,
        result: &mut ComputedRelation,
        untrimmed_path: &[Point],
        edge: Option<&InputEdge>,
        node_map: &HashMap<&str, &InputNode>,
        config: &RelationEngineConfig,
    ) {
        let (start_tangent, end_tangent) = super::geometry::compute_tangents(untrimmed_path);
        result.start_tangent = start_tangent;
        result.end_tangent = end_tangent;

        let start_port = untrimmed_path.first().copied().unwrap_or(Point::zero());
        let end_port = untrimmed_path.last().copied().unwrap_or(Point::zero());

        let style = edge.and_then(|e| e.style.as_ref());
        let from_node = edge.and_then(|e| node_map.get(e.from_node_id.as_str()).copied());
        let to_node = edge.and_then(|e| node_map.get(e.to_node_id.as_str()).copied());

        if let Some(node) = from_node {
            let ep = super::sections::endpoint::resolve_start(node, start_port, start_tangent, style, config);
            result.start_endpoint = ep.shape;
            result.start_direction = ep.direction;
        } else {
            result.start_endpoint = style
                .and_then(|s| s.start_shape.as_ref())
                .map(|s| EndpointShapeType::from(*s))
                .unwrap_or(config.endpoint.default_start_shape);
            result.start_direction = start_tangent.direction() + std::f64::consts::PI;
        }

        if let Some(node) = to_node {
            let ep = super::sections::endpoint::resolve_end(node, end_port, end_tangent, style, config);
            result.end_endpoint = ep.shape;
            result.end_direction = ep.direction;
        } else {
            result.end_endpoint = style
                .and_then(|s| s.end_shape.as_ref())
                .map(|s| EndpointShapeType::from(*s))
                .unwrap_or(config.endpoint.default_end_shape);
            result.end_direction = end_tangent.direction();
        }

        let stroke_width = style.map(|s| s.stroke_width as f64).unwrap_or(2.0);
        let arrow_size = style.map(|s| s.arrow_size).unwrap_or(config.endpoint.arrow_size);

        let start_width = match result.body_type {
            BodyType::Taper => config.body.taper_start_width,
            _ => stroke_width,
        };
        let end_width = match result.body_type {
            BodyType::Taper => config.body.taper_end_width,
            _ => stroke_width,
        };

        let start_scale = if start_width > 0.0 { start_width / 2.0 } else { 1.0 };
        let end_scale = if end_width > 0.0 { end_width / 2.0 } else { 1.0 };

        let start_margin = if result.start_endpoint != EndpointShapeType::None {
            arrow_size * start_scale
        } else {
            0.0
        };
        let end_margin = if result.end_endpoint != EndpointShapeType::None {
            arrow_size * end_scale
        } else {
            0.0
        };

        result.path_points = super::painting::relation::trim_path(untrimmed_path, start_margin, end_margin);

        self.buffers.widths.clear();
        let _body_result = section_body::compute_widths(
            &result.path_points,
            result.body_type,
            stroke_width,
            config,
            &mut self.buffers.widths,
        );
        result.body_widths = self.buffers.widths.clone();

        let (label_pos, _) = compute_label_position(&result.path_points, config);
        result.label_position = label_pos;
        result.bbox = compute_bbox(&result.path_points);
        result.start_margin = start_margin;
        result.end_margin = end_margin;
    }

    pub fn update_node_cache(&mut self, node: InputNode, margin: f64) {
        self.state.update_node(node, margin);
    }

    pub fn remove_from_node_cache(&mut self, node_id: &str) {
        self.state.remove_node(node_id);
        let to_remove: Vec<String> = self.cache.routes.iter()
            .filter(|(_, r)| r.depends_on_nodes.contains(&node_id.to_string()))
            .map(|(id, _)| id.clone())
            .collect();
        for id in to_remove {
            self.cache.remove(&id);
        }
    }

    pub fn apply_cache_patch(&mut self, id: &str, patch: &EntityPatch, margin: f64) {
        match patch {
            EntityPatch::Node(patches) => {
                let mut node = match self.state.nodes.get(id).cloned() {
                    Some(n) => n,
                    None => return,
                };
                for node_patch in patches {
                    match node_patch {
                        NodePatch::Position(coords) => {
                            node.x = coords.x as f64;
                            node.y = coords.y as f64;
                        }
                        NodePatch::Size(size) => {
                            node.width = size.width as f64;
                            node.height = size.height as f64;
                        }
                        _ => {}
                    }
                }
                self.state.update_node(node, margin);
            }
            EntityPatch::CreateNode(node, _) => {
                if let Some(input_node) = InputNode::from_domain(node) {
                    self.state.update_node(input_node, margin);
                }
            }
            EntityPatch::DeleteNode(_, _) => {
                self.state.remove_node(id);
            }
            _ => {}
        }
    }

    fn compute_single_relation(
        &mut self,
        edge: &InputEdge,
        node_map: &HashMap<&str, &InputNode>,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) -> ComputedRelation {
        if !node_map.contains_key(edge.from_node_id.as_str()) || !node_map.contains_key(edge.to_node_id.as_str()) {
            return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id);
        }

        let (path_points, path_type) = route_relation(edge, node_map, obstacles, config, &self.state);

        self.buffers.clear();
        self.buffers.path.extend_from_slice(&path_points);

        let sectioned = compute_sections(
            edge,
            node_map,
            config,
            &mut self.buffers.path,
            &mut self.buffers.tail_start,
            &mut self.buffers.tail_end,
        );

        let body_strategy_str = edge.style.as_ref().map(|s| s.body_strategy.as_str()).unwrap_or("");
        let body_type = match body_strategy_str {
            "uniform" => BodyType::Uniform,
            "taper" => BodyType::Taper,
            "widthModulate" => BodyType::WidthModulate,
            "bundled" => BodyType::Bundled,
            _ => config.body.default_type,
        };

        let s = sectioned.as_ref().expect("compute_sections returns None only when nodes are missing, which is handled above");

        let mut result = ComputedRelation {
            id: edge.id.clone(),
            path_points: path_points.clone(),
            path_type,
            start_tangent: Point::new(1.0, 0.0),
            end_tangent: Point::new(1.0, 0.0),
            body_widths: Vec::new(),
            body_type,
            start_endpoint: s.tail_start.endpoint.shape,
            end_endpoint: s.tail_end.endpoint.shape,
            start_direction: s.tail_start.endpoint.direction,
            end_direction: s.tail_end.endpoint.direction,
            label_position: Point::zero(),
            label_anchor: LabelAnchor::Center,
            bundle_id: None,
            bundle_offset: None,
            hit_test_points: Vec::new(),
            depends_on_nodes: vec![edge.from_node_id.clone(), edge.to_node_id.clone()],
            bbox: Rect::new(0.0, 0.0, 0.0, 0.0),
            start_margin: 0.0,
            end_margin: 0.0,
        };

        self.finalize_relation(&mut result, &path_points, Some(edge), node_map, config);
        result
    }
}

fn empty_computed_relation(id: &str, from: &str, to: &str) -> ComputedRelation {
    ComputedRelation {
        id: id.to_string(),
        path_points: vec![Point::zero(), Point::zero()],
        path_type: PathType::Straight,
        start_tangent: Point::new(1.0, 0.0),
        end_tangent: Point::new(1.0, 0.0),
        body_widths: vec![2.0, 2.0],
        body_type: BodyType::Uniform,
        start_endpoint: EndpointShapeType::None,
        end_endpoint: EndpointShapeType::None,
        start_direction: 0.0,
        end_direction: 0.0,
        label_position: Point::zero(),
        label_anchor: LabelAnchor::Center,
        bundle_id: None,
        bundle_offset: None,
        hit_test_points: Vec::new(),
        depends_on_nodes: vec![from.to_string(), to.to_string()],
        bbox: Rect::new(0.0, 0.0, 0.0, 0.0),
        start_margin: 0.0,
        end_margin: 0.0,
    }
}
