use crate::domain::styles::EndpointShape;
use crate::relation_engine::geometry::Point;

impl EndpointShape {
    pub fn generate_polygon(
        &self,
        tip_position: Point,
        direction_rad: f64,
        size: f64,
    ) -> Vec<Point> {
        match self {
            EndpointShape::None => vec![],
            EndpointShape::Arrow | EndpointShape::OpenArrow => {
                Self::arrow_vertices(tip_position, direction_rad, size)
            }
            EndpointShape::Circle => Self::circle_vertices(tip_position, direction_rad, size),
            EndpointShape::Diamond => Self::diamond_vertices(tip_position, direction_rad, size),
            EndpointShape::Square => Self::square_vertices(tip_position, direction_rad, size),
        }
    }

    pub fn is_filled(&self) -> bool {
        *self != EndpointShape::OpenArrow
    }

    fn arrow_vertices(tip: Point, direction_rad: f64, size: f64) -> Vec<Point> {
        let half_width = size * 0.30;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = Point::new(cos, sin);
        let perp = Point::new(-sin, cos);

        let base_center = tip - dir * size;
        let base_left = base_center + perp * half_width;
        let base_right = base_center - perp * half_width;

        vec![tip, base_left, base_right]
    }

    fn circle_vertices(tip: Point, direction_rad: f64, size: f64) -> Vec<Point> {
        let radius = size / 2.0;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = Point::new(cos, sin);
        // Center is offset backward from tip by radius
        let center = tip - dir * radius;

        let segments = 12;
        let mut points = Vec::with_capacity(segments);
        for i in 0..segments {
            let angle = (i as f64) * 2.0 * std::f64::consts::PI / (segments as f64);
            points.push(Point::new(
                center.x + radius * angle.cos(),
                center.y + radius * angle.sin(),
            ));
        }
        points
    }

    fn diamond_vertices(tip: Point, direction_rad: f64, size: f64) -> Vec<Point> {
        let half_len = size / 2.0;
        let half_width = size * 0.4;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = Point::new(cos, sin);
        let perp = Point::new(-sin, cos);

        let center = tip - dir * half_len;
        let right = center + perp * half_width;
        let back = tip - dir * size;
        let left = center - perp * half_width;

        vec![tip, right, back, left]
    }

    fn square_vertices(tip: Point, direction_rad: f64, size: f64) -> Vec<Point> {
        let half_len = size / 2.0;
        let half_width = size / 2.0;
        let cos = direction_rad.cos();
        let sin = direction_rad.sin();
        let dir = Point::new(cos, sin);
        let perp = Point::new(-sin, cos);

        let front_left = tip + perp * half_width;
        let front_right = tip - perp * half_width;
        let back_right = tip - dir * size - perp * half_width;
        let back_left = tip - dir * size + perp * half_width;

        vec![front_left, front_right, back_right, back_left]
    }
}
