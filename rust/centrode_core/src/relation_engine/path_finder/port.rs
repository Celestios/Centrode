use crate::domain::id::TypedRecordId;
use crate::domain::styles::PortSide;
use crate::relation_engine::config::RoutingMode;
use crate::relation_engine::geometry::{point_distance_to_rect, Point, Rect};
use crate::relation_engine::types::{InputEdge, InputNode};

use std::collections::HashMap;

const OBSTACLE_WALL_COST: f64 = 1e8;
const COLLISION_BUFFER: f64 = 5.0;

pub struct ResolvedPorts {
    pub start: Point,
    pub end: Point,
    pub start_normal: Option<Point>,
    pub end_normal: Option<Point>,
    pub start_exit: Point,
    pub end_exit: Point,
}

pub fn port_position(node: &InputNode, side: Option<&PortSide>) -> (Point, f64) {
    let (x, y, w, h) = (node.x, node.y, node.width, node.height);
    let (cx, cy) = (x + w / 2.0, y + h / 2.0);
    match side {
        Some(PortSide::Top) => (Point::new(cx, y), -std::f64::consts::FRAC_PI_2),
        Some(PortSide::Right) => (Point::new(x + w, cy), 0.0),
        Some(PortSide::Bottom) => (Point::new(cx, y + h), std::f64::consts::FRAC_PI_2),
        Some(PortSide::Left) => (Point::new(x, cy), std::f64::consts::PI),
        Some(PortSide::TopLeft) => (Point::new(x, y), -3.0 * std::f64::consts::FRAC_PI_4),
        Some(PortSide::TopRight) => (Point::new(x + w, y), -std::f64::consts::FRAC_PI_4),
        Some(PortSide::BottomRight) => (Point::new(x + w, y + h), std::f64::consts::FRAC_PI_4),
        Some(PortSide::BottomLeft) => (Point::new(x, y + h), 3.0 * std::f64::consts::FRAC_PI_4),
        _ => (Point::new(cx, cy), 0.0),
    }
}

pub fn get_port_dir(side: Option<&PortSide>) -> Option<(i32, i32)> {
    match side {
        Some(PortSide::Top) => Some((0, -1)),
        Some(PortSide::Right) => Some((1, 0)),
        Some(PortSide::Bottom) => Some((0, 1)),
        Some(PortSide::Left) => Some((-1, 0)),
        Some(PortSide::TopLeft) => Some((-1, -1)),
        Some(PortSide::TopRight) => Some((1, -1)),
        Some(PortSide::BottomRight) => Some((1, 1)),
        Some(PortSide::BottomLeft) => Some((-1, 1)),
        _ => None,
    }
}

pub fn normal_for_side(side: &PortSide) -> Point {
    match side {
        PortSide::Top => Point::new(0.0, -1.0),
        PortSide::Right => Point::new(1.0, 0.0),
        PortSide::Bottom => Point::new(0.0, 1.0),
        PortSide::Left => Point::new(-1.0, 0.0),
        PortSide::TopLeft => Point::new(-1.0, -1.0).normalize(),
        PortSide::TopRight => Point::new(1.0, -1.0).normalize(),
        PortSide::BottomRight => Point::new(1.0, 1.0).normalize(),
        PortSide::BottomLeft => Point::new(-1.0, 1.0).normalize(),
        PortSide::Auto => Point::new(1.0, 0.0),
    }
}

pub fn resolve_orthogonal_normal_from_side(side: &PortSide, port: Point, other: Point) -> Point {
    match side {
        PortSide::TopLeft => {
            let dx = other.x - port.x;
            let dy = other.y - port.y;
            if dx.abs() <= dy.abs() {
                Point::new(-1.0, 0.0)
            } else {
                Point::new(0.0, -1.0)
            }
        }
        PortSide::TopRight => {
            let dx = other.x - port.x;
            let dy = other.y - port.y;
            if dx.abs() <= dy.abs() {
                Point::new(1.0, 0.0)
            } else {
                Point::new(0.0, -1.0)
            }
        }
        PortSide::BottomLeft => {
            let dx = other.x - port.x;
            let dy = other.y - port.y;
            if dx.abs() <= dy.abs() {
                Point::new(-1.0, 0.0)
            } else {
                Point::new(0.0, 1.0)
            }
        }
        PortSide::BottomRight => {
            let dx = other.x - port.x;
            let dy = other.y - port.y;
            if dx.abs() <= dy.abs() {
                Point::new(1.0, 0.0)
            } else {
                Point::new(0.0, 1.0)
            }
        }
        other_side => normal_for_side(other_side),
    }
}

pub fn closest_port_to(node: &InputNode, target: Point) -> (PortSide, Point) {
    let sides = [
        PortSide::Top,
        PortSide::Right,
        PortSide::Bottom,
        PortSide::Left,
        PortSide::TopLeft,
        PortSide::TopRight,
        PortSide::BottomRight,
        PortSide::BottomLeft,
    ];
    let mut best_side = PortSide::Top;
    let mut best_pos = port_position(node, Some(&PortSide::Top)).0;
    let mut min_dist = best_pos.distance_to(target);

    for side in &sides {
        let pos = port_position(node, Some(side)).0;
        let d = pos.distance_to(target);
        if d < min_dist {
            min_dist = d;
            best_side = side.clone();
            best_pos = pos;
        }
    }
    (best_side, best_pos)
}

pub fn compute_extension(node: &InputNode, extension_min: f64, extension_scale: f64) -> f64 {
    let node_dim = node.width.min(node.height);
    (node_dim * extension_scale).max(extension_min)
}

