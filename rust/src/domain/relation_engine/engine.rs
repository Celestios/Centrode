use std::collections::{HashMap, HashSet};
use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::types::{InputNode, InputEdge};
use crate::domain::relation_engine::config::{RelationEngineConfig, RoutingConfig, RoutingMode, BundlingMode};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::state::{CanvasState, RelationCache};
use crate::domain::relation_engine::path_finder::steer::AStarContext;
use crate::domain::relation_engine::path_finder::grid::Grid;
use crate::domain::relation_engine::path_finder::orthogonal::OrthogonalSteer;
use crate::domain::relation_engine::path_finder::bspline::BSplineSteer;
use crate::domain::relation_engine::path_finder::core::a_star;
use crate::domain::relation_engine::path_finder::port::{resolve_ports_full, compute_extension};
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext};
use crate::domain::relation_engine::shaper::straight::StraightShaper;
use crate::domain::relation_engine::shaper::bezier::BezierShaper;
use crate::domain::relation_engine::shaper::orthogonal::OrthogonalShaper;
use crate::domain::relation_engine::shaper::bspline::BSplineShaper;

pub struct RelationEngine {
    pub state: CanvasState,
    pub cache: RelationCache,
}

impl RelationEngine {
    pub fn new() -> Self {
        Self {
            state: CanvasState::new(),
            cache: RelationCache::new(),
        }
    }

    pub fn compute_relations_stateful(
        &mut self,
        nodes: Vec<InputNode>,
        edges: Vec<InputEdge>,
        config: &RelationEngineConfig,
        relation_ids: Option<Vec<String>>,
    ) -> Vec<ComputedRelation> {
        let margin = config.routing.obstacle_margin;

        // 1. Sync removed nodes
        let incoming_node_ids: HashSet<String> = nodes.iter().map(|n| n.id.clone()).collect();
        let current_node_ids: Vec<String> = self.state.nodes.keys().cloned().collect();
        for id in current_node_ids {
            if !incoming_node_ids.contains(&id) {
                self.state.remove_node(&id);
            }
        }

        // 2. Sync updated/added nodes
        for node in &nodes {
            self.state.update_node(node.clone(), margin);
        }

        // 3. Build node_map and obstacles
        let mut node_map = HashMap::new();
        for node in &nodes {
            node_map.insert(node.id.clone(), node.clone());
        }
        let obstacles: Vec<InputNode> = nodes.iter().filter(|n| n.is_obstacle).cloned().collect();

        // 4. Filter edges by relation_ids if specified
        let mut edges_to_compute = edges;
        if let Some(ref ids) = relation_ids {
            let id_set: HashSet<&String> = ids.iter().collect();
            edges_to_compute.retain(|e| id_set.contains(&e.id));
        }

        // 5. RoutingPass
        let mut results = Vec::new();
        for edge in &edges_to_compute {
            let cached = if !self.state.incremental.dirty_relations.contains(&edge.id) {
                self.cache.get(&edge.id).cloned()
            } else {
                None
            };

            let computed = match cached {
                Some(res) => res,
                None => {
                    let res = compute_single_relation(edge, &node_map, &obstacles, config);
                    self.cache.insert(edge.id.clone(), res.clone());
                    self.state.relations.insert(edge.id.clone(), res.clone());
                    self.state.incremental.clear_dirty_id(&edge.id);
                    res
                }
            };
            results.push(computed);
        }

        // 6. ResolutionPass (Nudging / Spacing)
        if config.nudging.enabled && results.len() >= 2 {
            let mut paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let configs: Vec<RoutingConfig> = edges_to_compute.iter().map(|_| config.routing.clone()).collect();
            let nudge_colors = crate::domain::relation_engine::compose::compose(&mut paths, &configs, &config.nudging, &obstacles);
            for i in 0..results.len() {
                results[i].path_points = paths[i].clone();
                results[i].nudge_colors = nudge_colors[i].clone();
            }
        }

        // 7. FinalizePass
        for i in 0..results.len() {
            let edge = &edges_to_compute[i];
            crate::domain::relation_engine::finalize::finalize_relation(&mut results[i], edge, &node_map, config);
            
            self.cache.insert(results[i].id.clone(), results[i].clone());
            self.state.relations.insert(results[i].id.clone(), results[i].clone());
            self.state.incremental.register(results[i].id.clone(), results[i].depends_on_nodes.clone(), results[i].bbox);
        }

        results
    }

