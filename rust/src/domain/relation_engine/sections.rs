use super::geometry::Point;
use super::config::EndpointShapeType;

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
