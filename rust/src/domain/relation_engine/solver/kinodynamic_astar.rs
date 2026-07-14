use crate::domain::relation_engine::config::KinodynamicConfig;
use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::geometry::bspline::{
    convex_hull_4, sat_intersects, de_casteljau_subdivide,
    cubic_bspline_point, cubic_bspline_first_derivative, cubic_bspline_curvature, gauss_legendre_3
};
use std::collections::{BinaryHeap, HashMap};
use std::cmp::Ordering;

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct KinodynamicState {
    pub x: f64,
    pub y: f64,
    pub theta: f64,
    pub kappa: f64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct LatticeKey {
    pub xi: i32,
    pub yi: i32,
    pub ti: i32,
    pub ki: i32,
}

impl KinodynamicState {
    pub fn lattice_key(&self, config: &KinodynamicConfig) -> LatticeKey {
        let xi = (self.x / config.lattice_cell_size).floor() as i32;
        let yi = (self.y / config.lattice_cell_size).floor() as i32;
        let theta_normalized = self.theta.rem_euclid(2.0 * std::f64::consts::PI);
        let bins = (2.0 * std::f64::consts::PI / config.angular_resolution).round() as i32;
        let ti = ((theta_normalized / config.angular_resolution).floor() as i32) % bins;
        let k_ratio = (self.kappa + config.kappa_max) / (2.0 * config.kappa_max);
        let ki = (k_ratio * (config.curvature_bins as f64)).floor() as i32;
        let ki = ki.clamp(0, (config.curvature_bins as i32) - 1);
        LatticeKey { xi, yi, ti, ki }
    }
}

pub struct Action {
    pub delta_theta: f64,
    pub delta_l: f64,
}

impl Action {
    pub fn all_actions() -> Vec<Self> {
        let delta_thetas = [
            -std::f64::consts::PI / 4.0,
            -std::f64::consts::PI / 8.0,
            0.0,
            std::f64::consts::PI / 8.0,
            std::f64::consts::PI / 4.0,
        ];
        let delta_ls = [30.0, 60.0, 90.0];
        let mut actions = Vec::with_capacity(15);
        for &dt in &delta_thetas {
            for &dl in &delta_ls {
                actions.push(Action { delta_theta: dt, delta_l: dl });
            }
        }
        actions
    }
}

pub fn distance_to_rect(q: Point, rect: &Rect) -> f64 {
    let dx = (rect.left() - q.x).max(0.0).max(q.x - rect.right());
    let dy = (rect.top() - q.y).max(0.0).max(q.y - rect.bottom());
    (dx * dx + dy * dy).sqrt()
}

pub fn min_distance_to_obstacles(q: Point, obstacles: &[Rect]) -> f64 {
    let mut min_d = f64::INFINITY;
    for rect in obstacles {
        let d = distance_to_rect(q, rect);
        if d < min_d {
            min_d = d;
        }
    }
    min_d
}

pub fn obstacle_potential(q: Point, obstacles: &[Rect], config: &KinodynamicConfig) -> f64 {
    if obstacles.is_empty() {
        return 0.0;
    }
    let d = min_distance_to_obstacles(q, obstacles);
    if d >= config.obstacle_falloff {
        0.0
    } else {
        config.weight_obstacle * (- (d * d) / (config.obstacle_falloff * config.obstacle_falloff)).exp()
    }
}

fn mod2pi(theta: f64) -> f64 {
    theta.rem_euclid(2.0 * std::f64::consts::PI)
}

pub fn dubins_path_length(
    x1: f64, y1: f64, theta1: f64,
    x2: f64, y2: f64, theta2: f64,
    r: f64,
) -> f64 {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let cos_t1 = theta1.cos();
    let sin_t1 = theta1.sin();
    let x_local = (dx * cos_t1 + dy * sin_t1) / r;
    let y_local = (-dx * sin_t1 + dy * cos_t1) / r;
    let theta = mod2pi(theta2 - theta1);
    let d = (x_local * x_local + y_local * y_local).sqrt();
    let sa = 0.0;
    let ca = 1.0;
    let sb = theta.sin();
    let cb = theta.cos();
    let c_ab = cb;
    let mut min_len = f64::INFINITY;

    let p_sq_lsl = 2.0 + d * d - 2.0 * c_ab + 2.0 * d * (sa - sb);
    if p_sq_lsl >= 0.0 {
        let p = p_sq_lsl.sqrt();
        let tmp = mod2pi((cb - ca).atan2(d + sa - sb));
        let t = mod2pi(tmp);
        let q = mod2pi(theta - tmp);
        let len = t + p + q;
        if len < min_len {
            min_len = len;
        }
    }

    let p_sq_rsr = 2.0 + d * d - 2.0 * c_ab + 2.0 * d * (sb - sa);
    if p_sq_rsr >= 0.0 {
        let p = p_sq_rsr.sqrt();
        let tmp = mod2pi(-(ca - cb).atan2(d - sa + sb));
        let t = mod2pi(tmp);
        let q = mod2pi(-theta + tmp);
        let len = t + p + q;
        if len < min_len {
            min_len = len;
        }
    }

    let p_sq_lsr = -2.0 + d * d + 2.0 * c_ab + 2.0 * d * (sa + sb);
    if p_sq_lsr >= 0.0 {
        let p = p_sq_lsr.sqrt();
        let tmp = (-ca - cb).atan2(d + sa + sb) - (2.0).atan2(p);
        let t = mod2pi(tmp);
        let q = mod2pi(-theta + tmp);
        let len = t + p + q;
        if len < min_len {
            min_len = len;
        }
    }

    let p_sq_rsl = d * d - 2.0 + 2.0 * c_ab - 2.0 * d * (sa + sb);
    if p_sq_rsl >= 0.0 {
        let p = p_sq_rsl.sqrt();
        let tmp = (ca + cb).atan2(d - sa - sb) - (2.0).atan2(p);
        let t = mod2pi(-tmp);
        let q = mod2pi(theta - tmp);
        let len = t + p + q;
        if len < min_len {
            min_len = len;
        }
    }

    let tmp_lrl = (6.0 - d * d + 2.0 * c_ab + 2.0 * d * (-sa + sb)) / 8.0;
    if tmp_lrl.abs() <= 1.0 {
        let p = mod2pi(2.0 * std::f64::consts::PI - tmp_lrl.acos());
        let t = mod2pi(-atan2_val(ca - cb, d + sa - sb) + p / 2.0);
        let q = mod2pi(theta - t + p);
        let len = t + p + q;
        if len < min_len {
            min_len = len;
        }
    }

    let tmp_rlr = (6.0 - d * d + 2.0 * c_ab + 2.0 * d * (sa - sb)) / 8.0;
    if tmp_rlr.abs() <= 1.0 {
        let p = mod2pi(2.0 * std::f64::consts::PI - tmp_rlr.acos());
        let t = mod2pi(-atan2_val(ca - cb, d - sa + sb) + p / 2.0);
        let q = mod2pi(-theta - t + p);
        let len = t + p + q;
        if len < min_len {
            min_len = len;
        }
    }

    if min_len.is_infinite() {
        d * r
    } else {
        min_len * r
    }
}

fn atan2_val(y: f64, x: f64) -> f64 {
    y.atan2(x)
}

pub fn dubins_heuristic(
    curr: &KinodynamicState,
    target: &KinodynamicState,
    config: &KinodynamicConfig,
) -> f64 {
    let dist = Point::new(curr.x, curr.y).distance_to(Point::new(target.x, target.y));
    let r_min = 1.0 / config.kappa_max;
    let dubins_len = dubins_path_length(
        curr.x, curr.y, curr.theta,
        target.x, target.y, target.theta,
        r_min,
    );
    dist.max(dubins_len)
}

fn segment_size(pts: &[Point; 4]) -> f64 {
    let mut max_dist = 0.0;
    for i in 0..4 {
        for j in i+1..4 {
            let dist = pts[i].distance_to(pts[j]);
            if dist > max_dist {
                max_dist = dist;
            }
        }
    }
    max_dist
}

fn check_collision_subdivision(
    control_points: [Point; 4],
    obstacles: &[Rect],
    tolerance: f64,
) -> bool {
    let hull = convex_hull_4(&control_points);
    let mut intersects = false;
    for obs in obstacles {
        if sat_intersects(&hull, obs) {
            intersects = true;
            break;
        }
    }
    if !intersects {
        return false;
    }
    if segment_size(&control_points) <= tolerance {
        return true;
    }
    let (left, right) = de_casteljau_subdivide(&control_points, 0.5);
    check_collision_subdivision(left, obstacles, tolerance)
        || check_collision_subdivision(right, obstacles, tolerance)
}

fn check_collision(
    p0: Point, p1: Point, p2: Point, p3: Point,
    obstacles: &[Rect],
    narrow_phase_tolerance: f64,
) -> bool {
    let control_points = [p0, p1, p2, p3];
    let hull = convex_hull_4(&control_points);
    let mut broad_phase_intersects = false;
    for obs in obstacles {
        if sat_intersects(&hull, obs) {
            broad_phase_intersects = true;
            break;
        }
    }
    if !broad_phase_intersects {
        return false;
    }
    check_collision_subdivision(control_points, obstacles, narrow_phase_tolerance)
}

fn expand_state(
    curr: &KinodynamicState,
    action: &Action,
    obstacles: &[Rect],
    config: &KinodynamicConfig,
) -> Option<(KinodynamicState, [Point; 4], f64)> {
    let theta3 = curr.theta + action.delta_theta;
    let p0 = Point::new(curr.x, curr.y);
    let p3 = p0 + Point::new(theta3.cos(), theta3.sin()) * action.delta_l;
    let v0 = Point::new(curr.theta.cos(), curr.theta.sin());
    let v3 = Point::new(theta3.cos(), theta3.sin());
    let d = p3 - p0;
    let l1 = action.delta_l / 3.0;
    let l0 = if curr.kappa.abs() < 1e-6 {
        action.delta_l / 3.0
    } else {
        let cross_v0_d = v0.x * d.y - v0.y * d.x;
        let cross_v0_v3 = v0.x * v3.y - v0.y * v3.x;
        let term = (2.0 / 3.0) * (cross_v0_d - l1 * cross_v0_v3) / curr.kappa;
        if term < 0.0 {
            action.delta_l / 3.0
        } else {
            term.sqrt()
        }
    };
    let l0 = l0.clamp(action.delta_l / 4.0, action.delta_l / 1.5);
    let p1 = p0 + v0 * l0;
    let p2 = p3 - v3 * l1;
    let end_kappa = cubic_bspline_curvature(p0, p1, p2, p3, 1.0);
    if end_kappa.abs() > config.kappa_max {
        return None;
    }
    if check_collision(p0, p1, p2, p3, obstacles, config.narrow_phase_tolerance) {
        return None;
    }
    let transition_cost = gauss_legendre_3(|u| {
        let pt = cubic_bspline_point(p0, p1, p2, p3, u);
        let d1 = cubic_bspline_first_derivative(p0, p1, p2, p3, u);
        let d1_len = d1.length();
        let k = cubic_bspline_curvature(p0, p1, p2, p3, u);
        let pot = obstacle_potential(pt, obstacles, config);
        (config.weight_arc_length * d1_len + config.weight_curvature * k * k + pot) * d1_len
    });
    let next_state = KinodynamicState {
        x: p3.x,
        y: p3.y,
        theta: theta3,
        kappa: end_kappa,
    };
    Some((next_state, [p0, p1, p2, p3], transition_cost))
}

#[derive(Debug, Clone)]
struct Node {
    state: KinodynamicState,
    key: LatticeKey,
    g_cost: f64,
    f_cost: f64,
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.f_cost == other.f_cost
    }
}

