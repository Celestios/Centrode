pub mod attraction;
pub mod collision;
pub mod repulsion;
pub mod wall;

use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::layout_engine::config::ForceConfig;
use crate::layout_engine::types::{LayoutEdge, NodePhysics};
use std::collections::HashMap;

pub struct ForceAccumulator;

impl ForceAccumulator {
    pub fn accumulate(
        nodes: &mut HashMap<TypedRecordId, NodePhysics>,
        edges: &[LayoutEdge],
        opt_area: &Option<BoundingBox>,
        config: &ForceConfig,
        alpha: f64,
    ) {
        let node_ids: Vec<TypedRecordId> = nodes.keys().cloned().collect();
        let n = node_ids.len();
        let mut forces: Vec<(f64, f64)> = vec![(0.0, 0.0); n];

        for i in 0..n {
            let a = &nodes[&node_ids[i]];

            for j in (i + 1)..n {
                let b = &nodes[&node_ids[j]];

                let (r_fx, r_fy) = repulsion::repulsion_force(a, b, config.repulsion_constant);
                forces[i].0 += r_fx;
                forces[i].1 += r_fy;
                forces[j].0 -= r_fx;
                forces[j].1 -= r_fy;

                let (c_fx, c_fy) = collision::collision_force(a, b, config);
                forces[i].0 += c_fx;
                forces[i].1 += c_fy;
                forces[j].0 -= c_fx;
                forces[j].1 -= c_fy;
            }
        }

        for edge in edges {
            let a_idx = node_ids.iter().position(|id| *id == edge.from_id);
            let b_idx = node_ids.iter().position(|id| *id == edge.to_id);
            if let (Some(ai), Some(bi)) = (a_idx, b_idx) {
                let a = &nodes[&node_ids[ai]];
                let b = &nodes[&node_ids[bi]];
                let (f_fx, f_fy) = attraction::link_spring_force(
                    a,
                    b,
                    config.spring_constant,
                    config.ideal_link_distance,
                );
                forces[ai].0 += f_fx;
                forces[ai].1 += f_fy;
                forces[bi].0 -= f_fx;
                forces[bi].1 -= f_fy;
            }
        }

        for i in 0..n {
            if let Some(area) = opt_area {
                let node = &nodes[&node_ids[i]];
                let (w_fx, w_fy) = wall::wall_force(node, area, config);
                forces[i].0 += w_fx;
                forces[i].1 += w_fy;
            }
        }

        for i in 0..n {
            let node = nodes.get_mut(&node_ids[i]).unwrap();
            node.vx = (node.vx + forces[i].0 * alpha) * (1.0 - config.damping);
            node.vy = (node.vy + forces[i].1 * alpha) * (1.0 - config.damping);
        }
    }
}
