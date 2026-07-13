use crate::domain::relation_engine::geometry::{segments_intersect, Point, Rect};

#[derive(Debug, Clone)]
struct SweepVertex {
    point: Point,
    _obstacle_idx: usize,
    corner_idx: usize,
    angle: f64,
    distance: f64,
}

impl PartialEq for SweepVertex {
    fn eq(&self, other: &Self) -> bool {
        self.angle == other.angle && self.distance == other.distance
    }
}
impl Eq for SweepVertex {}

impl PartialOrd for SweepVertex {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for SweepVertex {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.angle
            .total_cmp(&other.angle)
            .then_with(|| self.distance.total_cmp(&other.distance))
    }
}

#[derive(Debug, Clone)]
struct SweepEdge {
    p1: Point,
    p2: Point,
    obstacle_idx: usize,
    angle_at_ray: f64,
    distance_at_ray: f64,
}

impl SweepEdge {
    fn new(p1: Point, p2: Point, obstacle_idx: usize) -> Self {
        Self {
            p1,
            p2,
            obstacle_idx,
            angle_at_ray: 0.0,
            distance_at_ray: 0.0,
        }
    }

    fn update_distance(&mut self, center: Point, ray_angle: f64) {
        self.angle_at_ray = ray_angle;
        let cos = ray_angle.cos();
        let sin = ray_angle.sin();
        let ray_end = Point::new(center.x + cos * 1e6, center.y + sin * 1e6);
        if let Some(intersection) = ray_segment_intersection(center, ray_end, self.p1, self.p2) {
            self.distance_at_ray = center.distance_to(intersection);
        } else {
            self.distance_at_ray = f64::INFINITY;
        }
    }
}

impl PartialEq for SweepEdge {
    fn eq(&self, other: &Self) -> bool {
        self.p1 == other.p1 && self.p2 == other.p2
    }
}

fn rotational_angle(p: Point, center: Point) -> f64 {
    let dx = p.x - center.x;
    let dy = p.y - center.y;
    dy.atan2(dx)
}

fn ray_segment_intersection(ray_start: Point, ray_end: Point, seg_a: Point, seg_b: Point) -> Option<Point> {
    let d1 = ray_end - ray_start;
    let d2 = seg_b - seg_a;
    let cross = d1.x * d2.y - d1.y * d2.x;

    if cross.abs() < 1e-10 {
        return None;
    }

    let t = ((seg_a.x - ray_start.x) * d2.y - (seg_a.y - ray_start.y) * d2.x) / cross;
    let u = ((seg_a.x - ray_start.x) * d1.y - (seg_a.y - ray_start.y) * d1.x) / cross;

    if t >= 0.0 && u >= 0.0 && u <= 1.0 {
        Some(Point::new(
            ray_start.x + t * d1.x,
            ray_start.y + t * d1.y,
        ))
    } else {
        None
    }
}

fn vec_dir(from: Point, through: Point, to: Point) -> i32 {
    let cross = (through.x - from.x) * (to.y - from.y) - (through.y - from.y) * (to.x - from.x);
    if cross > 1e-10 {
        1
    } else if cross < -1e-10 {
        -1
    } else {
        0
    }
}

pub struct ObstacleEdge {
    pub from: Point,
    pub to: Point,
    pub obstacle_idx: usize,
}

pub fn build_obstacle_edges(obstacles: &[Rect]) -> Vec<ObstacleEdge> {
    let mut edges = Vec::new();
    for (oi, obs) in obstacles.iter().enumerate() {
        let corners = obs.corners();
        for i in 0..4 {
            edges.push(ObstacleEdge {
                from: corners[i],
                to: corners[(i + 1) % 4],
                obstacle_idx: oi,
            });
        }
    }
    edges
}

pub struct SweepVisResult {
    pub visible_edges: Vec<(usize, usize)>,
}

pub fn angular_sweep_visibility(
    vertices: &[Point],
    obstacle_edges: &[ObstacleEdge],
) -> SweepVisResult {
    let n = vertices.len();
    let mut visible = vec![vec![false; n]; n];

    for i in 0..n {
        let center = vertices[i];
        sweep_from_vertex(i, center, vertices, obstacle_edges, &mut visible);
    }

    let mut visible_edges = Vec::new();
    for i in 0..n {
        for j in (i + 1)..n {
            if visible[i][j] {
                visible_edges.push((i, j));
            }
        }
    }

    SweepVisResult { visible_edges }
}