pub fn resolve_ports_full(
    edge: &InputEdge,
    node_map: &HashMap<TypedRecordId, InputNode>,
    routing_mode: &RoutingMode,
    start_ext: f64,
    end_ext: f64,
) -> Option<ResolvedPorts> {
    let from_node = node_map.get(&edge.from_node_id).or_else(|| {
        node_map.values().find(|n| n.id == edge.from_node_id || (n.id.key == edge.from_node_id.key && n.id.table == edge.from_node_id.table))
    })?;
    let to_node = node_map.get(&edge.to_node_id).or_else(|| {
        node_map.values().find(|n| n.id == edge.to_node_id || (n.id.key == edge.to_node_id.key && n.id.table == edge.to_node_id.table))
    })?;

    let to_center = Point::new(
        to_node.x + to_node.width / 2.0,
        to_node.y + to_node.height / 2.0,
    );

    let (start_side, start_pos) = match &edge.from_side {
        Some(PortSide::Auto) | None => closest_port_to(from_node, to_center),
        Some(side) => (side.clone(), port_position(from_node, Some(side)).0),
    };

    let (end_side, end_pos) = match &edge.to_side {
        Some(PortSide::Auto) | None => closest_port_to(to_node, start_pos),
        Some(side) => (side.clone(), port_position(to_node, Some(side)).0),
    };

    let start_normal = if *routing_mode == RoutingMode::Orthogonal {
        resolve_orthogonal_normal_from_side(&start_side, start_pos, end_pos)
    } else {
        normal_for_side(&start_side)
    };

    let end_normal = if *routing_mode == RoutingMode::Orthogonal {
        resolve_orthogonal_normal_from_side(&end_side, end_pos, start_pos)
    } else {
        normal_for_side(&end_side)
    };

    let start_exit = start_pos + start_normal * start_ext;
    let end_exit = end_pos + end_normal * end_ext;

    Some(ResolvedPorts {
        start: start_pos,
        end: end_pos,
        start_normal: Some(start_normal),
        end_normal: Some(end_normal),
        start_exit,
        end_exit,
    })
}

pub fn get_clearance_point(
    local_node: &InputNode,
    other_nodes: &[InputNode],
    port_pt: Point,
    dir: Option<(i32, i32)>,
    outer_bbox_distance: f64,
) -> (Point, f64) {
    let Some((dx, dy)) = dir else {
        return (port_pt, 0.0);
    };
    if dx == 0 && dy == 0 {
        return (port_pt, 0.0);
    }

    let min_x = local_node.x - outer_bbox_distance;
    let max_x = local_node.x + local_node.width + outer_bbox_distance;
    let min_y = local_node.y - outer_bbox_distance;
    let max_y = local_node.y + local_node.height + outer_bbox_distance;

    let dir = Point::new(dx as f64, dy as f64).normalize();

    let mut t_ideal = 0.0;
    if dir.x.abs() > 1e-6 {
        let t1 = (min_x - port_pt.x) / dir.x;
        let t2 = (max_x - port_pt.x) / dir.x;
        if t1 > t_ideal {
            t_ideal = t1;
        }
        if t2 > t_ideal {
            t_ideal = t2;
        }
    }
    if dir.y.abs() > 1e-6 {
        let t1 = (min_y - port_pt.y) / dir.y;
        let t2 = (max_y - port_pt.y) / dir.y;
        if t1 > t_ideal {
            t_ideal = t1;
        }
        if t2 > t_ideal {
            t_ideal = t2;
        }
    }

    let ideal_terminus = Point::new(port_pt.x + t_ideal * dir.x, port_pt.y + t_ideal * dir.y);

    let mut min_collision_t = t_ideal;
    for n in other_nodes {
        if n.id == local_node.id || !n.is_obstacle {
            continue;
        }
        let rect = Rect {
            x: n.x,
            y: n.y,
            width: n.width,
            height: n.height,
        };

        if let Some(s) = rect.intersect_segment_t(port_pt, ideal_terminus) {
            let collision_t = s * t_ideal;
            if collision_t < min_collision_t {
                min_collision_t = collision_t;
            }
        }
    }

    let mut t_max = t_ideal;
    if min_collision_t < t_ideal {
        t_max = (min_collision_t - COLLISION_BUFFER).max(0.0);
    }

    if t_max < COLLISION_BUFFER {
        t_max = 0.0;
    }

    if t_max == 0.0 {
        (port_pt, 0.0)
    } else {
        (
            Point::new(port_pt.x + t_max * dir.x, port_pt.y + t_max * dir.y),
            t_max,
        )
    }
}

pub fn compute_obstacle_cost(
    pt: Point,
    nodes: &[InputNode],
    outer_bbox_distance: f64,
    inner_bbox_scale: f64,
    weight: f64,
) -> f64 {
    let mut max_cost = 0.0;
    for n in nodes {
        if !n.is_obstacle {
            continue;
        }
        let cx = n.x + n.width / 2.0;
        let cy = n.y + n.height / 2.0;
        let hw = n.width * inner_bbox_scale / 2.0;
        let hh = n.height * inner_bbox_scale / 2.0;
        let inner = Rect {
            x: cx - hw,
            y: cy - hh,
            width: n.width * inner_bbox_scale,
            height: n.height * inner_bbox_scale,
        };
        if inner.contains(pt) {
            return OBSTACLE_WALL_COST;
        }
        let d_inner = point_distance_to_rect(pt, inner);
        let inner_to_node = ((n.width / 2.0 - hw).powi(2) + (n.height / 2.0 - hh).powi(2)).sqrt();

        let d_max = inner_to_node + outer_bbox_distance;
        if d_inner >= d_max {
            continue;
        }
        let cost = weight * (d_max / d_inner - 1.0);
        if cost > max_cost {
            max_cost = cost;
        }
    }
    max_cost
}
