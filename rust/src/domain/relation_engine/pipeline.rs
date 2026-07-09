use std::collections::HashMap;
use super::computed::ComputedRelation;
use super::config::RelationEngineConfig;
use super::engine::RelationEngine;
use super::input::{InputEdge, InputNode};
use super::geometry::{Point, Rect};
use super::bundling::bundle_edges;
use super::nudging::{nudge_edges, NudgeConfig};
use super::crossing::minimize_crossings;
use super::routing::compute_bbox;
use super::config::BundlingMode;

pub trait PipelinePass {
    fn run(
        &self,
        engine: &mut RelationEngine,
        results: &mut Vec<ComputedRelation>,
        edges_to_compute: &[&InputEdge],
        node_map: &HashMap<&str, &InputNode>,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
    );
}

pub struct RoutingPass;

impl PipelinePass for RoutingPass {
    fn run(
        &self,
        engine: &mut RelationEngine,
        results: &mut Vec<ComputedRelation>,
        edges_to_compute: &[&InputEdge],
        node_map: &HashMap<&str, &InputNode>,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) {
        for edge in edges_to_compute {
            let edge = *edge;
            if let Some(cached) = engine.cache.get(&edge.id) {
                if !engine.state.incremental.is_dirty(&edge.id) {
                    results.push(cached.clone());
                    continue;
                }
            }

            let computed = engine.compute_single_relation(edge, node_map, obstacles, config);
            engine.cache.insert(edge.id.clone(), computed.clone());
            engine.state.relations.insert(edge.id.clone(), computed.clone());
            engine.state.incremental.clear_dirty_id(&edge.id);
            results.push(computed);
        }
    }
}

pub struct ResolutionPass;

impl PipelinePass for ResolutionPass {
    fn run(
        &self,
        _engine: &mut RelationEngine,
        results: &mut Vec<ComputedRelation>,
        edges_to_compute: &[&InputEdge],
        _node_map: &HashMap<&str, &InputNode>,
        _obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) {
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

            for result in results.iter_mut() {
                if let Some((bundle_id, offset)) = bundling_result.edge_assignments.get(&result.id) {
                    result.bundle_id = Some(bundle_id.clone());
                    result.bundle_offset = Some(*offset);
                }
            }
        }

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

            for (i, result) in results.iter_mut().enumerate() {
                result.path_points = paths[i].clone();
                result.bbox = compute_bbox(&result.path_points);
            }
        }

        if config.crossing_minimization && results.len() >= 2 {
            let mut paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();

            let reordered_ids = minimize_crossings(&mut paths, &edge_ids, 20);

            let mut id_to_result: HashMap<String, ComputedRelation> =
                std::mem::take(results).into_iter().map(|r| (r.id.clone(), r)).collect();

            *results = reordered_ids
                .iter()
                .filter_map(|id| id_to_result.remove(id))
                .collect();
        }
    }
}

pub struct FinalizePass;

impl PipelinePass for FinalizePass {
    fn run(
        &self,
        engine: &mut RelationEngine,
        results: &mut Vec<ComputedRelation>,
        edges_to_compute: &[&InputEdge],
        node_map: &HashMap<&str, &InputNode>,
        _obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) {
        for (i, result) in results.iter_mut().enumerate() {
            let edge = edges_to_compute.get(i).copied();
            engine.finalize_relation(result, &result.path_points.clone(), edge, node_map, config);
        }
    }
}
