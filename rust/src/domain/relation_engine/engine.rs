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
                    Box::new(RoutingPass {}),
                                        // Box::new(ResolutionPass), // INTENTIONALLY DISABLED — do not uncomment without Shahin's approval
                                        Box::new(FinalizePass {}),
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
        path: &[Point],
        edge: Option<&InputEdge>,
        node_map: &HashMap<&str, &InputNode>,
        config: &RelationEngineConfig,
    ) {
        let (start_tangent, end_tangent) = super::geometry::compute_tangents(path);
        result.start_tangent = start_tangent;
        result.end_tangent = end_tangent;

        let style = edge.and_then(|e| e.style.as_ref());
        let from_node = edge.and_then(|e| node_map.get(e.from_node_id.as_str()).copied());
        let to_node = edge.and_then(|e| node_map.get(e.to_node_id.as_str()).copied());

        let start_port = if let Some(node) = from_node {
            let to_center = to_node.map(|n| n.center()).unwrap_or(Point::zero());
            match edge.and_then(|e| e.from_side.as_ref()) {
                Some(side) => node.resolve_port(side, to_center).position,
                None => node.closest_port_to(to_center).position,
            }
        } else {
            path.first().copied().unwrap_or(Point::zero())
        };
        let end_port = if let Some(node) = to_node {
            let from_center = from_node.map(|n| n.center()).unwrap_or(Point::zero());
            match edge.and_then(|e| e.to_side.as_ref()) {
                Some(side) => node.resolve_port(side, from_center).position,
                None => node.closest_port_to(from_center).position,
            }
        } else {
            path.last().copied().unwrap_or(Point::zero())
        };

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

        result.path_points = path.to_vec();

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
        result.start_margin = 0.0;
        result.end_margin = 0.0;
        result.start_arrow_center = start_port - start_tangent * (arrow_size * 0.5);
        result.end_arrow_center = end_port - end_tangent * (arrow_size * 0.5);
        result.start_point = path.first().copied().unwrap_or(Point::zero());
        result.end_point = path.last().copied().unwrap_or(Point::zero());
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
        let start_extension = compute_extension(from_node, config.routing.extension_min, config.routing.extension_scale);
        let end_extension = compute_extension(to_node, config.routing.extension_min, config.routing.extension_scale);

        let ports = match resolve_edge_ports_full(edge, node_map, routing_mode, start_extension, end_extension) {
            Some(p) => p,
            None => return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id),
        };

        let mut full_obstacles: Vec<Rect> = obstacles.iter()
            .filter(|r| **r != from_node.rect() && **r != to_node.rect())
            .copied()
            .collect();

        let strategy = resolve_strategy(routing_mode);
        let (path_points, path_type) = strategy.route_full(&ports, &full_obstacles, config);

        eprintln!("=== Relation: {} ===", edge.id);
        eprintln!("  start_ext: {:.1}  end_ext: {:.1}", start_extension, end_extension);
        eprintln!("  start: ({:.1}, {:.1})  end: ({:.1}, {:.1})", ports.start.position.x, ports.start.position.y, ports.end.position.x, ports.end.position.y);
        eprintln!("  start_exit: ({:.1}, {:.1})  end_exit: ({:.1}, {:.1})", ports.start_exit.x, ports.start_exit.y, ports.end_exit.x, ports.end_exit.y);
        eprintln!("  path_type: {:?}", path_type);
        eprintln!("  points ({}):", path_points.len());
        for (i, p) in path_points.iter().enumerate() {
            eprintln!("    [{:3}] ({:.1}, {:.1})", i, p.x, p.y);
        }
        eprintln!("");

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