    pub fn compute_incremental_stateful(
        &mut self,
        nodes: Vec<InputNode>,
        edges: Vec<InputEdge>,
        config: &RelationEngineConfig,
    ) -> Vec<ComputedRelation> {
        if !self.state.incremental.has_dirty() {
            return Vec::new();
        }

        let margin = config.routing.obstacle_margin;

        let mut dirty_node_positions = HashMap::new();
        for node_id in &self.state.incremental.dirty_nodes {
            if let Some(node) = self.state.nodes.get(node_id) {
                dirty_node_positions.insert(node_id.clone(), node.bounding_box());
            }
        }

        let dirty_ids = self.state.incremental.dirty_relation_ids(&dirty_node_positions, margin);
        self.state.incremental.clear_dirty();

        if dirty_ids.is_empty() {
            return Vec::new();
        }

        self.compute_relations_stateful(nodes, edges, config, Some(dirty_ids))
    }
}

pub fn compute_single_relation(
    edge: &InputEdge,
    node_map: &HashMap<String, InputNode>,
    obstacles: &[InputNode],
    config: &RelationEngineConfig,
) -> ComputedRelation {
    let from_node = match node_map.get(&edge.from_node_id) {
        Some(n) => n,
        None => return ComputedRelation::new_basic(edge.id.clone(), vec![Point::new(0.0, 0.0), Point::new(0.0, 0.0)], PathType::Straight),
    };
    let to_node = match node_map.get(&edge.to_node_id) {
        Some(n) => n,
        None => return ComputedRelation::new_basic(edge.id.clone(), vec![Point::new(0.0, 0.0), Point::new(0.0, 0.0)], PathType::Straight),
    };

    let mode = edge.routing_mode.clone().unwrap_or(config.routing.routing_mode.clone());

    let (start_ext, end_ext) = (
        compute_extension(from_node, config.routing.extension_min, config.routing.extension_scale),
        compute_extension(to_node, config.routing.extension_min, config.routing.extension_scale),
    );

    let resolved = match resolve_ports_full(edge, node_map, &mode, start_ext, end_ext) {
        Some(r) => r,
        None => return ComputedRelation::new_basic(edge.id.clone(), vec![Point::new(0.0, 0.0), Point::new(0.0, 0.0)], PathType::Straight),
    };

    let raw_path = match mode {
        RoutingMode::Polyline => {
            vec![resolved.start, resolved.end]
        }
        RoutingMode::CircularArc | RoutingMode::SineWave => {
            vec![resolved.start, resolved.end]
        }
        RoutingMode::Orthogonal | RoutingMode::BSpline => {
            let cell_size = config.routing.cell_size();
            let grid = Grid::new(resolved.start_exit, resolved.end_exit, cell_size);
            let context = AStarContext {
                grid: &grid,
                start_terminus: resolved.start_exit,
                end_terminus: resolved.end_exit,
                start_pt: resolved.start,
                end_pt: resolved.end,
                start_dir: resolved.start_normal.map(|n| (n.x.round() as i32, n.y.round() as i32)),
                end_dir: resolved.end_normal.map(|n| (n.x.round() as i32, n.y.round() as i32)),
                start_stub_len: start_ext,
                end_stub_len: end_ext,
                outer_bbox_distance: config.routing.outer_bbox_distance(),
                nodes: obstacles,
            };

            let path = match mode {
                RoutingMode::Orthogonal => {
                    let steer = OrthogonalSteer::new(config.routing.clone());
                    a_star(&steer, &context)
                }
                RoutingMode::BSpline => {
                    let steer = BSplineSteer::new(config.routing.clone());
                    a_star(&steer, &context)
                }
                _ => unreachable!(),
            };

            match path {
                Some(p) => p,
                None => vec![resolved.start_exit, resolved.end_exit],
            }
        }
    };

    let shaper_ctx = ShaperContext {
        start_pt: resolved.start,
        end_pt: resolved.end,
        start_dir: resolved.start_normal.map(|n| (n.x.round() as i32, n.y.round() as i32)),
        end_dir: resolved.end_normal.map(|n| (n.x.round() as i32, n.y.round() as i32)),
        start_stub_len: start_ext,
        end_stub_len: end_ext,
        cell_size: config.routing.cell_size(),
    };

    let mut result = match mode {
        RoutingMode::Polyline => {
            let shaper = StraightShaper::new(config.routing.straight_config());
            shaper.shape(&raw_path, &shaper_ctx)
        }
        RoutingMode::CircularArc => {
            let shaper = BezierShaper::new(config.routing.bezier_config());
            shaper.shape(&raw_path, &shaper_ctx)
        }
        RoutingMode::Orthogonal => {
            let shaper = OrthogonalShaper::new(config.routing.clone());
            shaper.shape(&raw_path, &shaper_ctx)
        }
        RoutingMode::BSpline => {
            let shaper = BSplineShaper::new(config.routing.clone());
            shaper.shape(&raw_path, &shaper_ctx)
        }
        RoutingMode::SineWave => {
            let shaper = StraightShaper::new(config.routing.straight_config());
            let mut res = shaper.shape(&raw_path, &shaper_ctx);
            res.path_type = PathType::SineWave;
            res
        }
    };

    result.id = edge.id.clone();
    result
}
