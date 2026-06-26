use crate::domain::relation_engine::geometry::Point;
use std::f64::consts::PI;

#[derive(Debug, Clone)]
pub struct EndpointPlacement {
    pub position: Point,
    pub direction: f64,
    pub scale: f64,
}

/// Trims the start and end of path points to accommodate endpoint shapes.
pub fn trim_path(path: &[Point], start_margin: f64, end_margin: f64) -> Vec<Point> {
    if path.len() < 2 {
        return path.to_vec();
    }

    let mut points = path.to_vec();

    // Trim start
    if start_margin > 0.0 {
        let mut remaining = start_margin;
        let mut new_points = Vec::new();
        let mut trimmed_start = None;

        for i in 0..points.len() - 1 {
            let p1 = points[i];
            let p2 = points[i + 1];
            let dist = p1.distance_to(p2);

            if dist >= remaining {
                let t = remaining / dist;
                let new_start = p1.lerp(p2, t);
                trimmed_start = Some(new_start);
                new_points.push(new_start);
                new_points.extend_from_slice(&points[i + 1..]);
                break;
            } else {
                remaining -= dist;
            }
        }

        if trimmed_start.is_some() {
            points = new_points;
        } else {
            return vec![*path.last().unwrap()];
        }
    }

    // Trim end
    if end_margin > 0.0 && points.len() >= 2 {
        let mut remaining = end_margin;
        let mut new_points = Vec::new();
        let mut trimmed_end = None;

        for i in (1..points.len()).rev() {
            let p2 = points[i];
            let p1 = points[i - 1];
            let dist = p1.distance_to(p2);

            if dist >= remaining {
                let t = 1.0 - (remaining / dist);
                let new_end = p1.lerp(p2, t);
                trimmed_end = Some(new_end);
                new_points.extend_from_slice(&points[..i]);
                new_points.push(new_end);
                break;
            } else {
                remaining -= dist;
            }
        }

        if trimmed_end.is_some() {
            points = new_points;
        } else {
            return vec![points[0]];
        }
    }

    points
}

/// Symmetrically divides a path into a list of dashes/dots segments.
pub fn generate_pattern(path: &[Point], pattern: &str) -> Vec<Vec<Point>> {
    if path.len() < 2 {
        return vec![path.to_vec()];
    }

    let dash_len;
    let gap_len;
    match pattern {
        "dashed" => {
            dash_len = 8.0;
            gap_len = 6.0;
        }
        "dotted" => {
            dash_len = 2.0;
            gap_len = 4.0;
        }
        _ => return vec![path.to_vec()],
    }

    let mut segments = Vec::new();
    let mut total_length = 0.0;
    let mut accum_lengths = vec![0.0; path.len()];
    for i in 1..path.len() {
        total_length += path[i - 1].distance_to(path[i]);
        accum_lengths[i] = total_length;
    }

    let mut distance = 0.0;
    let mut draw = true;

    while distance < total_length {
        let step = if draw { dash_len } else { gap_len };
        let end_distance = (distance + step).min(total_length);

        if draw {
            let segment = extract_subpath(path, &accum_lengths, distance, end_distance);
            if segment.len() >= 2 {
                segments.push(segment);
            }
        }

        distance = end_distance;
        draw = !draw;
    }

    segments
}

fn extract_subpath(path: &[Point], accum_lengths: &[f64], start: f64, end: f64) -> Vec<Point> {
    let mut sub = Vec::new();
    if path.is_empty() {
        return sub;
    }

    let mut started = false;
    for i in 0..path.len() - 1 {
        let p1 = path[i];
        let p2 = path[i + 1];
        let d1 = accum_lengths[i];
        let d2 = accum_lengths[i + 1];

        if !started && start >= d1 && start <= d2 {
            let t = if d2 > d1 { (start - d1) / (d2 - d1) } else { 0.0 };
            sub.push(p1.lerp(p2, t));
            started = true;
        }

        if started {
            if end >= d1 && end <= d2 {
                let t = if d2 > d1 { (end - d1) / (d2 - d1) } else { 0.0 };
                sub.push(p1.lerp(p2, t));
                break;
            } else {
                sub.push(p2);
            }
        }
    }
    sub
}

/// Computes endpoint placement details (position, direction, dynamic scale factor).
pub fn compute_endpoint_placement(
    endpoint: Point,
    node_center: Point,
    arrow_size: f64,
    stroke_width: f64,
) -> EndpointPlacement {
    let dx = endpoint.x - node_center.x;
    let dy = endpoint.y - node_center.y;
    let outward_dir = dy.atan2(dx);

    let offset_x = outward_dir.cos() * arrow_size * 0.5;
    let offset_y = outward_dir.sin() * arrow_size * 0.5;
    let position = Point::new(endpoint.x + offset_x, endpoint.y + offset_y);

    let direction = outward_dir + PI;
    let scale = if stroke_width > 0.0 { stroke_width / 2.0 } else { 1.0 };

    EndpointPlacement {
        position,
        direction,
        scale,
    }
}
