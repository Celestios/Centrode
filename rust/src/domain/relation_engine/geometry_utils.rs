use crate::domain::relation_engine::geometry::Point;

/// Evaluates a single cubic Bezier point at parameter `t` (0.0 to 1.0).
pub fn evaluate_cubic_bezier_point(p0: Point, p1: Point, p2: Point, p3: Point, t: f64) -> Point {
    let u = 1.0 - t;
    p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t)
}

/// Evaluates the tangent vector of a cubic Bezier curve at parameter `t` (0.0 to 1.0).
pub fn evaluate_cubic_bezier_tangent(p0: Point, p1: Point, p2: Point, p3: Point, t: f64) -> Point {
    let u = 1.0 - t;
    (p1 - p0) * (3.0 * u * u) + (p2 - p1) * (6.0 * u * t) + (p3 - p2) * (3.0 * t * t)
}

/// Evaluates a list of sample points along a cubic Bezier curve.
pub fn evaluate_cubic_bezier(
    p0: Point,
    p1: Point,
    p2: Point,
    p3: Point,
    num_samples: usize,
) -> Vec<Point> {
    if num_samples < 2 {
        return vec![p0, p3];
    }
    let mut points = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f64 / (num_samples - 1) as f64;
        points.push(evaluate_cubic_bezier_point(p0, p1, p2, p3, t));
    }
    points
}
