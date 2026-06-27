use std::collections::HashMap;

use super::bundling::{bundle_edges, BundlingStrategy};
use super::buffers::RelationBuffers;
use super::computed::{ComputedRelation, LabelAnchor, PathType};
use super::config::{BodyType, EndpointShapeType, RelationEngineConfig, BundlingMode};
use super::crossing::minimize_crossings;
use super::endpoint::{compute_endpoints, compute_tangents};
use super::geometry::{Point, Rect};
use super::incremental::IncrementalState;
use super::input::{InputEdge, InputNode};
use super::label::compute_label_position;
use super::nudging::{nudge_edges, NudgeConfig};
use super::routing::{compute_bbox, route_relation};
use super::sections::compute_sections;
use super::section_body;
use super::state::CanvasState;
use super::cache::RelationCache;

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

        let bundling_strategy = if has_bundled_edges || config.bundling.mode != BundlingMode::None {
            let mode = if has_bundled_edges {
                edges_to_compute.iter()
                    .filter_map(|e| e.bundling_mode)
                    .find(|m| *m != BundlingMode::None)
                    .unwrap_or(config.bundling.mode)
            } else {
                config.bundling.mode
            };

            match mode {
                BundlingMode::SharedEndpoint => BundlingStrategy::SharedEndpoint,
                BundlingMode::Proximity => BundlingStrategy::Proximity {
                    threshold: config.bundling.threshold,
                },
                BundlingMode::None => BundlingStrategy::None,
            }
        } else {
            BundlingStrategy::None
        };

        if !matches!(bundling_strategy, BundlingStrategy::None) && results.len() >= 2 {
            let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();
            let from_ids: Vec<String> = edges_to_compute.iter().map(|e| e.from_node_id.clone()).collect();
            let to_ids: Vec<String> = edges_to_compute.iter().map(|e| e.to_node_id.clone()).collect();

            let bundling_result = bundle_edges(
                &edge_ids,
                &paths,
                &from_ids,
                &to_ids,
                &bundling_strategy,
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
                // Find the reordered path for this result
                if let Some(idx) = reordered_ids.iter().position(|rid| rid == &result.id) {
                    let untrimmed_path = paths[idx].clone();
                    let start_port = untrimmed_path.first().copied().unwrap_or(Point::zero());
                    let end_port = untrimmed_path.last().copied().unwrap_or(Point::zero());
                    let (start_tangent, end_tangent) = compute_tangents(&untrimmed_path);
                    result.start_tangent = start_tangent;
                    result.end_tangent = end_tangent;

                    let edge = edge_map.get(result.id.as_str()).copied();
                    let style = edge.and_then(|e| e.style.as_ref());
                    let from_node = edge.and_then(|e| node_map.get(e.from_node_id.as_str()).copied());
                    let to_node = edge.and_then(|e| node_map.get(e.to_node_id.as_str()).copied());

                    let (start_shape, start_dir, end_shape, end_dir) =
                        compute_endpoints(
                            start_tangent,
                            end_tangent,
                            config,
                            style,
                            from_node,
                            to_node,
                            start_port,
                            end_port,
                        );
                    result.start_endpoint = start_shape;
                    result.start_direction = start_dir;
                    result.end_endpoint = end_shape;
                    result.end_direction = end_dir;

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

                    let start_margin = if start_shape != EndpointShapeType::None {
                        arrow_size * start_scale
                    } else {
                        0.0
                    };
                    let end_margin = if end_shape != EndpointShapeType::None {
                        arrow_size * end_scale
                    } else {
                        0.0
                    };

                    result.path_points = super::painting::relation::trim_path(&untrimmed_path, start_margin, end_margin);

                    self.buffers.widths.clear();
                    let _body_result = section_body::compute_widths(
                        &result.path_points,
                        result.body_type,
                        stroke_width,
                        config,
                        &mut self.buffers.widths,
                    );
                    result.body_widths = self.buffers.widths.clone();
                    let (label_pos, _) = compute_label_position(
                        &result.path_points,
                        &result.path_type,
                        config,
                    );
                    result.label_position = label_pos;
                    result.bbox = compute_bbox(&result.path_points);
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

        let (start_tangent, end_tangent) = compute_tangents(&path_points);

        let s = sectioned.as_ref().expect("compute_sections returns None only when nodes are missing, which is handled above");
        let start_shape = s.tail_start.endpoint.shape;
        let start_dir = s.tail_start.endpoint.direction;
        let end_shape = s.tail_end.endpoint.shape;
        let end_dir = s.tail_end.endpoint.direction;

        let stroke_width = edge.style.as_ref().map(|s| s.stroke_width as f64).unwrap_or(2.0);
        let arrow_size = edge.style.as_ref().map(|s| s.arrow_size).unwrap_or(config.endpoint.arrow_size);

        let body_strategy_str = edge.style.as_ref().map(|s| s.body_strategy.as_str()).unwrap_or("");
        let body_type = match body_strategy_str {
            "uniform" => BodyType::Uniform,
            "taper" => BodyType::Taper,
            "widthModulate" => BodyType::WidthModulate,
            "bundled" => BodyType::Bundled,
            _ => config.body.default_type,
        };

        let start_width = match body_type {
            BodyType::Taper => config.body.taper_start_width,
            _ => stroke_width,
        };
        let end_width = match body_type {
            BodyType::Taper => config.body.taper_end_width,
            _ => stroke_width,
        };

        let start_scale = if start_width > 0.0 { start_width / 2.0 } else { 1.0 };
        let end_scale = if end_width > 0.0 { end_width / 2.0 } else { 1.0 };

        let start_margin = if start_shape != EndpointShapeType::None {
            arrow_size * start_scale
        } else {
            0.0
        };
        let end_margin = if end_shape != EndpointShapeType::None {
            arrow_size * end_scale
        } else {
            0.0
        };

        let trimmed_path = super::painting::relation::trim_path(&path_points, start_margin, end_margin);

        self.buffers.widths.clear();
        let _body_result = section_body::compute_widths(
            &trimmed_path,
            body_type,
            stroke_width,
            config,
            &mut self.buffers.widths,
        );
        let body_widths = self.buffers.widths.clone();

        let (label_pos, _) = compute_label_position(&trimmed_path, &path_type, config);

        let depends_on_nodes = vec![
            edge.from_node_id.clone(),
            edge.to_node_id.clone(),
        ];

        let bbox = compute_bbox(&trimmed_path);

        ComputedRelation {
            id: edge.id.clone(),
            path_points: trimmed_path,
            path_type,
            start_tangent,
            end_tangent,
            body_widths,
            body_type,
            start_endpoint: start_shape,
            end_endpoint: end_shape,
            start_direction: start_dir,
            end_direction: end_dir,
            label_position: label_pos,
            label_anchor: LabelAnchor::Center,
            bundle_id: None,
            bundle_offset: None,
            hit_test_points: Vec::new(),
            depends_on_nodes,
            bbox,
            start_margin,
            end_margin,
        }
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
