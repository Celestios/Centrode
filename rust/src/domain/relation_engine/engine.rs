use std::collections::HashMap;

use super::buffers::RelationBuffers;
use super::computed::{ComputedRelation, LabelAnchor, PathType};
use super::config::{BodyType, EndpointShapeType, RelationEngineConfig};

use super::geometry::{Point, Rect};
use super::input::{InputEdge, InputNode, resolve_edge_ports_full, compute_extension};
use crate::domain::patches::{EntityPatch, NodePatch};
use super::label::compute_label_position;
use super::routing::{resolve_strategy, compute_bbox};
use super::state::incremental::IncrementalState;
use super::sections::body as section_body;
use super::state::CanvasState;
use super::state::cache::RelationCache;
use super::pipeline::{PipelinePass, RoutingPass, FinalizePass};

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

        let obstacles: Vec<Rect> = nodes.iter()
            .filter(|n| n.is_obstacle)
            .map(|n| n.rect())
            .collect();

        let edges_to_compute: Vec<&InputEdge> = if let Some(ids) = relation_ids {
            edges.iter().filter(|e| ids.contains(&e.id)).collect()
        } else {
            edges.iter().collect()
        };

        let mut results = Vec::with_capacity(edges_to_compute.len());

        let passes: Vec<Box<dyn PipelinePass>> = vec![
                    Box::new(RoutingPass),
                                        // Box::new(ResolutionPass), // INTENTIONALLY DISABLED — do not uncomment without Shahin's approval
                                        Box::new(FinalizePass),
                ];

        for pass in passes {
            pass.run(
                self,
                &mut results,
                &edges_to_compute,
                &node_map,
                &obstacles,
                config,
            );
        }

        // Update cache with final computed/processed routes
        for result in &results {
            self.cache.insert(result.id.clone(), result.clone());
            self.state.relations.insert(result.id.clone(), result.clone());
            self.state.incremental.clear_dirty_id(&result.id);
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

    pub(crate) fn finalize_relation(
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

        let is_orthogonal = result.path_type == crate::domain::relation_engine::computed::PathType::Orthogonal;

        if let Some(node) = from_node {
            let ep = super::sections::endpoint::resolve_start(node, start_port, start_tangent, style, config, is_orthogonal);
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
            let ep = super::sections::endpoint::resolve_end(node, end_port, end_tangent, style, config, is_orthogonal);
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
            arrow_size * start_scale * 0.5
        } else {
            0.0
        };
        let end_margin = if result.end_endpoint != EndpointShapeType::None {
            arrow_size * end_scale * 0.5
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
        result.start_arrow_center = result.path_points.first().copied().unwrap_or(Point::zero());
        result.end_arrow_center = result.path_points.last().copied().unwrap_or(Point::zero());
        result.start_point = untrimmed_path.first().copied().unwrap_or(Point::zero());
        result.end_point = untrimmed_path.last().copied().unwrap_or(Point::zero());
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

    pub(crate) fn compute_single_relation(
        &mut self,
        edge: &InputEdge,
        node_map: &HashMap<&str, &InputNode>,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) -> ComputedRelation {
        if !node_map.contains_key(edge.from_node_id.as_str()) || !node_map.contains_key(edge.to_node_id.as_str()) {
            return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id);
        }

        let from_node = node_map[edge.from_node_id.as_str()];
        let to_node = node_map[edge.to_node_id.as_str()];
        let routing_mode = edge.routing_mode.unwrap_or(config.routing.routing_mode);
        let extension = compute_extension(from_node, to_node, config.routing.grid_size, config.routing.extension_min, config.routing.extension_scale);

        let ports = match resolve_edge_ports_full(edge, node_map, routing_mode, extension) {
            Some(p) => p,
            None => return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id),
        };

        let mut full_obstacles = obstacles.to_vec();
        full_obstacles.push(from_node.rect());
        full_obstacles.push(to_node.rect());

        let strategy = resolve_strategy(routing_mode);
        let (path_points, path_type) = strategy.route_full(&ports, &full_obstacles, config);

        let body_strategy_str = edge.style.as_ref().map(|s| s.body_strategy.as_str()).unwrap_or("");
        let body_type = match body_strategy_str {
            "uniform" => BodyType::Uniform,
            "taper" => BodyType::Taper,
            "widthModulate" => BodyType::WidthModulate,
            "bundled" => BodyType::Bundled,
            _ => config.body.default_type,
        };

        let mut result = ComputedRelation {
            id: edge.id.clone(),
            path_points: path_points.clone(),
            path_type,
            start_tangent: Point::new(1.0, 0.0),
            end_tangent: Point::new(1.0, 0.0),
            body_widths: Vec::new(),
            body_type,
            start_endpoint: EndpointShapeType::None,
            end_endpoint: EndpointShapeType::None,
            start_direction: 0.0,
            end_direction: 0.0,
            label_position: Point::zero(),
            label_anchor: LabelAnchor::Center,
            bundle_id: None,
            bundle_offset: None,
            hit_test_points: Vec::new(),
            depends_on_nodes: vec![edge.from_node_id.clone(), edge.to_node_id.clone()],
            bbox: Rect::new(0.0, 0.0, 0.0, 0.0),
            start_margin: 0.0,
            end_margin: 0.0,
            start_arrow_center: Point::zero(),
            end_arrow_center: Point::zero(),
            start_point: Point::zero(),
            end_point: Point::zero(),
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
        start_arrow_center: Point::zero(),
        end_arrow_center: Point::zero(),
        start_point: Point::zero(),
        end_point: Point::zero(),
    }
}
