use super::{Point, Rect};

pub fn cubic_bspline_point(p0: Point, p1: Point, p2: Point, p3: Point, u: f64) -> Point {
    let u2 = u * u;
    let u3 = u2 * u;
    let mt = 1.0 - u;
    let mt3 = mt * mt * mt;

    let c0 = mt3 / 6.0;
    let c1 = (3.0 * u3 - 6.0 * u2 + 4.0) / 6.0;
    let c2 = (-3.0 * u3 + 3.0 * u2 + 3.0 * u + 1.0) / 6.0;
    let c3 = u3 / 6.0;

    p0 * c0 + p1 * c1 + p2 * c2 + p3 * c3
}

pub fn cubic_bspline_first_derivative(p0: Point, p1: Point, p2: Point, p3: Point, u: f64) -> Point {
    let u2 = u * u;
    let mt = 1.0 - u;
    let mt2 = mt * mt;

    let c0 = -mt2 / 2.0;
    let c1 = (3.0 * u2 - 4.0 * u) / 2.0;
    let c2 = (-3.0 * u2 + 2.0 * u + 1.0) / 2.0;
    let c3 = u2 / 2.0;

    p0 * c0 + p1 * c1 + p2 * c2 + p3 * c3
}

pub fn cubic_bspline_second_derivative(p0: Point, p1: Point, p2: Point, p3: Point, u: f64) -> Point {
    let c0 = 1.0 - u;
    let c1 = 3.0 * u - 2.0;
    let c2 = -3.0 * u + 1.0;
    let c3 = u;

    p0 * c0 + p1 * c1 + p2 * c2 + p3 * c3
}

pub fn cubic_bspline_curvature(p0: Point, p1: Point, p2: Point, p3: Point, u: f64) -> f64 {
    let d1 = cubic_bspline_first_derivative(p0, p1, p2, p3, u);
    let d2 = cubic_bspline_second_derivative(p0, p1, p2, p3, u);
    let num = d1.x * d2.y - d1.y * d2.x;
    let den = d1.x * d1.x + d1.y * d1.y;
    if den < 1e-10 {
        0.0
    } else {
        num / den.powf(1.5)
    }
}

pub fn de_casteljau_subdivide(control_points: &[Point; 4], u: f64) -> ([Point; 4], [Point; 4]) {
    let p0 = control_points[0];
    let p1 = control_points[1];
    let p2 = control_points[2];
    let p3 = control_points[3];

    let q0 = p0.lerp(p1, u);
    let q1 = p1.lerp(p2, u);
    let q2 = p2.lerp(p3, u);

    let r0 = q0.lerp(q1, u);
    let r1 = q1.lerp(q2, u);

    let s = r0.lerp(r1, u);

    ([p0, q0, r0, s], [s, r1, q2, p3])
}

pub fn convex_hull_4(points: &[Point; 4]) -> Vec<Point> {
    let mut pts = points.to_vec();
    pts.sort_by(|a, b| {
        a.x.partial_cmp(&b.x)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then(a.y.partial_cmp(&b.y).unwrap_or(std::cmp::Ordering::Equal))
    });

    pts.dedup_by(|a, b| (a.x - b.x).abs() < 1e-9 && (a.y - b.y).abs() < 1e-9);

    if pts.len() <= 2 {
        return pts;
    }

    fn cross(o: Point, a: Point, b: Point) -> f64 {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }

    let mut lower = Vec::new();
    for &p in &pts {
        while lower.len() >= 2 && cross(lower[lower.len() - 2], lower[lower.len() - 1], p) <= 1e-9 {
            lower.pop();
        }
        lower.push(p);
    }

    let mut upper = Vec::new();
    for &p in pts.iter().rev() {
        while upper.len() >= 2 && cross(upper[upper.len() - 2], upper[upper.len() - 1], p) <= 1e-9 {
            upper.pop();
        }
        upper.push(p);
    }

    lower.pop();
    upper.pop();

    lower.extend(upper);
    lower
}

