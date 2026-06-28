use crate::domain::relation_engine::geometry::{Point, Rect, sample_cubic_bezier, is_horiz};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::{RoutingStrategy, RouteContext, node_clearance};

pub struct BezierRouting;

impl RoutingStrategy for BezierRouting {
    fn route(&self, ctx: &RouteContext, _state: &CanvasState) -> (Vec<Point>, PathType) {
        if ctx.from_normal.dot(ctx.to_normal) > 0.5 {
            return routed_bezier(ctx.start, ctx.end, ctx.from_normal, ctx.to_normal, ctx.from_rect, ctx.to_rect, &ctx.config);
        }
        standard_bezier(ctx.start, ctx.end, ctx.from_normal, ctx.to_normal, &ctx.config)
    }
}

fn standard_bezier(
    start: Point, end: Point,
    from_normal: Point, to_normal: Point,
    config: &RelationEngineConfig,
) -> (Vec<Point>, PathType) {
    let distance = start.distance_to(end);
    let proj = (distance * config.routing.bezier_projection_factor)
        .min(config.routing.bezier_clamp_max)
        .max(config.routing.bezier_clamp_min.min(distance * 0.5));

    let cp1 = start + from_normal * proj;
    let cp2 = end + to_normal * proj;
    let points = sample_cubic_bezier(start, cp1, cp2, end, 32);
    (points, PathType::CubicBezier)
}

fn routed_bezier(
    start: Point, end: Point,
    from_normal: Point, to_normal: Point,
    from_rect: Rect, to_rect: Rect,
    config: &RelationEngineConfig,
) -> (Vec<Point>, PathType) {
    let ext = node_clearance(start, from_normal, from_rect)
        .max(node_clearance(end, to_normal, to_rect));

    let horizontal = is_horiz(from_normal);

    let detour = if horizontal {
        let mx = if from_normal.x > 0.0 {
            start.x.max(end.x) + ext
        } else {
            start.x.min(end.x) - ext
        };
        let node_mid_y = (from_rect.top() + from_rect.bottom()) / 2.0;
        let detour_y = if start.y < node_mid_y {
            from_rect.top() - ext
        } else {
            from_rect.bottom() + ext
        };
        (Point::new(mx, start.y), Point::new(mx, detour_y), Point::new(end.x, detour_y))
    } else {
        let my = if from_normal.y > 0.0 {
            start.y.max(end.y) + ext
        } else {
            start.y.min(end.y) - ext
        };
        let node_mid_x = (from_rect.left() + from_rect.right()) / 2.0;
        let detour_x = if start.x < node_mid_x {
            from_rect.left() - ext
        } else {
            from_rect.right() + ext
        };
        (Point::new(start.x, my), Point::new(detour_x, my), Point::new(detour_x, end.y))
    };

    let (p1, p2, p3) = detour;
    let distance = start.distance_to(end);
    let proj = (distance * config.routing.bezier_projection_factor)
        .min(config.routing.bezier_clamp_max)
        .max(config.routing.bezier_clamp_min.min(distance * 0.5));

    let cp1a = start + from_normal * proj;
    let cp1b = p1 + (p2 - p1).normalized() * proj;
    let seg1 = sample_cubic_bezier(start, cp1a, cp1b, p2, 16);

    let cp2a = p2 + (p3 - p2).normalized() * proj;
    let cp2b = end + to_normal * proj;
    let seg2 = sample_cubic_bezier(p2, cp2a, cp2b, p3, 16);

    let cp3a = p3 + (p1 - p2).normalized() * proj;
    let cp3b = end + to_normal * proj;
    let seg3 = sample_cubic_bezier(p3, cp3a, cp3b, end, 16);

    let mut points = seg1;
    points.extend_from_slice(&seg2[1..]);
    points.extend_from_slice(&seg3[1..]);

    (points, PathType::CubicBezier)
}
