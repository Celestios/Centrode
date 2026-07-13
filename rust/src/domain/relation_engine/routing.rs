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
    /// Target endpoint — transitions that know where the body *should* go
    /// (e.g. orthogonal corner) use this as the destination hint.  By
    /// default (most strategies) equal to stub_exit / stub_entry, meaning
    /// the body starts at the stub tip and no transition is needed.
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

    /// Compute a transition (curve) from the stub tip toward the body.
    ///
    /// Called **before** `compute_body` — the transition determines where the
    /// body should start (its last point = `body_start`, or empty = body starts
    /// at `stub_exit`).  Strategies that don't need a transition return `vec![]`.
    fn compute_transition(
        &self,
        _input: &TransitionInput,
        _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        vec![]
    }

    fn compute_obstacle_waypoints(
        &self, from: Point, to: Point, obstacles: &[Rect], config: &RelationEngineConfig,
    ) -> Vec<Point> {
        super::obstacle_avoidance::compute_waypoints_with_strategy(from, to, obstacles, config.routing.obstacle_margin, self)
    }

    fn compute_body(
        &self, waypoints: &[Point], ports: &ResolvedPorts, config: &RelationEngineConfig,
    ) -> Vec<Point>;

    fn post_process(&self, _path: &mut Vec<Point>, _config: &RelationEngineConfig) {}

    fn path_type(&self) -> PathType;

    fn a_star_edge_cost(
        &self,
        params: &super::solver::visibility_graph::RouteCostParams,
        edge_dist: f64,
        prev_point: Option<Point>,
        curr_point: Point,
        next_point: Point,
        dst_point: Point,
        grid: &super::solver::visibility_graph::SpatialGrid,
    ) -> f64 {
        let mut cost = edge_dist;

        if let Some(prev) = prev_point {
            let rad = std::f64::consts::PI - super::solver::visibility_graph::angle_between(prev, curr_point, next_point);

            if rad > 1e-6 && params.angle_penalty > 0.0 {
                let xval = rad * 10.0 / std::f64::consts::PI;
                let yval = xval * (xval + 1.0).log10() / 10.5;
                cost += params.angle_penalty * yval;
            }

            if rad > std::f64::consts::PI - 1e-6 {
                cost += 2.0 * params.segment_penalty;
            } else if rad > 1e-6 {
                cost += params.segment_penalty;
            }
        } else {
            cost += params.segment_penalty * 0.5;
        }

        if params.reverse_direction_penalty > 0.0 {
            let src_to_dst = dst_point - Point::new(0.0, 0.0);
            let x_dir = super::solver::visibility_graph::dim_direction(src_to_dst.x);
            let y_dir = super::solver::visibility_graph::dim_direction(src_to_dst.y);

            let seg_dir = next_point - curr_point;
            let seg_x_dir = super::solver::visibility_graph::dim_direction(seg_dir.x);
            let seg_y_dir = super::solver::visibility_graph::dim_direction(seg_dir.y);

            let mut does_reverse = false;
            if x_dir != 0 && seg_x_dir == -x_dir {
                does_reverse = true;
            }
            if y_dir != 0 && seg_y_dir == -y_dir {
                does_reverse = true;
            }

            if does_reverse {
                cost += params.reverse_direction_penalty;
            }
        }

        if params.crossing_penalty > 0.0 {
            if grid.intersects_segment(curr_point, next_point) {
                cost += params.crossing_penalty;
            }
        }

        cost
    }

    fn a_star_heuristic(
        &self,
        from: Point,
        to: Point,
        prev: Option<Point>,
        params: &super::solver::visibility_graph::RouteCostParams,
    ) -> f64 {
        let dist = from.distance_to(to);

        if params.segment_penalty > 0.0 || params.angle_penalty > 0.0 {
            let dx = to.x - from.x;
            let dy = to.y - from.y;
            let mut bend_estimate = 0;

            if let Some(prev_pt) = prev {
                let curr_dir = from - prev_pt;
                let curr_len = curr_dir.length();
                if curr_len > 1e-6 {
                    let curr_dir_norm = Point::new(curr_dir.x / curr_len, curr_dir.y / curr_len);
                    if curr_dir_norm.x.abs() > 0.5 && dy.abs() > 1e-6 {
                        bend_estimate += 1;
                    } else if curr_dir_norm.y.abs() > 0.5 && dx.abs() > 1e-6 {
                        bend_estimate += 1;
                    }
                }
            } else {
                if dx.abs() > 1e-6 && dy.abs() > 1e-6 {
                    bend_estimate += 1;
                }
            }

            dist + bend_estimate as f64 * params.segment_penalty
        } else {
            dist
        }
    }

    fn a_star_is_better(
        &self,
        tentative_g: f64,
        existing_g: f64,
        _current: usize,
        _neighbor: usize,
        _graph: &super::solver::visibility_graph::VisibilityGraph,
        _came_from: &[Option<usize>],
    ) -> bool {
        tentative_g < existing_g - 1e-6
    }

    fn route_full(
        &self,
        ports: &ResolvedPorts,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
    ) -> (Vec<Point>, PathType) {
        // 1. stubs (sequential — cheap)
        let start_stub = self.compute_stub(Side::Start, ports, config);
        let end_stub = self.compute_stub(Side::End, ports, config);
        let stub_exit = *start_stub.last().unwrap();
        let stub_entry = *end_stub.first().unwrap();

        // 2. transitions (parallel) — determine where the body will start/end.
        //    body_start/body_end default to stub_exit/stub_entry (no gap).
        let (start_trans, end_trans) = rayon::join(
            || self.compute_transition(
                &TransitionInput {
                    side: Side::Start,
                    stub_exit,
                    stub_entry,
                    start_normal: ports.start_normal,
                    end_normal: ports.end_normal,
                    body_start: stub_exit,
                    body_end: stub_entry,
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
                    body_start: stub_exit,
                    body_end: stub_entry,
                },
                config,
            ),
        );

        // 3. body — starts where the start-transition ends (or at stub_exit)
        let body_start = start_trans.last().copied().unwrap_or(stub_exit);
        let body_end = end_trans.first().copied().unwrap_or(stub_entry);
        let waypoints = self.compute_obstacle_waypoints(body_start, body_end, obstacles, config);
        let body = self.compute_body(&waypoints, ports, config);

        // 4. assemble — each segment cascades into the next (no duplicates)
        let mut path = start_stub;
        if !start_trans.is_empty() {
            // start_trans[0] = stub_exit (already last in start_stub) — skip
            path.extend(start_trans[1..].iter().copied());
        }
        // body[0] = body_start = start_trans.last() (or stub_exit) — skip
        if body.len() > 1 {
            path.extend(body[1..].iter().copied());
        }
        if !end_trans.is_empty() {
            // end_trans[0] = body_end (= body.last()) — skip
            path.extend(end_trans[1..].iter().copied());
        }
        // end_stub[0] = stub_entry (= end_trans.last() or body.last()) — skip
        path.extend(end_stub[1..].iter().copied());

        self.post_process(&mut path, config);

        let path_type = self.path_type();
        (path, path_type)
    }
}