pub fn sat_intersects(hull: &[Point], rect: &Rect) -> bool {
    if hull.is_empty() {
        return false;
    }

    let corners = rect.corners();

    let overlap = |axis: Point| -> bool {
        let mut min_h = f64::INFINITY;
        let mut max_h = f64::NEG_INFINITY;
        for &p in hull {
            let proj = p.dot(axis);
            if proj < min_h { min_h = proj; }
            if proj > max_h { max_h = proj; }
        }

        let mut min_r = f64::INFINITY;
        let mut max_r = f64::NEG_INFINITY;
        for &p in &corners {
            let proj = p.dot(axis);
            if proj < min_r { min_r = proj; }
            if proj > max_r { max_r = proj; }
        }

        max_h >= min_r && min_h <= max_r
    };

    if !overlap(Point::new(1.0, 0.0)) { return false; }
    if !overlap(Point::new(0.0, 1.0)) { return false; }

    let n = hull.len();
    for i in 0..n {
        let p1 = hull[i];
        let p2 = hull[(i + 1) % n];
        let edge = p2 - p1;
        let axis = edge.perpendicular();
        if !overlap(axis) {
            return false;
        }
    }

    true
}

pub fn gauss_legendre_3<F>(f: F) -> f64
where
    F: Fn(f64) -> f64,
{
    let sqrt_0_15 = 0.15_f64.sqrt();
    let u0 = 0.5 - sqrt_0_15;
    let u1 = 0.5;
    let u2 = 0.5 + sqrt_0_15;

    let w0 = 5.0 / 18.0;
    let w1 = 8.0 / 18.0;
    let w2 = 5.0 / 18.0;

    w0 * f(u0) + w1 * f(u1) + w2 * f(u2)
}

pub fn knot_vector_unification(segments: &[Vec<Point>], uniform: bool) -> (Vec<Point>, Vec<f64>) {
    if segments.is_empty() {
        return (Vec::new(), Vec::new());
    }

    let mut cp = Vec::with_capacity(3 * segments.len() + 1);
    cp.extend_from_slice(&segments[0]);
    for seg in segments.iter().skip(1) {
        cp.push(seg[1]);
        cp.push(seg[2]);
        cp.push(seg[3]);
    }

    let m = segments.len();
    let mut knots = Vec::with_capacity(3 * m + 5);

    for _ in 0..4 {
        knots.push(0.0);
    }

    if m > 1 {
        if uniform {
            for k in 1..m {
                let val = k as f64 / m as f64;
                for _ in 0..3 {
                    knots.push(val);
                }
            }
        } else {
            let mut seg_lengths = Vec::with_capacity(m);
            let mut total_length = 0.0;
            for seg in segments {
                let dist = seg[0].distance_to(seg[1])
                    + seg[1].distance_to(seg[2])
                    + seg[2].distance_to(seg[3]);
                seg_lengths.push(dist);
                total_length += dist;
            }

            if total_length < 1e-10 {
                for k in 1..m {
                    let val = k as f64 / m as f64;
                    for _ in 0..3 {
                        knots.push(val);
                    }
                }
            } else {
                let mut cum_length = 0.0;
                for k in 0..m - 1 {
                    cum_length += seg_lengths[k];
                    let val = cum_length / total_length;
                    for _ in 0..3 {
                        knots.push(val);
                    }
                }
            }
        }
    }

    for _ in 0..4 {
        knots.push(1.0);
    }

    (cp, knots)
}

pub fn bspline_basis(i: usize, p: usize, u: f64, knots: &[f64]) -> f64 {
    if p == 0 {
        let next_idx = i + 1;
        if next_idx >= knots.len() {
            return 0.0;
        }

        let t_start = knots[i];
        let t_end = knots[next_idx];

        if u >= t_start && u < t_end {
            return 1.0;
        }

        let is_last_interval = next_idx == knots.len() - 1 || (next_idx < knots.len() && (knots[next_idx] - knots[knots.len() - 1]).abs() < 1e-9);
        if is_last_interval && (u - t_end).abs() < 1e-9 {
            return 1.0;
        }

        return 0.0;
    }

    let mut sum = 0.0;

    let den1 = knots[i + p] - knots[i];
    if den1.abs() > 1e-9 {
        sum += (u - knots[i]) / den1 * bspline_basis(i, p - 1, u, knots);
    }

    let den2 = knots[i + p + 1] - knots[i + 1];
    if den2.abs() > 1e-9 {
        sum += (knots[i + p + 1] - u) / den2 * bspline_basis(i + 1, p - 1, u, knots);
    }

    sum
}

