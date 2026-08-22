use surrealdb::types::SurrealValue;

pub use crate::domain::routing::Point;

#[derive(Clone, Copy, Debug, PartialEq, SurrealValue)]
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

    pub fn min_x(&self) -> f64 { self.x }
    pub fn min_y(&self) -> f64 { self.y }
    pub fn max_x(&self) -> f64 { self.x + self.width }
    pub fn max_y(&self) -> f64 { self.y + self.height }

    pub fn expand(&self, margin: f64) -> Self {
        Self::new(
            self.x - margin,
            self.y - margin,
            self.width + 2.0 * margin,
            self.height + 2.0 * margin,
        )
    }

    pub fn overlaps(&self, other: Rect) -> bool {
        self.min_x() <= other.max_x()
            && self.max_x() >= other.min_x()
            && self.min_y() <= other.max_y()
            && self.max_y() >= other.min_y()
    }

    pub fn contains(&self, pt: Point) -> bool {
        pt.x >= self.min_x() && pt.x <= self.max_x() && pt.y >= self.min_y() && pt.y <= self.max_y()
    }

    pub fn intersect_segment_t(&self, p0: Point, p1: Point) -> Option<f64> {
        let dx = p1.x - p0.x;
        let dy = p1.y - p0.y;

        let mut t_min = 0.0f64;
        let mut t_max = 1.0f64;

        for (p, q) in [
            (-dx, p0.x - self.min_x()),
            (dx, self.max_x() - p0.x),
            (-dy, p0.y - self.min_y()),
            (dy, self.max_y() - p0.y),
        ] {
            if p == 0.0 {
                if q < 0.0 {
                    return None;
                }
            } else {
                let r = q / p;
                if p < 0.0 {
                    if r > t_max { return None; }
                    if r > t_min { t_min = r; }
                } else {
                    if r < t_min { return None; }
                    if r < t_max { t_max = r; }
                }
            }
        }
        if t_min <= t_max { Some(t_min) } else { None }
    }

    pub fn intersects_segment(&self, p0: Point, p1: Point) -> bool {
        self.intersect_segment_t(p0, p1).is_some()
    }
}

pub fn segments_intersect(p1: Point, p2: Point, p3: Point, p4: Point) -> bool {
    let ccw = |a: Point, b: Point, c: Point| {
        (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)
    };
    ccw(p1, p3, p4) != ccw(p2, p3, p4) && ccw(p1, p2, p3) != ccw(p1, p2, p4)
}

pub fn distance_to_segment(pt: Point, p1: Point, p2: Point) -> f64 {
    let l2 = (p2.x - p1.x).powi(2) + (p2.y - p1.y).powi(2);
    if l2 == 0.0 {
        return pt.distance_to(p1);
    }
    let t = (((pt.x - p1.x) * (p2.x - p1.x) + (pt.y - p1.y) * (p2.y - p1.y)) / l2).clamp(0.0, 1.0);
    let proj = Point::new(p1.x + t * (p2.x - p1.x), p1.y + t * (p2.y - p1.y));
    pt.distance_to(proj)
}

pub fn polyline_length(points: &[Point]) -> f64 {
    if points.len() < 2 {
        return 0.0;
    }
    let mut total = 0.0;
    for i in 0..points.len() - 1 {
        total += points[i].distance_to(points[i + 1]);
    }
    total
}

pub fn point_distance_to_rect(pt: Point, rect: Rect) -> f64 {
    let dx = (rect.min_x() - pt.x).max(0.0).max(pt.x - rect.max_x());
    let dy = (rect.min_y() - pt.y).max(0.0).max(pt.y - rect.max_y());
    (dx * dx + dy * dy).sqrt()
}

pub fn smooth_path_corners(path: &[Point], corner_radius: f64) -> Vec<Point> {
    if path.len() < 3 || corner_radius <= 0.0 {
        return path.to_vec();
    }
    let mut smoothed = Vec::new();
    smoothed.push(path[0]);
    for i in 1..path.len() - 1 {
        let p_prev = path[i - 1];
        let p_curr = path[i];
        let p_next = path[i + 1];

        let v1 = (p_prev - p_curr).normalize();
        let v2 = (p_next - p_curr).normalize();

        let len1 = p_curr.distance_to(p_prev);
        let len2 = p_curr.distance_to(p_next);
        let max_r = (len1 / 2.0).min(len2 / 2.0).min(corner_radius);

        if max_r <= 0.0 {
            smoothed.push(p_curr);
            continue;
        }

        let start = p_curr + v1 * max_r;
        let end = p_curr + v2 * max_r;
        smoothed.push(start);
        smoothed.push(end);
    }
    smoothed.push(*path.last().unwrap());
    smoothed
}
