use super::Point;

pub fn cubic_bezier_point(
    p0: Point,
    p1: Point,
    p2: Point,
    p3: Point,
    t: f64,
) -> Point {
    let mt = 1.0 - t;
    let mt2 = mt * mt;
    let mt3 = mt2 * mt;
    let t2 = t * t;
    let t3 = t2 * t;

    Point {
        x: mt3 * p0.x + 3.0 * mt2 * t * p1.x + 3.0 * mt * t2 * p2.x + t3 * p3.x,
        y: mt3 * p0.y + 3.0 * mt2 * t * p1.y + 3.0 * mt * t2 * p2.y + t3 * p3.y,
    }
}

pub fn sample_cubic_bezier(
    p0: Point,
    p1: Point,
    p2: Point,
    p3: Point,
    n: usize,
) -> Vec<Point> {
    (0..=n)
        .map(|i| {
            let t = i as f64 / n as f64;
            cubic_bezier_point(p0, p1, p2, p3, t)
        })
        .collect()
}

pub fn quadratic_bezier_point(p0: Point, p1: Point, p2: Point, t: f64) -> Point {
    let mt = 1.0 - t;
    Point {
        x: mt * mt * p0.x + 2.0 * mt * t * p1.x + t * t * p2.x,
        y: mt * mt * p0.y + 2.0 * mt * t * p1.y + t * t * p2.y,
    }
}

pub fn sample_quadratic_bezier(p0: Point, p1: Point, p2: Point, n: usize) -> Vec<Point> {
    (0..=n)
        .map(|i| {
            let t = i as f64 / n as f64;
            quadratic_bezier_point(p0, p1, p2, t)
        })
        .collect()
}

pub fn round_corners(points: &[Point], radius: f64) -> Vec<Point> {
    if points.len() < 3 || radius < 1e-6 {
        return points.to_vec();
    }

    let mut result = Vec::with_capacity(points.len() * 2);
    result.push(points[0]);

    for i in 1..points.len() - 1 {
        let prev = points[i - 1];
        let curr = points[i];
        let next = points[i + 1];

        let d1 = curr - prev;
        let d2 = next - curr;
        let len1 = d1.length();
        let len2 = d2.length();

        if len1 < 1e-6 || len2 < 1e-6 {
            result.push(curr);
            continue;
        }

        let r = radius.min(len1 / 2.0).min(len2 / 2.0);

        let start_point = prev + d1.normalized() * (len1 - r);
        let end_point = curr + d2.normalized() * r;

        let corner_samples = sample_quadratic_bezier(start_point, curr, end_point, 8);
        result.extend(corner_samples);
    }

    result.push(*points.last().unwrap());
    result.dedup_by(|a, b| a.distance_to(*b) < 1e-6);
    result
}
