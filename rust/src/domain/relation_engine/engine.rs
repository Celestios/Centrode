use std::collections::HashMap;

use super::body::compute_body_widths;
use super::bundling::{bundle_edges, BundlingStrategy};
use super::computed::{ComputedRelation, LabelAnchor, PathType};
use super::config::{BodyType, EndpointShapeType, RelationEngineConfig};
use super::crossing::minimize_crossings;
use super::endpoint::{compute_endpoints, compute_tangents};
use super::geometry::{Point, Rect};
use super::incremental::IncrementalState;
use super::input::{InputEdge, InputNode};
use super::label::compute_label_position;
use super::nudging::{nudge_edges, NudgeConfig};
use super::routing::{compute_bbox, route_relation};

pub struct RelationEngine;

impl RelationEngine {
    pub fn compute_relations(
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        relation_ids: Option<&[String]>,
    ) -> Vec<ComputedRelation> {
        let node_map: HashMap<&str, &InputNode> =
            nodes.iter().map(|n| (n.id.as_str(), n)).collect();

        let obstacles: Vec<Rect> = nodes.iter().map(|n| n.rect()).collect();

        let edges_to_compute: Vec<&InputEdge> = if let Some(ids) = relation_ids {
            edges.iter().filter(|e| ids.contains(&e.id)).collect()
        } else {
            edges.iter().collect()
        };

        // Phase 1: Route each edge individually
        let mut results: Vec<ComputedRelation> = edges_to_compute
            .iter()
            .map(|edge| compute_single_relation(edge, &node_map, &obstacles, config))
            .collect();

        // Phase 2: Bundle edges sharing endpoints or proximity
        let bundling_strategy = match config.bundling.mode {
            super::config::BundlingMode::SharedEndpoint => BundlingStrategy::SharedEndpoint,
            super::config::BundlingMode::Proximity => BundlingStrategy::Proximity {
                threshold: config.bundling.threshold,
            },
            super::config::BundlingMode::None => BundlingStrategy::None,
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

            for result in &mut results {
                // Find the reordered path for this result
                if let Some(idx) = reordered_ids.iter().position(|rid| rid == &result.id) {
                    result.path_points = paths[idx].clone();
                    let (start_tangent, end_tangent) = compute_tangents(&result.path_points);
                    result.start_tangent = start_tangent;
                    result.end_tangent = end_tangent;

                    let (start_shape, start_dir, end_shape, end_dir) =
                        compute_endpoints(start_tangent, end_tangent, config);
                    result.start_endpoint = start_shape;
                    result.start_direction = start_dir;
                    result.end_endpoint = end_shape;
                    result.end_direction = end_dir;

                    result.body_widths = compute_body_widths(
                        &result.path_points,
                        &result.body_type,
                        2.0,
                        config,
                    );
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

        results
    }

    /// Compute relations with incremental invalidation.
    ///
    /// Uses the incremental state to determine which relations need recomputation.
    /// Returns only the changed relations.
    pub fn compute_incremental(
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

        let results = Self::compute_relations(
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
}

fn compute_single_relation(
    edge: &InputEdge,
    node_map: &HashMap<&str, &InputNode>,
    obstacles: &[Rect],
    config: &RelationEngineConfig,
) -> ComputedRelation {
    if !node_map.contains_key(edge.from_node_id.as_str()) || !node_map.contains_key(edge.to_node_id.as_str()) {
        return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id);
    }

    let (path_points, path_type) = route_relation(edge, node_map, obstacles, config);

    let (start_tangent, end_tangent) = compute_tangents(&path_points);
    let (start_shape, start_dir, end_shape, end_dir) =
        compute_endpoints(start_tangent, end_tangent, config);

    let body_type = config.body.default_type;
    let base_width = 2.0;
    let body_widths = compute_body_widths(&path_points, &body_type, base_width, config);

    let (label_pos, _) = compute_label_position(&path_points, &path_type, config);

    let depends_on_nodes = vec![
        edge.from_node_id.clone(),
        edge.to_node_id.clone(),
    ];

    let bbox = compute_bbox(&path_points);

    ComputedRelation {
        id: edge.id.clone(),
        path_points,
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
    }
}
