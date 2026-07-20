use std::collections::{HashMap, HashSet};
use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::types::{InputNode, InputEdge};
use crate::domain::relation_engine::config::{RelationEngineConfig, RoutingConfig, RoutingMode, BundlingMode};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::state::{CanvasState, RelationCache};
use crate::domain::relation_engine::path_finder::steer::{AStarContext, CostGrid};
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

    pub fn update_node_cache(&mut self, node: InputNode, margin: f64) {
        self.state.update_node(node, margin);
    }

    pub fn compute_relations(
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        relation_ids: Option<&[String]>,
    ) -> Vec<ComputedRelation> {
        let mut engine = Self::new();
        engine.compute_relations_stateful(nodes, edges, config, relation_ids)
    }


    pub fn compute_relations_stateful(
        &mut self,
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        relation_ids: Option<&[String]>,
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
        for node in nodes {
            self.state.update_node(node.clone(), margin);
        }

        // 3. Build node_map and obstacles
        let mut node_map = HashMap::new();
        for node in nodes {
            node_map.insert(node.id.clone(), node.clone());
        }
        let obstacles: Vec<InputNode> = nodes.iter().filter(|n| n.is_obstacle).cloned().collect();

        // 4. Filter edges by relation_ids if specified
        let mut edges_to_compute = edges.to_vec();
        if let Some(ids) = relation_ids {
            let id_set: HashSet<&String> = ids.iter().collect();
            edges_to_compute.retain(|e| id_set.contains(&e.id));
        }

        // 5. RoutingPass
        let mut results = Vec::with_capacity(edges_to_compute.len());
        let mut miss_indices = Vec::new();
        let mut miss_edges = Vec::new();

        for (i, edge) in edges_to_compute.iter().enumerate() {
            let cached = if !self.state.incremental.dirty_relations.contains(&edge.id) {
                self.cache.get(&edge.id).cloned()
            } else {
                None
            };

            if let Some(res) = cached {
                results.push(res);
            } else {
                results.push(ComputedRelation::new_basic(edge.id.clone(), vec![], PathType::Straight));
                miss_indices.push(i);
                miss_edges.push(edge);
            }
        }

        if !miss_edges.is_empty() {
            use rayon::prelude::*;
            let computed: Vec<ComputedRelation> = miss_edges
                .par_iter()
                .map(|edge| {
                    compute_single_relation(edge, &node_map, &obstacles, config)
                })
                .collect();

            for (computed_res, &i) in computed.into_iter().zip(&miss_indices) {
                let edge_id = &edges_to_compute[i].id;
                self.cache.insert(edge_id.clone(), computed_res.clone());
                self.state.relations.insert(edge_id.clone(), computed_res.clone());
                self.state.incremental.clear_dirty_id(edge_id);
                results[i] = computed_res;
            }
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
        nodes: &[InputNode],
        edges: &[InputEdge],
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

        self.compute_relations_stateful(nodes, edges, config, Some(&dirty_ids))
    }

    pub fn apply_cache_patch(&mut self, id: &str, patch: &crate::domain::patches::EntityPatch, margin: f64) {
        use crate::domain::patches::{EntityPatch, NodePatch};
        match patch {
            EntityPatch::Node(patches) => {
                if let Some(mut node) = self.state.nodes.get(id).cloned() {
                    for p in patches {
                        match p {
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
            }
            EntityPatch::CreateNode(node_val, _) => {
                if let Some(input_node) = InputNode::from_domain(node_val) {
                    self.state.update_node(input_node, margin);
                }
            }
            EntityPatch::DeleteNode(node_val, _) => {
                use crate::domain::nodes::IsNode;
                self.state.remove_node(node_val.key());
            }
            _ => {}
        }
    }
}

const GRID_MARGIN_EXTRA: f64 = 100.0;

fn build_grid(nodes: &[InputNode], config: &RoutingConfig, start: Point, end: Point) -> Grid {
    let margin = config.margin();
    let cell = config.cell_size();
    let mut min_x = start.x.min(end.x);
    let mut min_y = start.y.min(end.y);
    let mut max_x = start.x.max(end.x);
    let mut max_y = start.y.max(end.y);
    for n in nodes {
        min_x = min_x.min(n.x);
        min_y = min_y.min(n.y);
        max_x = max_x.max(n.x + n.width);
        max_y = max_y.max(n.y + n.height);
    }
    min_x -= margin + GRID_MARGIN_EXTRA;
    min_y -= margin + GRID_MARGIN_EXTRA;
    max_x += margin + GRID_MARGIN_EXTRA;
    max_y += margin + GRID_MARGIN_EXTRA;
    let w = ((max_x - min_x) / cell).ceil() as usize;
    let h = ((max_y - min_y) / cell).ceil() as usize;
    Grid::new(min_x, min_y, w, h, cell)
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
        RoutingMode::Orthogonal | RoutingMode::BSpline => {
            let grid = build_grid(obstacles, &config.routing, resolved.start_exit, resolved.end_exit);
            let cost_grid = CostGrid::new(&grid, obstacles, config.routing.outer_bbox_distance());
            let context = AStarContext {
                grid: &grid,
                nodes: obstacles,
                start_node_id: &edge.from_node_id,
                end_node_id: &edge.to_node_id,
                start_pt: resolved.start,
                start_terminus: resolved.start_exit,
                start_dir: resolved.start_normal.map(|n| (n.x.round() as i32, n.y.round() as i32)),
                use_start_penalty: true,
                start_stub_len: start_ext,
                end_pt: resolved.end,
                end_terminus: resolved.end_exit,
                end_dir: resolved.end_normal.map(|n| (n.x.round() as i32, n.y.round() as i32)),
                use_end_penalty: true,
                end_stub_len: end_ext,
                outer_bbox_distance: config.routing.outer_bbox_distance(),
                port_penalty: config.routing.port_penalty(),
                cost_grid: &cost_grid,
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
        RoutingMode::Orthogonal => {
            let shaper = OrthogonalShaper::new(config.routing.clone());
            shaper.shape(&raw_path, &shaper_ctx)
        }
        RoutingMode::BSpline => {
            let shaper = BSplineShaper::new(config.routing.clone());
            shaper.shape(&raw_path, &shaper_ctx)
        }
    };

    result.id = edge.id.clone();
    result
}
