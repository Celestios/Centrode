use super::geometry::Point;

pub struct RelationBuffers {
    pub path: Vec<Point>,
    pub tail_start: Vec<Point>,
    pub tail_end: Vec<Point>,
    pub widths: Vec<f64>,
}

impl RelationBuffers {
    pub fn with_capacity(cap: usize) -> Self {
        Self {
            path: Vec::with_capacity(cap),
            tail_start: Vec::with_capacity(cap / 4),
            tail_end: Vec::with_capacity(cap / 4),
            widths: Vec::with_capacity(cap),
        }
    }

    pub fn clear(&mut self) {
        self.path.clear();
        self.tail_start.clear();
        self.tail_end.clear();
        self.widths.clear();
    }
}