pub fn bspline_curve_point(control_points: &[Point], degree: usize, knots: &[f64], u: f64) -> Point {
    let mut pt = Point::zero();
    for i in 0..control_points.len() {
        let basis = bspline_basis(i, degree, u, knots);
        pt = pt + control_points[i] * basis;
    }
    pt
}

fn bspline_derivative_control_points(control_points: &[Point], degree: usize, knots: &[f64]) -> (Vec<Point>, Vec<f64>) {
    let n = control_points.len();
    if n <= 1 || degree == 0 {
        return (vec![Point::zero()], knots.to_vec());
    }

    let mut q = Vec::with_capacity(n - 1);
    for i in 0..(n - 1) {
        let den = knots[i + degree + 1] - knots[i + 1];
        let val = if den.abs() > 1e-9 {
            (control_points[i + 1] - control_points[i]) * (degree as f64 / den)
        } else {
            Point::zero()
        };
        q.push(val);
    }

    let q_knots = knots[1..(knots.len() - 1)].to_vec();
    (q, q_knots)
}

pub fn bspline_derivative(control_points: &[Point], degree: usize, knots: &[f64], u: f64) -> Point {
    if degree == 0 {
        return Point::zero();
    }
    let (q, q_knots) = bspline_derivative_control_points(control_points, degree, knots);
    bspline_curve_point(&q, degree - 1, &q_knots, u)
}

pub fn bspline_second_derivative(control_points: &[Point], degree: usize, knots: &[f64], u: f64) -> Point {
    if degree <= 1 {
        return Point::zero();
    }
    let (q, q_knots) = bspline_derivative_control_points(control_points, degree, knots);
    let (qq, qq_knots) = bspline_derivative_control_points(&q, degree - 1, &q_knots);
    bspline_curve_point(&qq, degree - 2, &qq_knots, u)
}

pub fn bspline_curvature(control_points: &[Point], degree: usize, knots: &[f64], u: f64) -> f64 {
    let d1 = bspline_derivative(control_points, degree, knots, u);
    let d2 = bspline_second_derivative(control_points, degree, knots, u);
    let num = d1.x * d2.y - d1.y * d2.x;
    let den = d1.x * d1.x + d1.y * d1.y;
    if den < 1e-10 {
        0.0
    } else {
        num / den.powf(1.5)
    }
}

