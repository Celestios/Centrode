use super::geometry::Point;
use super::config::{EndpointShapeType, RelationEngineConfig};
use super::input::InputNode;
use crate::domain::styles::RelationStyle;

#[derive(Debug, Clone, Copy)]
pub enum EndpointResolver {
    Standard,
}

impl EndpointResolver {
    #[inline(always)]
    pub fn resolve(
        &self,
        node: &InputNode,
        port: Point,
        tangent: Point,
        style: Option<&RelationStyle>,
        config: &RelationEngineConfig,
    ) -> super::sections::EndpointResult {
        match self {
            Self::Standard => standard_resolve(node, port, tangent, style, config),
        }
    }
}

#[inline(always)]
fn standard_resolve(
    node: &InputNode,
    port: Point,
    tangent: Point,
    style: Option<&RelationStyle>,
    config: &RelationEngineConfig,
) -> super::sections::EndpointResult {
    let center = node.center();
    let dx = port.x - center.x;
    let dy = port.y - center.y;
    let direction = if dx.abs() > 1e-6 || dy.abs() > 1e-6 {
        dy.atan2(dx) + std::f64::consts::PI
    } else {
        tangent.direction() + std::f64::consts::PI
    };

    let shape = style
        .and_then(|s| s.start_shape.as_ref())
        .map(|s| match s {
            crate::domain::styles::EndpointShape::None => EndpointShapeType::None,
            crate::domain::styles::EndpointShape::Arrow => EndpointShapeType::Arrow,
            crate::domain::styles::EndpointShape::OpenArrow => EndpointShapeType::OpenArrow,
            crate::domain::styles::EndpointShape::Circle => EndpointShapeType::Circle,
            crate::domain::styles::EndpointShape::Diamond => EndpointShapeType::Diamond,
            crate::domain::styles::EndpointShape::Square => EndpointShapeType::Square,
        })
        .unwrap_or(config.endpoint.default_start_shape);

    super::sections::EndpointResult {
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
) -> super::sections::EndpointResult {
    EndpointResolver::Standard.resolve(node, port, tangent, style, config)
}

pub fn resolve_end(
    node: &InputNode,
    port: Point,
    tangent: Point,
    style: Option<&RelationStyle>,
    config: &RelationEngineConfig,
) -> super::sections::EndpointResult {
    let center = node.center();
    let dx = port.x - center.x;
    let dy = port.y - center.y;
    let direction = if dx.abs() > 1e-6 || dy.abs() > 1e-6 {
        dy.atan2(dx) + std::f64::consts::PI
    } else {
        tangent.direction()
    };

    let shape = style
        .and_then(|s| s.end_shape.as_ref())
        .map(|s| match s {
            crate::domain::styles::EndpointShape::None => EndpointShapeType::None,
            crate::domain::styles::EndpointShape::Arrow => EndpointShapeType::Arrow,
            crate::domain::styles::EndpointShape::OpenArrow => EndpointShapeType::OpenArrow,
            crate::domain::styles::EndpointShape::Circle => EndpointShapeType::Circle,
            crate::domain::styles::EndpointShape::Diamond => EndpointShapeType::Diamond,
            crate::domain::styles::EndpointShape::Square => EndpointShapeType::Square,
        })
        .unwrap_or(config.endpoint.default_end_shape);

    super::sections::EndpointResult {
        position: port,
        direction,
        shape,
    }
}
