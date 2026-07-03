use super::geometry::Point;
use super::input::InputNode;
use super::sections::{EndpointResult, EndpartResult};

#[derive(Debug, Clone, Copy)]
pub enum EndpartResolver {
    Perpendicular,
}

impl EndpartResolver {
    #[inline(always)]
    pub fn guide(
        &self,
        endpoint: &EndpointResult,
        node: &InputNode,
        path_buffer: &mut Vec<Point>,
    ) -> EndpartResult {
        match self {
            Self::Perpendicular => perpendicular_guide(endpoint, node, path_buffer),
        }
    }
}

#[inline(always)]
fn perpendicular_guide(
    endpoint: &EndpointResult,
    _node: &InputNode,
    path_buffer: &mut Vec<Point>,
) -> EndpartResult {
    let port = endpoint.position;
    let direction = endpoint.direction;

    let start_idx = path_buffer.len();
    path_buffer.push(port);

    let perpendicular = Point::new(direction.cos(), direction.sin());
    let length = 8.0;
    let exit = port + perpendicular * length;
    path_buffer.push(exit);

    EndpartResult {
        exit_point: exit,
        exit_direction: direction,
        point_count: path_buffer.len() - start_idx,
    }
}

pub fn guide_endpart(
    endpoint: &EndpointResult,
    node: &InputNode,
    path_buffer: &mut Vec<Point>,
) -> EndpartResult {
    EndpartResolver::Perpendicular.guide(endpoint, node, path_buffer)
}
