pub mod polyline;
pub mod orthogonal;
pub mod bezier;
pub mod circular_arc;
pub mod sine_wave;

use super::geometry::{Point, Rect};
use super::config::{RelationEngineConfig, RoutingMode};
use super::computed::PathType;
use super::input::{ResolvedPorts, Side};

#[derive(Debug, Clone, Copy)]
pub struct TransitionInput {
    pub side: Side,
    pub stub_exit: Point,
    pub stub_entry: Point,
    pub start_normal: Point,
    pub end_normal: Point,
    pub body_start: Point,
    pub body_end: Point,
}

pub trait RoutingStrategy: Send + Sync {
    /// Default stub: the straight line from port position to extension exit.
    /// Panics if `ports.start` / `ports.end` are the same point (produces one-element vec).
    fn compute_stub(
        &self, side: Side, ports: &ResolvedPorts, _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        match side {
            Side::Start => vec![ports.start.position, ports.start_exit],
            Side::End => vec![ports.end_exit, ports.end.position],
        }
    }

    /// Compute the transition (curve) between a stub and the body.
    fn compute_transition(
        &self,
        input: &TransitionInput,
        config: &RelationEngineConfig,
    ) -> Vec<Point>;

    fn compute_obstacle_waypoints(
        &self, from: Point, to: Point, obstacles: &[Rect], config: &RelationEngineConfig,
    ) -> Vec<Point> {
        super::obstacle_avoidance::compute_waypoints(from, to, obstacles, config.routing.obstacle_margin)
    }

    fn compute_body(
        &self, waypoints: &[Point], ports: &ResolvedPorts, config: &RelationEngineConfig,
    ) -> Vec<Point>;

    fn post_process(&self, _path: &mut Vec<Point>, _config: &RelationEngineConfig) {}

    fn path_type(&self) -> PathType;

    fn route_full(
        &self,
        ports: &ResolvedPorts,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) -> (Vec<Point>, PathType) {
        let (start_stub, end_stub) = rayon::join(
            || self.compute_stub(Side::Start, ports, config),
            || self.compute_stub(Side::End, ports, config),
        );
        let stub_exit = *start_stub.last().unwrap();
        let stub_entry = *end_stub.first().unwrap();

        let waypoints = self.compute_obstacle_waypoints(stub_exit, stub_entry, obstacles, config);
        let body = self.compute_body(&waypoints, ports, config);

        let (start_trans, end_trans) = rayon::join(
            || self.compute_transition(
                &TransitionInput {
                    side: Side::Start,
                    stub_exit,
                    stub_entry,
                    start_normal: ports.start_normal,
                    end_normal: ports.end_normal,
                    body_start: body[0],
                    body_end: *body.last().unwrap(),
                },
                config,
            ),
            || self.compute_transition(
                &TransitionInput {
                    side: Side::End,
                    stub_exit,
                    stub_entry,
                    start_normal: ports.start_normal,
                    end_normal: ports.end_normal,
                    body_start: body[0],
                    body_end: *body.last().unwrap(),
                },
                config,
            ),
        );

        let mut path = start_stub;
        path.extend(start_trans);
        // body[1..] skips body[0] — already the endpoint of start_trans (no dedup needed)
        path.extend(body[1..].iter().copied());
        path.extend(end_trans);
        path.extend(end_stub[1..].iter().copied());

        self.post_process(&mut path, config);

        let path_type = self.path_type();
        (path, path_type)
    }
}

pub fn resolve_strategy(mode: RoutingMode) -> Box<dyn RoutingStrategy> {
    match mode {
        RoutingMode::Polyline => Box::new(polyline::PolylineRouting),
        RoutingMode::Bezier => Box::new(bezier::BezierRouting),
        RoutingMode::Orthogonal => Box::new(orthogonal::OrthogonalRouting),
        RoutingMode::CircularArc => Box::new(circular_arc::CircularArcRouting),
        RoutingMode::SineWave => Box::new(sine_wave::SineWaveRouting),
    }
}

pub fn compute_bbox(points: &[Point]) -> Rect {
    if points.is_empty() {
        return Rect::new(0.0, 0.0, 0.0, 0.0);
    }
    let mut min_x = f64::MAX;
    let mut min_y = f64::MAX;
    let mut max_x = f64::MIN;
    let mut max_y = f64::MIN;
    for p in points {
        if p.x < min_x { min_x = p.x; }
        if p.y < min_y { min_y = p.y; }
        if p.x > max_x { max_x = p.x; }
        if p.y > max_y { max_y = p.y; }
    }
    Rect::new(min_x, min_y, max_x - min_x, max_y - min_y)
}