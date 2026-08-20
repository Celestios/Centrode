use crate::domain::styles::PortSide;
use crate::layout_engine::types::NodePhysics;
use std::f64::consts::{PI, TAU};

pub fn compute_optimal_ports(source: &NodePhysics, target: &NodePhysics) -> (PortSide, PortSide) {
    let dx = target.cx() - source.cx();
    let dy = target.cy() - source.cy();
    let angle = dy.atan2(dx);

    let source_side = angle_to_side(angle);
    let target_side = angle_to_side(angle + PI);

    (source_side, target_side)
}

pub fn angle_to_side(angle: f64) -> PortSide {
    let a = angle.rem_euclid(TAU);
    if a < PI / 4.0 || a >= 7.0 * PI / 4.0 {
        PortSide::Right
    } else if a < 3.0 * PI / 4.0 {
        PortSide::Bottom
    } else if a < 5.0 * PI / 4.0 {
        PortSide::Left
    } else {
        PortSide::Top
    }
}