fn sweep_from_vertex(
    center_idx: usize,
    center: Point,
    vertices: &[Point],
    obstacle_edges: &[ObstacleEdge],
    visible: &mut Vec<Vec<bool>>,
) {
    let mut sweep_verts: Vec<SweepVertex> = vertices
        .iter()
        .enumerate()
        .filter(|&(idx, _)| idx != center_idx)
        .map(|(idx, &p)| {
            let angle = rotational_angle(p, center);
            let distance = center.distance_to(p);
            SweepVertex {
                point: p,
                _obstacle_idx: usize::MAX,
                corner_idx: idx,
                angle,
                distance,
            }
        })
        .collect();

    sweep_verts.sort();

    if sweep_verts.is_empty() {
        return;
    }

    let init_angle = sweep_verts[0].angle;

    let mut sweep_edges: Vec<SweepEdge> = obstacle_edges
        .iter()
        .filter(|edge| {
            if segments_intersect(center, Point::new(center.x + 1e6 * init_angle.cos(), center.y + 1e6 * init_angle.sin()), edge.from, edge.to) {
                return true;
            }
            false
        })
        .map(|edge| {
            let mut se = SweepEdge::new(edge.from, edge.to, edge.obstacle_idx);
            se.update_distance(center, init_angle);
            se
        })
        .collect();

        let _total_angle = std::f64::consts::TAU;

    for sv in &sweep_verts {
        let ray_angle = sv.angle;

        for se in &mut sweep_edges {
            se.update_distance(center, ray_angle);
        }
        sweep_edges.sort_by(|a, b| a.distance_at_ray.total_cmp(&b.distance_at_ray));

        let mut blocked = false;
        let mut blocker_idx = usize::MAX;

        for se in &sweep_edges {
            if se.distance_at_ray < sv.distance - 1e-6 {
                blocked = true;
                blocker_idx = se.obstacle_idx;
                break;
            } else if (se.distance_at_ray - sv.distance).abs() < 1e-6 {
                blocked = true;
                blocker_idx = se.obstacle_idx;
                break;
            }
        }

        visible[center_idx][sv.corner_idx] = !blocked;
        visible[sv.corner_idx][center_idx] = !blocked;

        let mut to_add = Vec::new();
        let mut to_remove = Vec::new();

        for edge in obstacle_edges {
            if edge.obstacle_idx == blocker_idx && blocked {
                continue;
            }
            let prev_vertex = find_prev_vertex_in_obstacle(sv.point, edge, vertices, center_idx);
            let next_vertex = find_next_vertex_in_obstacle(sv.point, edge, vertices, center_idx);

            if let Some(prev) = prev_vertex {
                let prev_dir = vec_dir(center, sv.point, prev);
                if prev_dir == -1 {
                    to_remove.push(SweepEdge::new(edge.from, edge.to, edge.obstacle_idx));
                } else if prev_dir == 1 {
                    let mut se = SweepEdge::new(edge.from, edge.to, edge.obstacle_idx);
                    se.update_distance(center, ray_angle);
                    to_add.push(se);
                }
            }
            if let Some(next) = next_vertex {
                let next_dir = vec_dir(center, sv.point, next);
                if next_dir == -1 {
                    to_remove.push(SweepEdge::new(edge.from, edge.to, edge.obstacle_idx));
                } else if next_dir == 1 {
                    let mut se = SweepEdge::new(edge.from, edge.to, edge.obstacle_idx);
                    se.update_distance(center, ray_angle);
                    to_add.push(se);
                }
            }
        }

        for se in to_remove {
            sweep_edges.retain(|e| !(e.p1 == se.p1 && e.p2 == se.p2));
        }
        for se in to_add {
            if !sweep_edges.iter().any(|e| e.p1 == se.p1 && e.p2 == se.p2) {
                sweep_edges.push(se);
            }
        }
    }
}

fn find_prev_vertex_in_obstacle(
    _point: Point,
    _edge: &ObstacleEdge,
    _vertices: &[Point],
    _center_idx: usize,
) -> Option<Point> {
    None
}

fn find_next_vertex_in_obstacle(
    _point: Point,
    _edge: &ObstacleEdge,
    _vertices: &[Point],
    _center_idx: usize,
) -> Option<Point> {
    None
}

pub fn naive_visibility(
    vertices: &[Point],
    obstacles: &[Rect],
    margin: f64,
) -> Vec<(usize, usize)> {
    naive_visibility_with_exemptions(vertices, obstacles, margin, &[])
}

