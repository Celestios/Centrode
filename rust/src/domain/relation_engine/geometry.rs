use std::ops::{Add, Mul, Sub};

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    pub fn zero() -> Self {
        Self { x: 0.0, y: 0.0 }
    }

    pub fn distance_to(self, other: Point) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        (dx * dx + dy * dy).sqrt()
    }

    pub fn distance_sq(self, other: Point) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        dx * dx + dy * dy
    }

    pub fn length(self) -> f64 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    pub fn normalized(self) -> Point {
        let len = self.length();
        if len < 1e-10 {
            Point::zero()
        } else {
            Point {
                x: self.x / len,
                y: self.y / len,
            }
        }
    }

    pub fn dot(self, other: Point) -> f64 {
        self.x * other.x + self.y * other.y
    }

    pub fn perpendicular(self) -> Point {
        Point {
            x: -self.y,
            y: self.x,
        }
    }

    pub fn lerp(self, other: Point, t: f64) -> Point {
        Point {
            x: self.x + (other.x - self.x) * t,
            y: self.y + (other.y - self.y) * t,
        }
    }

    pub fn direction(self) -> f64 {
        self.y.atan2(self.x)
    }
}

impl Add for Point {
    type Output = Point;
    fn add(self, rhs: Point) -> Point {
        Point {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
        }
    }
}

impl Sub for Point {
    type Output = Point;
    fn sub(self, rhs: Point) -> Point {
        Point {
            x: self.x - rhs.x,
            y: self.y - rhs.y,
        }
    }
}

impl Mul<f64> for Point {
    type Output = Point;
    fn mul(self, rhs: f64) -> Point {
        Point {
            x: self.x * rhs,
            y: self.y * rhs,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Rect {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Rect {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self {
            x,
            y,
            width,
            height,
        }
    }

    pub fn left(&self) -> f64 {
        self.x
    }

    pub fn right(&self) -> f64 {
        self.x + self.width
    }

    pub fn top(&self) -> f64 {
        self.y
    }

    pub fn bottom(&self) -> f64 {
        self.y + self.height
    }

    pub fn center(&self) -> Point {
        Point {
            x: self.x + self.width / 2.0,
            y: self.y + self.height / 2.0,
        }
    }

    pub fn contains(&self, p: Point) -> bool {
        p.x >= self.left()
            && p.x <= self.right()
            && p.y >= self.top()
            && p.y <= self.bottom()
    }

    pub fn expand(&self, margin: f64) -> Rect {
        Rect {
            x: self.x - margin,
            y: self.y - margin,
            width: self.width + margin * 2.0,
            height: self.height + margin * 2.0,
        }
    }

    pub fn corners(&self) -> [Point; 4] {
        [
            Point::new(self.left(), self.top()),
            Point::new(self.right(), self.top()),
            Point::new(self.right(), self.bottom()),
            Point::new(self.left(), self.bottom()),
        ]
    }

    pub fn intersects_segment(&self, p1: Point, p2: Point) -> bool {
        if self.contains(p1) || self.contains(p2) {
            return true;
        }
        let corners = self.corners();
        for i in 0..4 {
            let c1 = corners[i];
            let c2 = corners[(i + 1) % 4];
            if segments_intersect(p1, p2, c1, c2) {
                return true;
            }
        }
        false
    }
}

pub fn segments_intersect(a: Point, b: Point, c: Point, d: Point) -> bool {
    fn ccw(p1: Point, p2: Point, p3: Point) -> f64 {
        (p3.y - p1.y) * (p2.x - p1.x) - (p2.y - p1.y) * (p3.x - p1.x)
    }

    let val1 = ccw(a, b, c);
    let val2 = ccw(a, b, d);
    let val3 = ccw(c, d, a);
    let val4 = ccw(c, d, b);

    if ((val1 > 0.0 && val2 < 0.0) || (val1 < 0.0 && val2 > 0.0))
        && ((val3 > 0.0 && val4 < 0.0) || (val3 < 0.0 && val4 > 0.0))
    {
        return true;
    }

    fn on_segment(p: Point, q: Point, r: Point) -> bool {
        q.x <= p.x.max(r.x)
            && q.x >= p.x.min(r.x)
            && q.y <= p.y.max(r.y)
            && q.y >= p.y.min(r.y)
    }

    if val1 == 0.0 && on_segment(a, c, b) {
        return true;
    }
    if val2 == 0.0 && on_segment(a, d, b) {
        return true;
    }
    if val3 == 0.0 && on_segment(c, a, d) {
        return true;
    }
    if val4 == 0.0 && on_segment(c, b, d) {
        return true;
    }

    false
}

pub fn segment_length(a: Point, b: Point) -> f64 {
    a.distance_to(b)
}

pub fn polyline_length(points: &[Point]) -> f64 {
    points
        .windows(2)
        .map(|w| w[0].distance_to(w[1]))
        .sum()
}

pub fn polyline_midpoint(points: &[Point]) -> Point {
    if points.is_empty() {
        return Point::zero();
    }
    if points.len() == 1 {
        return points[0];
    }

    let total = polyline_length(points);
    if total < 1e-10 {
        return points[0];
    }

    let target = total * 0.5;
    let mut accum = 0.0;

    for w in points.windows(2) {
        let seg_len = w[0].distance_to(w[1]);
        if accum + seg_len >= target {
            let t = (target - accum) / seg_len;
            return w[0].lerp(w[1], t);
        }
        accum += seg_len;
    }

    *points.last().unwrap()
}

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

        result.push(start_point);
        result.push(end_point);
    }

    result.push(*points.last().unwrap());
    result
}
