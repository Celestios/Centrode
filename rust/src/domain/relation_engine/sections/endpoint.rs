use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::config::{EndpointShapeType, RelationEngineConfig};
use crate::domain::relation_engine::input::InputNode;
use crate::domain::styles::RelationStyle;

use super::EndpointResult;

#[inline(always)]
fn resolve_endpoint(
    node: &InputNode,
    port: Point,
    tangent: Point,
    style: Option<&RelationStyle>,
    _config: &RelationEngineConfig,
    get_shape: impl FnOnce(&RelationStyle) -> Option<&crate::domain::styles::EndpointShape>,
    default_shape: EndpointShapeType,
    tangent_offset: f64,
    is_orthogonal: bool,
) -> EndpointResult {
    let center = node.center();
    let dx = port.x - center.x;
    let dy = port.y - center.y;
    let direction = if is_orthogonal {
        if dx.abs() > 1e-6 || dy.abs() > 1e-6 {
            dy.atan2(dx) + std::f64::consts::PI
        } else {
            tangent.direction() + tangent_offset
        }
    } else {
        tangent.direction() + tangent_offset
    };

    let shape = style
        .and_then(|s| get_shape(s))
        .map(|s| EndpointShapeType::from(*s))
        .unwrap_or(default_shape);

    EndpointResult {
        position: port,
        direction,
        shape,
    }
}

pub fn resolve_start(
    node: &InputNode,
    port: Point,
    tangent: Point,
    style: Option<&RelationStyle>,
    config: &RelationEngineConfig,
    is_orthogonal: bool,
) -> EndpointResult {
    resolve_endpoint(
        node, port, tangent, style, config,
        |s| s.start_shape.as_ref(),
        config.endpoint.default_start_shape,
        std::f64::consts::PI,
        is_orthogonal,
    )
}

pub fn resolve_end(
    node: &InputNode,
    port: Point,
    tangent: Point,
    style: Option<&RelationStyle>,
    config: &RelationEngineConfig,
    is_orthogonal: bool,
) -> EndpointResult {
    resolve_endpoint(
        node, port, tangent, style, config,
        |s| s.end_shape.as_ref(),
        config.endpoint.default_end_shape,
        0.0,
        is_orthogonal,
    )
}
