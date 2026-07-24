use crate::relation_engine::geometry::Point;

pub struct Grid {
    pub width: usize,
    pub height: usize,
    pub cell_size: f64,
    pub origin_x: f64,
    pub origin_y: f64,
}

impl Grid {
    pub fn new(origin_x: f64, origin_y: f64, width: usize, height: usize, cell_size: f64) -> Self {
        Self {
            width,
            height,
            cell_size,
            origin_x,
            origin_y,
        }
    }

    pub fn world_to_grid(&self, pt: Point) -> (i32, i32) {
        let col = ((pt.x - self.origin_x) / self.cell_size).floor() as i32;
        let row = ((pt.y - self.origin_y) / self.cell_size).floor() as i32;
        (col, row)
    }

    pub fn grid_to_world(&self, col: i32, row: i32) -> Point {
        Point::new(
            self.origin_x + (col as f64 + 0.5) * self.cell_size,
            self.origin_y + (row as f64 + 0.5) * self.cell_size,
        )
    }

    pub fn in_bounds(&self, col: i32, row: i32) -> bool {
        col >= 0 && col < self.width as i32 && row >= 0 && row < self.height as i32
    }
}
