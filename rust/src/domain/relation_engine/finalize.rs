use std::collections::HashMap;
use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::types::{InputNode, InputEdge};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::{ComputedRelation, LabelAnchor};
use crate::domain::styles::{EndpointShape, PortSide};
use crate::domain::relation_engine::path_finder::port::port_position;

fn intersect_line_rect(p0: Point, p1: Point, rect: Rect) -> Option<Point> {
    rect.intersect_segment_t(p0, p1).map(|t| p0.lerp(p1, t))
}

fn compute_tangents(path: &[Point]) -> (Point, Point) {
    let start = if path.len() >= 2 {
        (path[1] - path[0]).normalize()
    } else {
        Point::new(1.0, 0.0)
    };

    let end = if path.len() >= 2 {
        let n = path.len();
        (path[n - 1] - path[n - 2]).normalize()
    } else {
        Point::new(1.0, 0.0)
    };

    (start, end)
}

fn polyline_midpoint(path: &[Point]) -> Point {
    if path.is_empty() {
        return Point::new(0.0, 0.0);
    }
    if path.len() == 1 {
        return path[0];
    }
    let mut total_len = 0.0;
    for w in path.windows(2) {
        total_len += w[0].distance_to(w[1]);
    }
    let target = total_len / 2.0;
    let mut current_len = 0.0;
    for w in path.windows(2) {
        let d = w[0].distance_to(w[1]);
        if current_len + d >= target {
            let t = if d > 0.0 { (target - current_len) / d } else { 0.0 };
            return w[0].lerp(w[1], t);
        }
        current_len += d;
    }
    *path.last().unwrap()
}

fn compute_body_widths(
    path: &[Point],
    body_type: crate::domain::relation_engine::config::BodyType,
    base_width: f64,
    config: &RelationEngineConfig,
) -> Vec<f64> {
    let n = path.len();
    if n == 0 {
        return vec![];
    }
    match body_type {
        crate::domain::relation_engine::config::BodyType::Uniform | crate::domain::relation_engine::config::BodyType::Bundled => {
            vec![base_width; n]
        }
        crate::domain::relation_engine::config::BodyType::Taper => {
            let mut lengths = vec![0.0; n];
            let mut total_len = 0.0;
            for i in 1..n {
                total_len += path[i].distance_to(path[i - 1]);
                lengths[i] = total_len;
            }
            let start_w = config.body.taper_start_width;
            let end_w = config.body.taper_end_width;
            let mut widths = Vec::with_capacity(n);
            for i in 0..n {
                let t = if total_len > 0.0 { lengths[i] / total_len } else { 0.0 };
                widths.push(start_w + (end_w - start_w) * t);
            }
            widths
        }
        crate::domain::relation_engine::config::BodyType::WidthModulate => {
            let mut lengths = vec![0.0; n];
            let mut total_len = 0.0;
            for i in 1..n {
                total_len += path[i].distance_to(path[i - 1]);
                lengths[i] = total_len;
            }
            let amp = config.body.width_modulate_amplitude;
            let freq = config.body.width_modulate_frequency;
            let mut widths = Vec::with_capacity(n);
            for i in 0..n {
                let w = base_width + amp * (lengths[i] * (freq / 300.0) * 2.0 * std::f64::consts::PI).sin();
                widths.push(w.max(0.1));
            }
            widths
        }
    }
}

fn compute_bbox(path: &[Point], padding: f64) -> Rect {
    if path.is_empty() {
        return Rect::new(0.0, 0.0, 0.0, 0.0);
    }
    let mut min_x = path[0].x;
    let mut max_x = path[0].x;
    let mut min_y = path[0].y;
    let mut max_y = path[0].y;
    for p in path {
        if p.x < min_x { min_x = p.x; }
        if p.x > max_x { max_x = p.x; }
        if p.y < min_y { min_y = p.y; }
        if p.y > max_y { max_y = p.y; }
    }
    Rect::new(
        min_x - padding,
        min_y - padding,
        (max_x - min_x) + 2.0 * padding,
        (max_y - min_y) + 2.0 * padding,
    )
}

