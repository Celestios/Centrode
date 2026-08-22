use crate::relation_engine::computed::{ComputedRelation, PathType};
use crate::relation_engine::geometry::Point;
use crate::relation_engine::path_finder::core::a_star;
use crate::relation_engine::path_finder::steer::{AStarContext, Steer};
use crate::relation_engine::shaper::core::{Shaper, ShaperContext};

/// Marker struct representing a routing mode that does not perform A* pathfinding.
pub struct NoSteer {}

impl Steer for NoSteer {
    fn neighbors(&self) -> Vec<(i32, i32, f64)> {
        vec![]
    }

    fn heuristic(&self, _from: Point, _to: Point) -> f64 {
        0.0
    }

    fn transition_cost(
        &self,
        _from_key: (i32, i32),
        _to_key: (i32, i32),
        _dir: (i32, i32),
        _prev_key: Option<(i32, i32)>,
        _step_cost: f64,
        _context: &AStarContext,
    ) -> f64 {
        0.0
    }
}

/// Zero-cost generic routing strategy runner pairing pathfinding (`Steer`) and curve shaping (`Shaper`).
pub struct RoutingStrategy<S: Steer, H: Shaper> {
    pub steer: Option<S>,
    pub shaper: H,
}

impl<S: Steer, H: Shaper> RoutingStrategy<S, H> {
    pub fn with_steer(steer: S, shaper: H) -> Self {
        Self {
            steer: Some(steer),
            shaper,
        }
    }

    pub fn execute(
        &self,
        context: &AStarContext,
        shaper_ctx: &ShaperContext,
    ) -> (ComputedRelation, bool) {
        let (raw_path, is_fallback) = match &self.steer {
            Some(steer) => {
                let path_opt = a_star(steer, context);
                let fallback = path_opt.is_none();
                let path = match path_opt {
                    Some(p) => p,
                    None => vec![context.start_terminus, context.end_terminus],
                };
                (path, fallback)
            }
            None => (vec![shaper_ctx.start_pt, shaper_ctx.end_pt], false),
        };

        let mut result = self.shaper.shape(&raw_path, shaper_ctx);
        if is_fallback {
            result.path_type = PathType::Straight;
        }
        (result, is_fallback)
    }
}

impl<H: Shaper> RoutingStrategy<NoSteer, H> {
    pub fn direct(shaper: H) -> Self {
        Self {
            steer: None,
            shaper,
        }
    }
}