pub fn bspline_max_curvature(control_points: &[Point], degree: usize, knots: &[f64], samples: usize) -> f64 {
    if samples <= 1 {
        return bspline_curvature(control_points, degree, knots, knots[degree]).abs();
    }
    let mut max_k = 0.0;
    let u_start = knots[degree];
    let u_end = knots[knots.len() - 1 - degree];
    for i in 0..=samples {
        let t = i as f64 / samples as f64;
        let u = u_start + (u_end - u_start) * t;
        let k = bspline_curvature(control_points, degree, knots, u).abs();
        if k > max_k {
            max_k = k;
        }
    }
    max_k
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bspline_evaluation() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 20.0);
        let p2 = Point::new(30.0, 20.0);
        let p3 = Point::new(40.0, 0.0);

        let pt0 = cubic_bspline_point(p0, p1, p2, p3, 0.0);
        let pt0_5 = cubic_bspline_point(p0, p1, p2, p3, 0.5);
        let pt1 = cubic_bspline_point(p0, p1, p2, p3, 1.0);

        assert!((pt0.x - 11.666666666666666).abs() < 1e-9);
        assert!((pt0.y - 16.666666666666667).abs() < 1e-9);

        assert!((pt1.x - 28.333333333333332).abs() < 1e-9);
        assert!((pt1.y - 16.666666666666667).abs() < 1e-9);

        let expected_x = (p0.x + 23.0 * p1.x + 23.0 * p2.x + p3.x) / 48.0;
        let expected_y = (p0.y + 23.0 * p1.y + 23.0 * p2.y + p3.y) / 48.0;
        assert!((pt0_5.x - expected_x).abs() < 1e-9);
        assert!((pt0_5.y - expected_y).abs() < 1e-9);
    }

    #[test]
    fn test_bspline_derivatives() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 20.0);
        let p2 = Point::new(30.0, 20.0);
        let p3 = Point::new(40.0, 0.0);

        let d1_0 = cubic_bspline_first_derivative(p0, p1, p2, p3, 0.0);
        let d2_0 = cubic_bspline_second_derivative(p0, p1, p2, p3, 0.0);

        assert!((d1_0.x - 15.0).abs() < 1e-9);
        assert!((d1_0.y - 10.0).abs() < 1e-9);

        assert!((d2_0.x - 10.0).abs() < 1e-9);
        assert!((d2_0.y - -20.0).abs() < 1e-9);
    }

    #[test]
    fn test_bspline_curvature() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 0.0);
        let p2 = Point::new(20.0, 0.0);
        let p3 = Point::new(30.0, 0.0);

        let k = cubic_bspline_curvature(p0, p1, p2, p3, 0.5);
        assert!(k.abs() < 1e-9);
    }

    #[test]
    fn test_de_casteljau_subdivide() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 20.0);
        let p2 = Point::new(30.0, 20.0);
        let p3 = Point::new(40.0, 0.0);

        let pts = [p0, p1, p2, p3];
        let (left, right) = de_casteljau_subdivide(&pts, 0.5);

        assert_eq!(left[0], p0);
        assert_eq!(right[3], p3);
        assert_eq!(left[3], right[0]);
    }

    #[test]
    fn test_convex_hull() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 0.0);
        let p2 = Point::new(5.0, 5.0);
        let p3 = Point::new(5.0, 2.0);

        let pts = [p0, p1, p2, p3];
        let hull = convex_hull_4(&pts);

        assert_eq!(hull.len(), 3);
        assert!(hull.contains(&p0));
        assert!(hull.contains(&p1));
        assert!(hull.contains(&p2));
        assert!(!hull.contains(&p3));
    }

    #[test]
    fn test_sat_intersects() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 0.0);
        let p2 = Point::new(5.0, 5.0);
        let p3 = Point::new(5.0, 2.0);

        let pts = [p0, p1, p2, p3];
        let hull = convex_hull_4(&pts);

        let rect_intersect = Rect::new(4.0, 1.0, 2.0, 2.0);
        let rect_disjoint = Rect::new(12.0, 12.0, 2.0, 2.0);

        assert!(sat_intersects(&hull, &rect_intersect));
        assert!(!sat_intersects(&hull, &rect_disjoint));
    }

    #[test]
    fn test_gauss_legendre() {
        let val = gauss_legendre_3(|x| x * x);
        assert!((val - 1.0 / 3.0).abs() < 1e-9);
    }

    #[test]
    fn test_knot_vector_unification() {
        let p0 = Point::new(0.0, 0.0);
        let p1 = Point::new(10.0, 20.0);
        let p2 = Point::new(30.0, 20.0);
        let p3 = Point::new(40.0, 0.0);

        let p4 = Point::new(50.0, -20.0);
        let p5 = Point::new(70.0, -20.0);
        let p6 = Point::new(80.0, 0.0);

        let seg1 = vec![p0, p1, p2, p3];
        let seg2 = vec![p3, p4, p5, p6];

        let (cp, knots) = knot_vector_unification(&[seg1, seg2], true);

        assert_eq!(cp.len(), 7);
        assert_eq!(knots.len(), 11);
        assert_eq!(knots[4], 0.5);
    }
}