pub fn resolve_strategy(mode: RoutingMode) -> Box<dyn RoutingStrategy> {
    match mode {
        RoutingMode::Polyline => Box::new(polyline::PolylineRouting {}),
        RoutingMode::Bezier => Box::new(bezier::BezierRouting {}),
        RoutingMode::Orthogonal => Box::new(orthogonal::OrthogonalRouting {}),
        RoutingMode::CircularArc => Box::new(circular_arc::CircularArcRouting {}),
        RoutingMode::SineWave => Box::new(sine_wave::SineWaveRouting {}),
    }
}

/// Remove collinear waypoints that don't contribute to the path shape.
pub fn prune_collinear_waypoints(waypoints: &[Point]) -> Vec<Point> {
    if waypoints.len() <= 2 {
        return waypoints.to_vec();
    }
    let mut pruned = vec![waypoints[0]];
    for i in 1..waypoints.len() - 1 {
        let prev = *pruned.last().unwrap();
        let curr = waypoints[i];
        let next = waypoints[i + 1];
        let v1 = (curr - prev).normalized();
        let v2 = (next - curr).normalized();
        let dot = v1.dot(v2);
        if dot < 0.999 {
            pruned.push(curr);
        }
    }
    pruned.push(*waypoints.last().unwrap());
    pruned
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
