use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::sections::{EndpartResult, AdapterResult};

#[derive(Debug, Clone, Copy)]
pub enum AdapterResolver {
    Bezier,
    Miter,
}

impl AdapterResolver {
    #[inline(always)]
    pub fn connect(
        &self,
        endpart: &EndpartResult,
        body_anchor: Point,
        path_buffer: &mut Vec<Point>,
    ) -> AdapterResult {
        match self {
            Self::Bezier => bezier_connect(endpart, body_anchor, path_buffer),
            Self::Miter => miter_connect(endpart, body_anchor, path_buffer),
        }
    }
}

#[inline(always)]
fn bezier_connect(
    endpart: &EndpartResult,
    body_anchor: Point,
    path_buffer: &mut Vec<Point>,
) -> AdapterResult {
    let start_idx = path_buffer.len();
    let start = endpart.exit_point;
    let direction = endpart.exit_direction;

    let dx = body_anchor.x - start.x;
    let dy = body_anchor.y - start.y;
    let dist = (dx * dx + dy * dy).sqrt();

    if dist < 1.0 {
        path_buffer.push(body_anchor);
        return AdapterResult {
            body_anchor,
            point_count: 1,
        };
    }

    let dir_vec = Point::new(direction.cos(), direction.sin());
    let cp1 = start + dir_vec * dist * 0.33;
    let cp2 = body_anchor - dir_vec * dist * 0.33;

    let segments = 6;
    for i in 1..=segments {
        let t = i as f64 / segments as f64;
        let mt = 1.0 - t;
        let p = Point::new(
            mt * mt * mt * start.x + 3.0 * mt * mt * t * cp1.x + 3.0 * mt * t * t * cp2.x + t * t * t * body_anchor.x,
            mt * mt * mt * start.y + 3.0 * mt * mt * t * cp1.y + 3.0 * mt * t * t * cp2.y + t * t * t * body_anchor.y,
        );
        path_buffer.push(p);
    }

    AdapterResult {
        body_anchor,
        point_count: path_buffer.len() - start_idx,
    }
}

#[inline(always)]
fn miter_connect(
    _endpart: &EndpartResult,
    body_anchor: Point,
    path_buffer: &mut Vec<Point>,
) -> AdapterResult {
    let start_idx = path_buffer.len();
    path_buffer.push(body_anchor);

    AdapterResult {
        body_anchor,
        point_count: path_buffer.len() - start_idx,
    }
}

pub fn connect_adapter(
    endpart: &EndpartResult,
    body_anchor: Point,
    path_buffer: &mut Vec<Point>,
) -> AdapterResult {
    AdapterResolver::Bezier.connect(endpart, body_anchor, path_buffer)
}
