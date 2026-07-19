use crate::domain::relation_engine::geometry::Point;

fn perpendicular_distance(p: Point, a: Point, b: Point) -> f64 {
    let dx = b.x - a.x;
    let dy = b.y - a.y;
    let len = (dx * dx + dy * dy).sqrt();
    if len < 1e-12 {
        return p.distance_to(a);
    }
    (dx * (a.y - p.y) - dy * (a.x - p.x)).abs() / len
}

fn collapse_stair_steps(points: &[Point], cell_size: f64) -> Vec<Point> {
    if points.len() <= 3 {
        return points.to_vec();
    }
    let max_int = cell_size * std::f64::consts::SQRT_2;
    let mut result = points.to_vec();
    for _ in 0..result.len() {
        let mut changed = false;
        let mut i = 1;
        while i < result.len() - 2 {
            let v1 = result[i] - result[i - 1];
            let v2 = result[i + 1] - result[i];
            let v3 = result[i + 2] - result[i + 1];
            let cross1 = v1.x * v2.y - v1.y * v2.x;
            let cross2 = v2.x * v3.y - v2.y * v3.x;
            let v2_len = (v2.x * v2.x + v2.y * v2.y).sqrt();
            if cross1 * cross2 < 0.0 && v2_len <= max_int {
                result.remove(i);
                changed = true;
                continue;
            }
            i += 1;
        }
        if !changed {
            break;
        }
    }
    result
}

fn rdp_simplify(points: &[Point], epsilon: f64) -> Vec<Point> {
    if points.len() <= 2 {
        return points.to_vec();
    }
    let mut dmax = 0.0;
    let mut idx = 0;
    let (first, last) = (points[0], points[points.len() - 1]);
    for i in 1..points.len() - 1 {
        let d = perpendicular_distance(points[i], first, last);
        if d > dmax {
            dmax = d;
            idx = i;
        }
    }
    if dmax > epsilon {
        let mut left = rdp_simplify(&points[..=idx], epsilon);
        let right = rdp_simplify(&points[idx..], epsilon);
        left.pop();
        left.extend(right);
        left
    } else {
        vec![first, last]
    }
}

pub fn simplify_path(
    pts: &[Point],
    epsilon: f64,
    cell_size: f64,
    has_start_stub: bool,
    has_end_stub: bool,
) -> Vec<Point> {
    if pts.len() <= 3 {
        return pts.to_vec();
    }
    let start_idx = if has_start_stub { 1 } else { 0 };
    let end_idx = if has_end_stub {
        pts.len() - 2
    } else {
        pts.len() - 1
    };

    if start_idx >= end_idx {
        return pts.to_vec();
    }

    let middle = &pts[start_idx..=end_idx];
    let simplified = rdp_simplify(middle, epsilon);
    let collapsed = collapse_stair_steps(&simplified, cell_size);
    let simplified2 = rdp_simplify(&collapsed, epsilon);

    let mut result = pts[..start_idx].to_vec();
    result.extend(simplified2);
    result.extend(&pts[end_idx + 1..]);
    result
}
