use centrode_macros::{SurrealDbEnum, SurqlSchemaField};
use surrealdb::types::SurrealValue;

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum EndpointShape {
    None = 0,
    Arrow = 1,
    OpenArrow = 2,
    Circle = 3,
    Diamond = 4,
    Square = 5,
}

impl EndpointShape {
    pub fn generate_polygon(
        &self,
        tip_position: crate::routing::Point,
        direction_rad: f64,
        size: f64,
    ) -> Vec<crate::routing::Point> {
        match self {
            EndpointShape::None => vec![],
            EndpointShape::Arrow => Self::arrow_vertices(tip_position, direction_rad, size),
            EndpointShape::OpenArrow => Self::open_arrow_vertices(tip_position, direction_rad, size),
            EndpointShape::Circle => Self::circle_vertices(tip_position, direction_rad, size),
            EndpointShape::Diamond => Self::diamond_vertices(tip_position, direction_rad, size),
            EndpointShape::Square => Self::square_vertices(tip_position, direction_rad, size),
        }
    }

    pub fn is_filled(&self) -> bool {
        *self != EndpointShape::OpenArrow
    }

    pub fn base_offset(&self, size: f64) -> f64 {
        match self {
            EndpointShape::None => 0.0,
            EndpointShape::Arrow | EndpointShape::OpenArrow => size,
            EndpointShape::Circle => size * 0.6,
            EndpointShape::Diamond => size,
            EndpointShape::Square => size,
        }
    }

    fn arrow_vertices(tip: crate::routing::Point, direction_rad: f64, size: f64) -> Vec<crate::routing::Point> {
        let half_width = size * 0.30;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = crate::routing::Point::new(cos, sin);
        let perp = crate::routing::Point::new(-sin, cos);

        let base_center = tip - dir * size;
        let base_left = base_center + perp * half_width;
        let base_right = base_center - perp * half_width;

        vec![tip, base_left, base_right]
    }

    fn open_arrow_vertices(tip: crate::routing::Point, direction_rad: f64, size: f64) -> Vec<crate::routing::Point> {
        let half_width = size * 0.30;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = crate::routing::Point::new(cos, sin);
        let perp = crate::routing::Point::new(-sin, cos);

        let base_center = tip - dir * size;
        let base_left = base_center + perp * half_width;
        let base_right = base_center - perp * half_width;

        vec![tip, base_left, base_right, base_center]
    }

    fn circle_vertices(tip: crate::routing::Point, direction_rad: f64, size: f64) -> Vec<crate::routing::Point> {
        let radius = size * 0.3;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = crate::routing::Point::new(cos, sin);
        let center = tip - dir * radius;

        let segments = 12;
        let mut points = Vec::with_capacity(segments);
        for i in 0..segments {
            let angle = (i as f64) * 2.0 * std::f64::consts::PI / (segments as f64);
            points.push(crate::routing::Point::new(
                center.x + radius * angle.cos(),
                center.y + radius * angle.sin(),
            ));
        }
        points
    }

    fn diamond_vertices(tip: crate::routing::Point, direction_rad: f64, size: f64) -> Vec<crate::routing::Point> {
        let half_len = size / 2.0;
        let half_width = size * 0.4;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = crate::routing::Point::new(cos, sin);
        let perp = crate::routing::Point::new(-sin, cos);

        let center = tip - dir * half_len;
        let right = center + perp * half_width;
        let back = tip - dir * size;
        let left = center - perp * half_width;

        vec![tip, right, back, left]
    }

    fn square_vertices(tip: crate::routing::Point, direction_rad: f64, size: f64) -> Vec<crate::routing::Point> {
        let half_width = size / 2.0;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = crate::routing::Point::new(cos, sin);
        let perp = crate::routing::Point::new(-sin, cos);

        let front_left = tip + perp * half_width;
        let front_right = tip - perp * half_width;
        let back_right = tip - dir * size - perp * half_width;
        let back_left = tip - dir * size + perp * half_width;

        vec![front_left, front_right, back_right, back_left]
    }
}

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum RelationDirection {
    #[default]
    Forward = 0,
    Backward = 1,
    Undirected = 2,
}

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum PortSide {
    #[default]
    Auto = 0,
    Top = 1,
    Right = 2,
    Bottom = 3,
    Left = 4,
    TopLeft = 5,
    TopRight = 6,
    BottomLeft = 7,
    BottomRight = 8,
}

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum PortType {
    #[default]
    Middle = 0,
    Corner = 1,
    Edge = 2,
}

use flutter_rust_bridge::frb;

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct NodeStyle {
    pub bg_color: u32,
    pub stroke_color: u32,
    pub stroke_width: i32,
    pub font_family: String,
    pub font_size: f64,
    pub shape: String,
    pub width: i32,
    pub height: i32,
    // --- Advanced Visual Properties ---
    pub text_color: u32,
    pub border_radius: f64,
    pub padding: f64,
    pub shadow_color: u32,
    pub shadow_blur: f64,
    pub shadow_spread: f64,
    pub shadow_offset_x: f64,
    pub shadow_offset_y: f64,
    pub strategy_type: String,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct RelationStyle {
    pub bg_color: u32,
    pub stroke_color: u32,
    pub stroke_width: i32,
    pub font_family: String,
    pub font_size: f64,
    pub shape: String,
    pub arrow_type: String,
    pub arrow_size: f64,
    pub start_shape: Option<EndpointShape>,
    pub end_shape: Option<EndpointShape>,
    pub width: i32,
    pub height: i32,
    // --- Advanced Visual Properties ---
    pub text_color: u32,
    pub shadow_color: u32,
    pub shadow_blur: f64,
    pub shadow_offset_x: f64,
    pub shadow_offset_y: f64,
    pub strategy_type: String,
    pub stroke_pattern: String,
    pub body_strategy: String,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct ControlPoint {
    pub x: f64,
    pub y: f64,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct RelationLayout {
    pub from_side: Option<PortSide>,
    pub to_side: Option<PortSide>,
    pub strategy_type: String,
    pub control_point_1: Option<ControlPoint>,
    pub control_point_2: Option<ControlPoint>,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct NodeLayout {
    pub strategy_type: String,
}

