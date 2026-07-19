use std::ops::{Add, Mul, Sub};
use flutter_rust_bridge::frb;

#[derive(Clone, Copy, Debug, PartialEq)]
#[frb]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    pub fn distance_to(self, other: Point) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        (dx * dx + dy * dy).sqrt()
    }

    pub fn lerp(self, other: Point, t: f64) -> Point {
        Point::new(self.x + (other.x - self.x) * t, self.y + (other.y - self.y) * t)
    }

    pub fn length(self) -> f64 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    pub fn normalize(self) -> Point {
        let len = self.length().max(1e-12);
        Point::new(self.x / len, self.y / len)
    }
}

impl Add for Point {
    type Output = Point;
    fn add(self, rhs: Point) -> Point {
        Point::new(self.x + rhs.x, self.y + rhs.y)
    }
}

impl Sub for Point {
    type Output = Point;
    fn sub(self, rhs: Point) -> Point {
        Point::new(self.x - rhs.x, self.y - rhs.y)
    }
}

impl Mul<f64> for Point {
    type Output = Point;
    fn mul(self, rhs: f64) -> Point {
        Point::new(self.x * rhs, self.y * rhs)
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
#[frb]
pub struct Rect {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Rect {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self { x, y, width, height }
    }

    pub fn contains(self, pt: Point) -> bool {
        pt.x >= self.x && pt.x <= self.x + self.width && pt.y >= self.y && pt.y <= self.y + self.height
    }

    pub fn intersect_segment_t(self, p0: Point, p1: Point) -> Option<f64> {
        let dx = p1.x - p0.x;
        let dy = p1.y - p0.y;

        let mut t0: f64 = 0.0;
        let mut t1: f64 = 1.0;

        if dx.abs() < 1e-9 {
            if p0.x < self.x || p0.x > self.x + self.width {
                return None;
            }
        } else {
            let r1 = (self.x - p0.x) / dx;
            let r2 = (self.x + self.width - p0.x) / dx;
            let (r_min, r_max) = if r1 < r2 { (r1, r2) } else { (r2, r1) };
            t0 = t0.max(r_min);
            t1 = t1.min(r_max);
        }

        if dy.abs() < 1e-9 {
            if p0.y < self.y || p0.y > self.y + self.height {
                return None;
            }
        } else {
            let r1 = (self.y - p0.y) / dy;
            let r2 = (self.y + self.height - p0.y) / dy;
            let (r_min, r_max) = if r1 < r2 { (r1, r2) } else { (r2, r1) };
            t0 = t0.max(r_min);
            t1 = t1.min(r_max);
        }

        if t0 <= t1 && t0 >= 0.0 && t0 <= 1.0 {
            Some(t0)
        } else {
            None
        }
    }

    pub fn intersects_segment(self, a: Point, b: Point) -> bool {
        self.contains(a) || self.contains(b) || self.intersect_segment_t(a, b).is_some()
    }
}

pub fn distance_to_segment(p: Point, a: Point, b: Point) -> f64 {
    let dx = b.x - a.x;
    let dy = b.y - a.y;
    let len_sq = dx * dx + dy * dy;
    if len_sq < 1e-12 {
        return p.distance_to(a);
    }
    let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len_sq;
    let t = t.clamp(0.0, 1.0);
    let closest = Point::new(a.x + t * dx, a.y + t * dy);
    p.distance_to(closest)
}

pub fn polyline_length(points: &[Point]) -> f64 {
    points.windows(2).map(|w| w[0].distance_to(w[1])).sum()
}

fn cross(a: Point, b: Point, c: Point) -> f64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

pub fn point_distance_to_rect(p: Point, r: Rect) -> f64 {
    let dx = if p.x < r.x { r.x - p.x } else if p.x > r.x + r.width { p.x - (r.x + r.width) } else { 0.0 };
    let dy = if p.y < r.y { r.y - p.y } else if p.y > r.y + r.height { p.y - (r.y + r.height) } else { 0.0 };
    (dx * dx + dy * dy).sqrt()
}

pub fn segments_intersect(a: Point, b: Point, c: Point, d: Point) -> bool {
    let d1 = cross(a, b, c);
    let d2 = cross(a, b, d);
    let d3 = cross(c, d, a);
    let d4 = cross(c, d, b);
    ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0))
        && ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0))
}

pub fn smooth_path_corners(
    points: &[Point],
    corner_radius: f64,
    num_samples_per_corner: usize,
) -> Vec<Point> {
    if points.len() <= 2 || corner_radius <= 0.0 || num_samples_per_corner == 0 {
        return points.to_vec();
    }

    let mut result = Vec::new();
    result.push(points[0]);

    for i in 1..points.len() - 1 {
        let prev = points[i - 1];
        let curr = points[i];
        let next = points[i + 1];

        let v1 = Point::new(curr.x - prev.x, curr.y - prev.y);
        let v2 = Point::new(next.x - curr.x, next.y - curr.y);

        let d1 = v1.length();
        let d2 = v2.length();

        if d1 < 1e-6 || d2 < 1e-6 {
            result.push(curr);
            continue;
        }

        let v1_unit = v1.normalize();
        let v2_unit = v2.normalize();

        let cross = v1_unit.x * v2_unit.y - v1_unit.y * v2_unit.x;
        if cross.abs() < 1e-6 {
            result.push(curr);
            continue;
        }

        // Determine deflection angle beta (actual turning angle between segments)
        let beta = (v1_unit.x * v2_unit.x + v1_unit.y * v2_unit.y).clamp(-1.0, 1.0).acos();

        // Determine tangent distance
        let t_dist = corner_radius * (beta / 2.0).tan();

        // Determine effective corner radius (cannot exceed half of either segment)
        let effective_r = if t_dist > d1 / 2.0 || t_dist > d2 / 2.0 {
            let max_t = (d1 / 2.0).min(d2 / 2.0);
            corner_radius * (max_t / t_dist)
        } else {
            corner_radius
        };

        let t_dist = effective_r * (beta / 2.0).tan();
        if t_dist < 1e-3 {
            result.push(curr);
            continue;
        }

        // Arc start and end
        let p_start = Point::new(curr.x - v1_unit.x * t_dist, curr.y - v1_unit.y * t_dist);

        // Circle center C
        let turn_sign = cross.signum();
        let n1 = Point::new(-v1_unit.y * turn_sign, v1_unit.x * turn_sign);
        let c_pt = Point::new(p_start.x + n1.x * effective_r, p_start.y + n1.y * effective_r);

        let r1 = Point::new(p_start.x - c_pt.x, p_start.y - c_pt.y);
        let u2 = Point::new(-r1.y * turn_sign, r1.x * turn_sign);

        for j in 0..=num_samples_per_corner {
            let t = j as f64 / num_samples_per_corner as f64;
            let phi = t * beta;
            let p_arc = Point::new(
                c_pt.x + r1.x * phi.cos() + u2.x * phi.sin(),
                c_pt.y + r1.y * phi.cos() + u2.y * phi.sin(),
            );
            
            if let Some(last) = result.last() {
                if (p_arc.x - last.x).abs() > 1e-6 || (p_arc.y - last.y).abs() > 1e-6 {
                    result.push(p_arc);
                }
            } else {
                result.push(p_arc);
            }
        }
    }

    let last = *points.last().unwrap();
    if let Some(prev) = result.last() {
        if (last.x - prev.x).abs() > 1e-6 || (last.y - prev.y).abs() > 1e-6 {
            result.push(last);
        }
    } else {
        result.push(last);
    }

    result
}