impl Eq for Node {}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f_cost.partial_cmp(&self.f_cost).unwrap_or(Ordering::Equal)
    }
}

struct PathInfo {
    parent: Option<LatticeKey>,
    segment_control_points: [Point; 4],
}

pub fn kinodynamic_astar(
    start: KinodynamicState,
    target: KinodynamicState,
    obstacles: &[Rect],
    config: &KinodynamicConfig,
) -> Option<Vec<Point>> {
    let start_key = start.lattice_key(config);
    let target_key = target.lattice_key(config);
    if start_key == target_key {
        let p0 = Point::new(start.x, start.y);
        let p3 = Point::new(target.x, target.y);
        let l = p0.distance_to(p3).max(10.0);
        let v0 = Point::new(start.theta.cos(), start.theta.sin());
        let v3 = Point::new(target.theta.cos(), target.theta.sin());
        let p1 = p0 + v0 * (l / 3.0);
        let p2 = p3 - v3 * (l / 3.0);
        return Some(vec![p0, p1, p2, p3]);
    }
    let actions = Action::all_actions();
    let mut open_set = BinaryHeap::new();
    let mut g_score = HashMap::new();
    let mut came_from: HashMap<LatticeKey, PathInfo> = HashMap::new();

    g_score.insert(start_key, 0.0);
    let h_start = dubins_heuristic(&start, &target, config);
    open_set.push(Node {
        state: start,
        key: start_key,
        g_cost: 0.0,
        f_cost: h_start,
    });

    while let Some(current_node) = open_set.pop() {
        let current_key = current_node.key;
        if current_key == target_key {
            let mut segments = Vec::new();
            let mut curr = current_key;
            while let Some(info) = came_from.get(&curr) {
                segments.push(info.segment_control_points.to_vec());
                if let Some(parent_key) = info.parent {
                    curr = parent_key;
                } else {
                    break;
                }
            }
            segments.reverse();
            let mut unified_control_points = Vec::new();
            if !segments.is_empty() {
                unified_control_points.extend_from_slice(&segments[0]);
                for seg in segments.iter().skip(1) {
                    unified_control_points.push(seg[1]);
                    unified_control_points.push(seg[2]);
                    unified_control_points.push(seg[3]);
                }
            }
            return Some(unified_control_points);
        }
        if let Some(&best_g) = g_score.get(&current_key) {
            if current_node.g_cost > best_g {
                continue;
            }
        }
        for action in &actions {
            if let Some((next_state, control_points, transition_cost)) =
                expand_state(&current_node.state, action, obstacles, config)
            {
                let next_key = next_state.lattice_key(config);
                let tentative_g = current_node.g_cost + transition_cost;
                let is_better = match g_score.get(&next_key) {
                    Some(&existing_g) => tentative_g < existing_g,
                    None => true,
                };
                if is_better {
                    g_score.insert(next_key, tentative_g);
                    came_from.insert(
                        next_key,
                        PathInfo {
                            parent: Some(current_key),
                            segment_control_points: control_points,
                        },
                    );
                    let h = dubins_heuristic(&next_state, &target, config);
                    open_set.push(Node {
                        state: next_state,
                        key: next_key,
                        g_cost: tentative_g,
                        f_cost: tentative_g + h,
                    });
                }
            }
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lattice_key() {
        let config = KinodynamicConfig::default();
        let state1 = KinodynamicState {
            x: 10.0,
            y: 20.0,
            theta: 0.1,
            kappa: 0.0,
        };
        let key1 = state1.lattice_key(&config);
        assert_eq!(key1.xi, 0);
        assert_eq!(key1.yi, 1);
        
        let state2 = KinodynamicState {
            x: 35.0,
            y: -10.0,
            theta: 2.0 * std::f64::consts::PI + 0.1,
            kappa: 0.0,
        };
        let key2 = state2.lattice_key(&config);
        assert_eq!(key2.xi, 1);
        assert_eq!(key2.yi, -1);
        assert_eq!(key1.ti, key2.ti);
    }

    #[test]
    fn test_action_set() {
        let actions = Action::all_actions();
        assert_eq!(actions.len(), 15);
    }

    #[test]
    fn test_potential_field() {
        let config = KinodynamicConfig::default();
        let rect = Rect::new(10.0, 10.0, 10.0, 10.0);
        let obstacles = vec![rect];
        
        let p_inside = Point::new(15.0, 15.0);
        let pot_inside = obstacle_potential(p_inside, &obstacles, &config);
        assert!((pot_inside - config.weight_obstacle).abs() < 1e-9);
        
        let p_far = Point::new(100.0, 100.0);
        let pot_far = obstacle_potential(p_far, &obstacles, &config);
        assert_eq!(pot_far, 0.0);
    }

    #[test]
    fn test_dubins_heuristic() {
        let config = KinodynamicConfig::default();
        let start = KinodynamicState {
            x: 0.0,
            y: 0.0,
            theta: 0.0,
            kappa: 0.0,
        };
        let target = KinodynamicState {
            x: 100.0,
            y: 0.0,
            theta: 0.0,
            kappa: 0.0,
        };
        let h = dubins_heuristic(&start, &target, &config);
        assert!(h >= 100.0);
    }

    #[test]
    fn test_collision_checking() {
        let obstacles = vec![Rect::new(10.0, 10.0, 10.0, 10.0)];
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(5.0, 5.0);
        let p2 = Point::new(8.0, 8.0);
        let p3 = Point::new(25.0, 25.0);
        let collides = check_collision(p0, p1, p2, p3, &obstacles, 5.0);
        assert!(collides);
        
        let p0_safe = Point::new(0.0, 0.0);
        let p1_safe = Point::new(0.0, 5.0);
        let p2_safe = Point::new(0.0, 10.0);
        let p3_safe = Point::new(0.0, 15.0);
        let collides_safe = check_collision(p0_safe, p1_safe, p2_safe, p3_safe, &obstacles, 5.0);
        assert!(!collides_safe);
    }

    #[test]
    fn test_astar_search() {
        let config = KinodynamicConfig::default();
        let start = KinodynamicState {
            x: 0.0,
            y: 0.0,
            theta: 0.0,
            kappa: 0.0,
        };
        let target = KinodynamicState {
            x: 100.0,
            y: 100.0,
            theta: std::f64::consts::PI / 4.0,
            kappa: 0.0,
        };
        let obstacles = vec![];
        let path = kinodynamic_astar(start, target, &obstacles, &config);
        assert!(path.is_some());
        let control_points = path.unwrap();
        assert!(control_points.len() >= 4);
    }
}
