use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::input::{ResolvedPorts, Side};
use super::{RoutingStrategy, TransitionInput};

pub struct PolylineRouting;

impl RoutingStrategy for PolylineRouting {
    fn compute_transition(
        &self,
        input: &TransitionInput,
        _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        match input.side {
            Side::Start => {
                if input.stub_exit.distance_to(input.body_start) < 1.0 { vec![] } else { vec![input.body_start] }
            }
            Side::End => {
                if input.body_end.distance_to(input.stub_entry) < 1.0 { vec![] } else { vec![input.stub_entry] }
            }
        }
    }

    // Polyline is a straight-line fallback — ignores obstacles intentionally
    fn compute_obstacle_waypoints(
        &self, from: Point, to: Point, _obstacles: &[Rect], _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        vec![from, to]
    }

    fn compute_body(
        &self, waypoints: &[Point], _ports: &ResolvedPorts, _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        waypoints.to_vec()
    }

    fn path_type(&self) -> PathType { PathType::Straight }
}