pub fn naive_visibility_with_exemptions(
    vertices: &[Point],
    obstacles: &[Rect],
    margin: f64,
    exempt_indices: &[usize],
) -> Vec<(usize, usize)> {
    let n = vertices.len();
    let exempt_set: std::collections::HashSet<usize> = exempt_indices.iter().copied().collect();
    let mut visible_edges = Vec::new();

    for i in 0..n {
        for j in (i + 1)..n {
            if is_segment_visible_exempt(vertices[i], vertices[j], i, j, obstacles, margin, &exempt_set) {
                visible_edges.push((i, j));
            }
        }
    }

    visible_edges
}

fn is_segment_visible_exempt(
    p1: Point, p2: Point,
    idx1: usize, idx2: usize,
    obstacles: &[Rect], margin: f64,
    exempt: &std::collections::HashSet<usize>,
) -> bool {
    fn is_interior(p: Point, rect: &Rect) -> bool {
        p.x > rect.left() + 1e-3
            && p.x < rect.right() - 1e-3
            && p.y > rect.top() + 1e-3
            && p.y < rect.bottom() - 1e-3
    }

    for obs in obstacles {
        // 1. Block if it intersects the actual un-expanded obstacle body
        if obs.intersects_segment(p1, p2) {
            return false;
        }

        let expanded = obs.expand(margin);

        // 2. Block if the segment midpoint is strictly inside the expanded obstacle interior
        // (unless one of the endpoints is exempt, i.e. the start/end exit points)
        let has_exempt = exempt.contains(&idx1) || exempt.contains(&idx2);
        if !has_exempt && is_interior((p1 + p2) * 0.5, &expanded) {
            return false;
        }

        // 3. Block if it crosses the expanded boundary without being a corner-to-corner link
        if expanded.intersects_segment(p1, p2) {
            let corners = expanded.corners();
            let p1_is_corner = corners.iter().any(|c| c.distance_to(p1) < 0.1);
            let p2_is_corner = corners.iter().any(|c| c.distance_to(p2) < 0.1);

            if !p1_is_corner && !p2_is_corner {
                return false;
            }
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rotational_angle() {
        let center = Point::new(0.0, 0.0);
        let right = Point::new(1.0, 0.0);
        let up = Point::new(0.0, 1.0);
        let left = Point::new(-1.0, 0.0);
        let down = Point::new(0.0, -1.0);

        let a_right = rotational_angle(right, center);
        let a_up = rotational_angle(up, center);
        let a_left = rotational_angle(left, center);
        let a_down = rotational_angle(down, center);

        assert!((a_right - 0.0).abs() < 1e-10);
        assert!((a_up - std::f64::consts::FRAC_PI_2).abs() < 1e-10);
        assert!(a_left.abs() > 2.0);
        assert!(a_down < 0.0);
    }

    #[test]
    fn test_sweep_empty_obstacles() {
        let vertices = vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)];
        let edges = build_obstacle_edges(&[]);
        let result = angular_sweep_visibility(&vertices, &edges);
        assert_eq!(result.visible_edges.len(), 1);
    }

    #[test]
    fn test_naive_visibility_no_obstacles() {
        let vertices = vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)];
        let visible = naive_visibility(&vertices, &[], 45.0);
        assert_eq!(visible.len(), 1);
    }

    #[test]
    fn test_naive_visibility_around_obstacle() {
        let vertices = vec![
            Point::new(0.0, 50.0),
            Point::new(100.0, 50.0),
            Point::new(30.0, 30.0),
            Point::new(70.0, 30.0),
            Point::new(70.0, 70.0),
            Point::new(30.0, 70.0),
        ];
        let obstacle = Rect::new(40.0, 40.0, 20.0, 20.0);
        let visible = naive_visibility(&vertices, &[obstacle], 5.0);
        assert!(visible.len() >= 1, "Should find at least some visible edges");
    }

    #[test]
    fn test_ray_segment_intersection() {
        let ray_start = Point::new(0.0, 0.0);
        let ray_end = Point::new(10.0, 0.0);
        let seg_a = Point::new(5.0, -5.0);
        let seg_b = Point::new(5.0, 5.0);

        let result = ray_segment_intersection(ray_start, ray_end, seg_a, seg_b);
        assert!(result.is_some());
        let pt = result.unwrap();
        assert!((pt.x - 5.0).abs() < 1e-10);
        assert!((pt.y - 0.0).abs() < 1e-10);
    }

    #[test]
    fn test_ray_no_intersection() {
        let ray_start = Point::new(0.0, 0.0);
        let ray_end = Point::new(10.0, 0.0);
        let seg_a = Point::new(5.0, 5.0);
        let seg_b = Point::new(5.0, 10.0);

        let result = ray_segment_intersection(ray_start, ray_end, seg_a, seg_b);
        assert!(result.is_none(), "Ray along x-axis should not intersect segment above it");
    }
}
