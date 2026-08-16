use crate::domain::id::TypedRecordId;
use crate::domain::styles::EndpointShape;
use crate::relation_engine::computed::{ComputedRelation, LabelAnchor};
use crate::relation_engine::config;
use crate::relation_engine::config::RoutingMode;
use crate::relation_engine::geometry::{polyline_length, Point, Rect};
use crate::relation_engine::types::{InputEdge, InputNode};
use std::collections::HashMap;

fn intersect_line_rect(p0: Point, p1: Point, rect: Rect) -> Option<Point> {
    rect.intersect_segment_t(p0, p1).map(|t| p0.lerp(p1, t))
}

fn compute_tangents(path: &[Point], start_inset: f64, end_inset: f64) -> (Point, Point) {
    if path.len() < 2 {
        return (Point::new(1.0, 0.0), Point::new(1.0, 0.0));
    }
    let total_len = polyline_length(path);
    let s_inset = start_inset.clamp(1.0, 40.0).min(total_len / 2.0);
    let e_inset = end_inset.clamp(1.0, 40.0).min(total_len / 2.0);

    let start_target = inset_along_polyline(path, true, s_inset);
    let end_target = inset_along_polyline(path, false, e_inset);

    let start = if start_target.distance_to(path[0]) > 1e-6 {
        (start_target - path[0]).normalize()
    } else {
        (path[1] - path[0]).normalize()
    };

    let end = if end_target.distance_to(*path.last().unwrap()) > 1e-6 {
        (*path.last().unwrap() - end_target).normalize()
    } else {
        let n = path.len();
        (path[n - 1] - path[n - 2]).normalize()
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
    let total_len = polyline_length(path);
    let target = total_len / 2.0;
    let mut current_len = 0.0;
    for w in path.windows(2) {
        let d = w[0].distance_to(w[1]);
        if current_len + d >= target {
            let t = if d > 0.0 {
                (target - current_len) / d
            } else {
                0.0
            };
            return w[0].lerp(w[1], t);
        }
        current_len += d;
    }
    *path.last().unwrap()
}

fn inset_along_polyline(points: &[Point], from_start: bool, inset: f64) -> Point {
    if points.is_empty() {
        return Point::new(0.0, 0.0);
    }
    if points.len() == 1 {
        return points[0];
    }
    let mut remaining = inset;
    let n = points.len();
    for i in 0..n - 1 {
        let idx = if from_start { i } else { n - 1 - i };
        let next = if from_start { idx + 1 } else {
            if idx == 0 { break; }
            idx - 1
        };
        let seg_len = points[idx].distance_to(points[next]);
        if seg_len < 1e-6 {
            continue;
        }
        if remaining <= seg_len {
            let t = remaining / seg_len;
            return points[idx].lerp(points[next], t);
        }
        remaining -= seg_len;
    }
    if from_start {
        points[n - 1]
    } else {
        points[0]
    }
}

fn trim_polyline_endpoint(points: &mut Vec<Point>, from_start: bool, trim_distance: f64) {
    if trim_distance <= 0.0 || points.len() < 2 {
        return;
    }
    let mut accumulated = 0.0;
    let n = points.len();
    let mut cut_idx = if from_start { 0 } else { n - 1 };
    let mut new_endpoint = points[cut_idx];

    for step in 0..n - 1 {
        let curr_idx = if from_start { step } else { n - 1 - step };
        let next_idx = if from_start { curr_idx + 1 } else { curr_idx - 1 };

        let seg_len = points[curr_idx].distance_to(points[next_idx]);
        if accumulated + seg_len >= trim_distance {
            let remaining = trim_distance - accumulated;
            let t = if seg_len > 1e-6 { remaining / seg_len } else { 0.0 };
            new_endpoint = points[curr_idx].lerp(points[next_idx], t);
            cut_idx = curr_idx;
            break;
        }
        accumulated += seg_len;
        cut_idx = curr_idx;
        if step == n - 2 {
            new_endpoint = points[curr_idx].lerp(points[next_idx], 0.45);
        }
    }

    if from_start {
        if cut_idx > 0 {
            points.drain(0..cut_idx);
        }
        if !points.is_empty() {
            points[0] = new_endpoint;
        }
    } else {
        if cut_idx < points.len() {
            points.truncate(cut_idx + 1);
        }
        if !points.is_empty() {
            let last = points.len() - 1;
            points[last] = new_endpoint;
        }
    }
}

fn smooth_path_at_endpoint(
    points: &mut Vec<Point>,
    from_start: bool,
    base_center: Point,
    tangent: Point,
    blend_dist: f64,
) {
    if points.len() < 2 || blend_dist <= 0.0 {
        return;
    }
    let n = points.len();
    let target_dir = if from_start { tangent } else { tangent * -1.0 };
    let endpoint_idx = if from_start { 0 } else { n - 1 };
    points[endpoint_idx] = base_center;

    let mut accumulated = 0.0;
    for step in 1..n {
        let curr_idx = if from_start { step } else { n - 1 - step };
        let prev_idx = if from_start { step - 1 } else { n - step };

        let seg_len = points[prev_idx].distance_to(points[curr_idx]);
        accumulated += seg_len;
        if accumulated >= blend_dist {
            break;
        }
        let norm_t = (accumulated / blend_dist).clamp(0.0, 1.0);
        let blend_factor = (1.0 - norm_t) * (1.0 - norm_t);
        let ideal_pt = base_center + target_dir * accumulated;
        points[curr_idx] = points[curr_idx].lerp(ideal_pt, blend_factor);
    }
}

fn compute_body_widths(
    path: &[Point],
    body_type: config::BodyType,
    base_width: f64,
    config: &config::RelationEngineConfig,
) -> Vec<f64> {
    let n = path.len();
    if n == 0 {
        return vec![];
    }
    match body_type {
        config::BodyType::Uniform | config::BodyType::Bundled => {
            vec![base_width; n]
        }
        config::BodyType::Taper => {
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
                let t = if total_len > 0.0 {
                    lengths[i] / total_len
                } else {
                    0.0
                };
                widths.push(start_w + (end_w - start_w) * t);
            }
            widths
        }
        config::BodyType::WidthModulate => {
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
                let w = base_width
                    + amp * (lengths[i] * (freq / 300.0) * 2.0 * std::f64::consts::PI).sin();
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
        if p.x < min_x {
            min_x = p.x;
        }
        if p.x > max_x {
            max_x = p.x;
        }
        if p.y < min_y {
            min_y = p.y;
        }
        if p.y > max_y {
            max_y = p.y;
        }
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
    node_map: &HashMap<TypedRecordId, InputNode>,
    config: &config::RelationEngineConfig,
) {
    // 1. Line snapping / center-to-center trimming
    // Skip for Bezier/SineWave — the shaper already positions endpoints at the port positions,
    // and the body path tangent at the endpoint should reflect the curve's actual direction.
    let mode = edge
        .routing_mode
        .as_ref()
        .unwrap_or(&config.routing.routing_mode);
    let skip_line_snapping = matches!(
        mode,
        RoutingMode::Bezier { .. } | RoutingMode::SineWave { .. }
    );
    if !skip_line_snapping && (edge.from_side.is_none() || edge.to_side.is_none()) {
        if let (Some(start_node), Some(end_node)) = (
            node_map.get(&edge.from_node_id).or_else(|| {
                node_map.values().find(|n| n.id.key == edge.from_node_id.key)
            }),
            node_map.get(&edge.to_node_id).or_else(|| {
                node_map.values().find(|n| n.id.key == edge.to_node_id.key)
            }),
        ) {
            let start_bbox = start_node.bounding_box();
            let end_bbox = end_node.bounding_box();
            let center_from = Point::new(
                start_node.x + start_node.width / 2.0,
                start_node.y + start_node.height / 2.0,
            );
            let center_to = Point::new(
                end_node.x + end_node.width / 2.0,
                end_node.y + end_node.height / 2.0,
            );
            if !result.path_points.is_empty() {
                let n = result.path_points.len();
                if edge.from_side.is_none() {
                    result.path_points[0] = intersect_line_rect(center_from, center_to, start_bbox)
                        .unwrap_or(result.path_points[0]);
                }
                if edge.to_side.is_none() {
                    result.path_points[n - 1] =
                        intersect_line_rect(center_to, center_from, end_bbox)
                            .unwrap_or(result.path_points[n - 1]);
                }
            }
        }
    }

    if result.path_points.is_empty() {
        return;
    }

    // 2. Endpoint Shapes & Sizes
    let start_node = node_map.get(&edge.from_node_id).or_else(|| {
        node_map.values().find(|n| n.id.key == edge.from_node_id.key)
    });
    let end_node = node_map.get(&edge.to_node_id).or_else(|| {
        node_map.values().find(|n| n.id.key == edge.to_node_id.key)
    });

    let start_shape = edge
        .style
        .as_ref()
        .and_then(|s| s.start_shape)
        .unwrap_or(config.endpoint.default_start_shape);

    let end_shape = edge
        .style
        .as_ref()
        .and_then(|s| s.end_shape)
        .unwrap_or(config.endpoint.default_end_shape);

    result.start_endpoint = start_shape;
    result.end_endpoint = end_shape;

    let base_width = edge
        .style
        .as_ref()
        .map(|s| s.stroke_width as f64)
        .unwrap_or(2.0);

    let start_shape_size = if start_shape != EndpointShape::None {
        let style_endpoint_sz = edge.style.as_ref().map(|s| s.arrow_size as f64).unwrap_or(config.endpoint.arrow_size);
        style_endpoint_sz * (base_width / 2.0).max(1.0)
    } else {
        0.0
    };

    let end_shape_size = if end_shape != EndpointShape::None {
        let style_endpoint_sz = edge.style.as_ref().map(|s| s.arrow_size as f64).unwrap_or(config.endpoint.arrow_size);
        style_endpoint_sz * (base_width / 2.0).max(1.0)
    } else {
        0.0
    };

    // 3. Tangents — derived from lookahead along body path geometry
    let start_inset = (start_shape_size * 1.5).max(15.0);
    let end_inset = (end_shape_size * 1.5).max(15.0);
    let (st, et) = compute_tangents(&result.path_points, start_inset, end_inset);
    result.start_tangent = st;
    result.end_tangent = et;

    // Direction follows the relation tangent so shapes dynamically reorient
    // as the relation body bends. Tip points outward (toward the node).
    result.start_direction = st.y.atan2(st.x) + std::f64::consts::PI;
    result.end_direction = et.y.atan2(et.x);

    // Dynamic scale based on node size
    let start_node_size = start_node.map(|n| n.width.min(n.height)).unwrap_or(80.0);
    let end_node_size = end_node.map(|n| n.width.min(n.height)).unwrap_or(80.0);
    let start_scale = (start_node_size / 80.0).clamp(0.5, 2.0);
    let end_scale = (end_node_size / 80.0).clamp(0.5, 2.0);

    let start_arrow_sz = config.endpoint.arrow_size * start_scale;
    let end_arrow_sz = config.endpoint.arrow_size * end_scale;

    // 4. Body Widths & Types
    let body_type_str = edge
        .style
        .as_ref()
        .map(|s| s.body_strategy.as_str())
        .unwrap_or("uniform");
    let body_type = match body_type_str {
        "uniform" => config::BodyType::Uniform,
        "taper" => config::BodyType::Taper,
        "widthModulate" => config::BodyType::WidthModulate,
        "bundled" => config::BodyType::Bundled,
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

    let start_base_offset = start_shape.base_offset(start_shape_size);
    let end_base_offset = end_shape.base_offset(end_shape_size);

    result.start_margin = start_base_offset;
    result.end_margin = end_base_offset;

    let n = result.path_points.len();
    result.start_point = result.path_points[0];
    result.end_point = result.path_points[n - 1];

    // Trim start & end path points by shape base offset so line stops cleanly at shape back base
    if start_base_offset > 0.0 {
        trim_polyline_endpoint(&mut result.path_points, true, start_base_offset);
        let start_base_center = result.start_point + st * start_base_offset;
        let blend_dist = start_base_offset * 0.5;
        smooth_path_at_endpoint(&mut result.path_points, true, start_base_center, st, blend_dist);
    }
    if end_base_offset > 0.0 {
        trim_polyline_endpoint(&mut result.path_points, false, end_base_offset);
        let end_base_center = result.end_point - et * end_base_offset;
        let blend_dist = end_base_offset * 0.5;
        smooth_path_at_endpoint(&mut result.path_points, false, end_base_center, et, blend_dist);
    }

    result.start_arrow_center = result.start_point + st * (start_base_offset / 2.0);
    result.end_arrow_center = result.end_point - et * (end_base_offset / 2.0);

    result.start_shape_path = if start_shape != EndpointShape::None {
        start_shape.generate_polygon(
            result.start_point,
            result.start_direction,
            start_shape_size,
        )
    } else {
        vec![]
    };

    result.end_shape_path = if end_shape != EndpointShape::None {
        end_shape.generate_polygon(
            result.end_point,
            result.end_direction,
            end_shape_size,
        )
    } else {
        vec![]
    };

    result.start_shape_filled = start_shape.is_filled();
    result.end_shape_filled = end_shape.is_filled();

    // 7. Handle positions inset from endpoint shapes
    let handle_inset = config.endpoint.handle_inset;
    result.start_handle_pos = inset_along_polyline(&result.path_points, true, handle_inset);
    result.end_handle_pos = inset_along_polyline(&result.path_points, false, handle_inset);

    // 8. Dependencies
    result.depends_on_nodes = vec![edge.from_node_id.clone(), edge.to_node_id.clone()];
    result.hit_test_points = result.path_points.clone();
}
