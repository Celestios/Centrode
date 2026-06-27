use super::config::{EndpointShapeType, RelationEngineConfig};
use super::geometry::Point;
use super::input::{InputEdge, InputNode};
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct EndpointResult {
    pub position: Point,
    pub direction: f64,
    pub shape: EndpointShapeType,
}

#[derive(Debug, Clone)]
pub struct EndpartResult {
    pub exit_point: Point,
    pub exit_direction: f64,
    pub point_count: usize,
}

#[derive(Debug, Clone)]
pub struct AdapterResult {
    pub body_anchor: Point,
    pub point_count: usize,
}

#[derive(Debug, Clone)]
pub struct BodyResult {
    pub point_count: usize,
    pub total_points: usize,
}

#[derive(Debug, Clone)]
pub struct TailSections {
    pub endpoint: EndpointResult,
    pub endpart: EndpartResult,
    pub adapter: AdapterResult,
}

#[derive(Debug, Clone)]
pub struct SectionedRelation {
    pub tail_start: TailSections,
    pub body: BodyResult,
    pub tail_end: TailSections,
}

pub fn compute_sections(
    edge: &InputEdge,
    node_map: &HashMap<&str, &InputNode>,
    config: &RelationEngineConfig,
    path_buffer: &mut Vec<Point>,
    tail_start_buffer: &mut Vec<Point>,
    tail_end_buffer: &mut Vec<Point>,
) -> Option<SectionedRelation> {
    let from_node = node_map.get(edge.from_node_id.as_str())?;
    let to_node = node_map.get(edge.to_node_id.as_str())?;

    let from_center = from_node.center();
    let to_center = to_node.center();

    let start_port = match &edge.from_side {
        Some(side) => from_node.resolve_port(side, to_center),
        None => from_node.closest_port_to(to_center),
    };
    let end_port = match &edge.to_side {
        Some(side) => to_node.resolve_port(side, from_center),
        None => to_node.closest_port_to(from_center),
    };

    let start_tangent = if path_buffer.len() >= 2 {
        (path_buffer[1] - path_buffer[0]).normalized()
    } else {
        Point::new(1.0, 0.0)
    };
    let end_tangent = if path_buffer.len() >= 2 {
        (path_buffer[path_buffer.len() - 1] - path_buffer[path_buffer.len() - 2]).normalized()
    } else {
        Point::new(1.0, 0.0)
    };

    let style = edge.style.as_ref();

    let start_endpoint = super::section_endpoint::resolve_start(
        from_node, start_port.position, start_tangent, style, config,
    );
    let end_endpoint = super::section_endpoint::resolve_end(
        to_node, end_port.position, end_tangent, style, config,
    );

    let start_endpart = super::section_endpart::guide_endpart(&start_endpoint, from_node, tail_start_buffer);
    let end_endpart = super::section_endpart::guide_endpart(&end_endpoint, to_node, tail_end_buffer);

    let body_start = path_buffer.first().copied().unwrap_or(Point::zero());
    let body_end = path_buffer.last().copied().unwrap_or(Point::zero());

    let start_adapter = super::section_adapter::connect_adapter(&start_endpart, body_start, tail_start_buffer);
    let end_adapter = super::section_adapter::connect_adapter(&end_endpart, body_end, tail_end_buffer);

    let body = BodyResult {
        point_count: path_buffer.len(),
        total_points: path_buffer.len(),
    };

    Some(SectionedRelation {
        tail_start: TailSections {
            endpoint: start_endpoint,
            endpart: start_endpart,
            adapter: start_adapter,
        },
        body,
        tail_end: TailSections {
            endpoint: end_endpoint,
            endpart: end_endpart,
            adapter: end_adapter,
        },
    })
}
