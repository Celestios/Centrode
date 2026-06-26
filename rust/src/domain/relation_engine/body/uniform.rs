use super::{BodyStrategy, Point, RelationEngineConfig};

pub struct UniformBody;

impl BodyStrategy for UniformBody {
    fn compute_widths(
        &self,
        path: &[Point],
        base_width: f64,
        _config: &RelationEngineConfig,
    ) -> Vec<f64> {
        vec![base_width; path.len()]
    }
}