pub fn finalize_relation(
    result: &mut ComputedRelation,
    edge: &InputEdge,
    node_map: &HashMap<String, InputNode>,
    config: &RelationEngineConfig,
) {
    // 1. Line snapping / center-to-center trimming
    if edge.from_side.is_none() || edge.to_side.is_none() {
        if let (Some(start_node), Some(end_node)) = (node_map.get(&edge.from_node_id), node_map.get(&edge.to_node_id)) {
            let start_bbox = start_node.bounding_box();
            let end_bbox = end_node.bounding_box();
            let center_from = Point::new(start_node.x + start_node.width / 2.0, start_node.y + start_node.height / 2.0);
            let center_to = Point::new(end_node.x + end_node.width / 2.0, end_node.y + end_node.height / 2.0);
            if !result.path_points.is_empty() {
                let n = result.path_points.len();
                if edge.from_side.is_none() {
                    result.path_points[0] = intersect_line_rect(center_from, center_to, start_bbox).unwrap_or(result.path_points[0]);
                }
                if edge.to_side.is_none() {
                    result.path_points[n - 1] = intersect_line_rect(center_to, center_from, end_bbox).unwrap_or(result.path_points[n - 1]);
                }
            }
        }
    }

    if result.path_points.is_empty() {
        return;
    }

    // 2. Tangents
    let (st, et) = compute_tangents(&result.path_points);
    result.start_tangent = st;
    result.end_tangent = et;

    // 3. Endpoint Shapes & Directions
    let start_node = node_map.get(&edge.from_node_id);
    let end_node = node_map.get(&edge.to_node_id);

    let start_shape = edge.style.as_ref().and_then(|s| s.start_shape).unwrap_or(match config.endpoint.default_start_shape {
        crate::domain::relation_engine::config::EndpointShapeType::None => EndpointShape::None,
        crate::domain::relation_engine::config::EndpointShapeType::Arrow => EndpointShape::Arrow,
        crate::domain::relation_engine::config::EndpointShapeType::OpenArrow => EndpointShape::OpenArrow,
        crate::domain::relation_engine::config::EndpointShapeType::Circle => EndpointShape::Circle,
        crate::domain::relation_engine::config::EndpointShapeType::Diamond => EndpointShape::Diamond,
        crate::domain::relation_engine::config::EndpointShapeType::Square => EndpointShape::Square,
    });

    let end_shape = edge.style.as_ref().and_then(|s| s.end_shape).unwrap_or(match config.endpoint.default_end_shape {
        crate::domain::relation_engine::config::EndpointShapeType::None => EndpointShape::None,
        crate::domain::relation_engine::config::EndpointShapeType::Arrow => EndpointShape::Arrow,
        crate::domain::relation_engine::config::EndpointShapeType::OpenArrow => EndpointShape::OpenArrow,
        crate::domain::relation_engine::config::EndpointShapeType::Circle => EndpointShape::Circle,
        crate::domain::relation_engine::config::EndpointShapeType::Diamond => EndpointShape::Diamond,
        crate::domain::relation_engine::config::EndpointShapeType::Square => EndpointShape::Square,
    });

    result.start_endpoint = start_shape;
    result.end_endpoint = end_shape;

    // Direction (orthogonal snaps to port outward normal angle)
    if let (Some(start_node), Some(side)) = (start_node, edge.from_side.as_ref()) {
        result.start_direction = port_position(start_node, Some(side)).1;
    } else {
        result.start_direction = st.y.atan2(st.x) + std::f64::consts::PI;
    }

    if let (Some(end_node), Some(side)) = (end_node, edge.to_side.as_ref()) {
        result.end_direction = port_position(end_node, Some(side)).1;
    } else {
        result.end_direction = et.y.atan2(et.x);
    }

    // Dynamic scale based on node size
    let start_node_size = start_node.map(|n| n.width.min(n.height)).unwrap_or(80.0);
    let end_node_size = end_node.map(|n| n.width.min(n.height)).unwrap_or(80.0);
    let start_scale = (start_node_size / 80.0).clamp(0.5, 2.0);
    let end_scale = (end_node_size / 80.0).clamp(0.5, 2.0);

    let start_arrow_sz = config.endpoint.arrow_size * start_scale;
    let end_arrow_sz = config.endpoint.arrow_size * end_scale;

    // 4. Body Widths & Types
    let base_width = edge.style.as_ref().map(|s| s.stroke_width as f64).unwrap_or(2.0);
    let body_type_str = edge.style.as_ref().map(|s| s.body_strategy.as_str()).unwrap_or("uniform");
    let body_type = match body_type_str {
        "uniform" => crate::domain::relation_engine::config::BodyType::Uniform,
        "taper" => crate::domain::relation_engine::config::BodyType::Taper,
        "widthModulate" => crate::domain::relation_engine::config::BodyType::WidthModulate,
        "bundled" => crate::domain::relation_engine::config::BodyType::Bundled,
        _ => config.body.default_type.clone(),
    };
    result.body_type = body_type.clone();
    result.body_widths = compute_body_widths(&result.path_points, body_type, base_width, config);

    // 5. Label Position & Anchor
    result.label_position = polyline_midpoint(&result.path_points);
    result.label_anchor = LabelAnchor::Center;

    // 6. BBox + Arrow Centers
    let padding = start_arrow_sz.max(end_arrow_sz).max(base_width) + 10.0;
    result.bbox = compute_bbox(&result.path_points, padding);

    let n = result.path_points.len();
    result.start_point = result.path_points[0];
    result.end_point = result.path_points[n - 1];

    result.start_arrow_center = result.start_point + st * (start_arrow_sz * 0.5);
    result.end_arrow_center = result.end_point - et * (end_arrow_sz * 0.5);

    // 7. Dependencies
    result.depends_on_nodes = vec![edge.from_node_id.clone(), edge.to_node_id.clone()];
}
