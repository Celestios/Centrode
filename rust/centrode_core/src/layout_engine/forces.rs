pub mod alignment;
pub mod anchor;
pub mod attraction;
pub mod collision;
pub mod density;
pub mod node_edge;
pub mod repulsion;
pub mod wall;

use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::layout_engine::config::ForceConfig;
use crate::layout_engine::types::{AlignmentConstraint, AnchorSpring, LayoutEdge, NodePhysics};
use std::collections::HashMap;

pub struct ForceAccumulator;

impl ForceAccumulator {
    pub fn accumulate(
        nodes: &mut HashMap<TypedRecordId, NodePhysics>,
        edges: &[LayoutEdge],
        opt_area: &Option<BoundingBox>,
        anchors: &HashMap<TypedRecordId, AnchorSpring>,
        alignments: &[AlignmentConstraint],
        config: &ForceConfig,
        alpha: f64,
    ) {
        let node_ids: Vec<TypedRecordId> = nodes.keys().cloned().collect();
        let n = node_ids.len();
        let id_to_index: HashMap<TypedRecordId, usize> = node_ids
            .iter()
            .enumerate()
            .map(|(idx, id)| (id.clone(), idx))
            .collect();
        let mut forces: Vec<(f64, f64)> = vec![(0.0, 0.0); n];

        let mut degrees: HashMap<TypedRecordId, usize> = HashMap::new();
        for edge in edges {
            *degrees.entry(edge.from_id.clone()).or_insert(0) += 1;
            *degrees.entry(edge.to_id.clone()).or_insert(0) += 1;
        }

        let node_refs: Vec<&NodePhysics> = node_ids.iter().map(|id| &nodes[id]).collect();

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
            let a_idx = id_to_index.get(&edge.from_id).copied();
            let b_idx = id_to_index.get(&edge.to_id).copied();
            if let (Some(ai), Some(bi)) = (a_idx, b_idx) {
                let a = &nodes[&node_ids[ai]];
                let b = &nodes[&node_ids[bi]];
                let (f_fx, f_fy) = attraction::link_spring_force(
                    a,
                    b,
                    config.spring_constant,
                    config.ideal_link_distance,
                    config.relation_stretch_factor,
                );
                forces[ai].0 += f_fx;
                forces[ai].1 += f_fy;
                forces[bi].0 -= f_fx;
                forces[bi].1 -= f_fy;
            }
        }

        if config.node_edge_repulsion > 0.0 {
            for i in 0..n {
                let node = &nodes[&node_ids[i]];
                for edge in edges {
                    if let (Some(from_node), Some(to_node)) =
                        (nodes.get(&edge.from_id), nodes.get(&edge.to_id))
                    {
                        let (ne_fx, ne_fy) = node_edge::node_edge_repulsion_force(
                            node,
                            from_node,
                            to_node,
                            config.node_edge_repulsion,
                        );
                        forces[i].0 += ne_fx;
                        forces[i].1 += ne_fy;
                    }
                }
            }
        }

        for i in 0..n {
            let id = &node_ids[i];
            let node = &nodes[id];

            if config.density_dispersion_strength > 0.0 {
                let deg = degrees.get(id).copied().unwrap_or(0);
                let (d_fx, d_fy) = density::density_dispersion_force(
                    node,
                    &node_refs,
                    deg,
                    config.density_dispersion_strength,
                );
                forces[i].0 += d_fx;
                forces[i].1 += d_fy;
            }

            if let Some(area) = opt_area {
                let (w_fx, w_fy) = wall::wall_force(node, area, config);
                forces[i].0 += w_fx;
                forces[i].1 += w_fy;
            }

            if let Some(anc) = anchors.get(id) {
                let (a_fx, a_fy) = anchor::anchor_force(node, anc);
                forces[i].0 += a_fx;
                forces[i].1 += a_fy;
            }
        }

        for constraint in alignments {
            let member_indices: Vec<(usize, &NodePhysics)> = constraint
                .node_ids
                .iter()
                .filter_map(|id| {
                    id_to_index
                        .get(id)
                        .copied()
                        .map(|idx| (idx, &nodes[id]))
                })
                .collect();


            if !member_indices.is_empty() {
                let member_nodes: Vec<&NodePhysics> = member_indices.iter().map(|(_, n)| *n).collect();
                let align_forces = alignment::alignment_force(&member_nodes, constraint, 0.5);
                for ((idx, _), (afx, afy)) in member_indices.into_iter().zip(align_forces) {
                    forces[idx].0 += afx;
                    forces[idx].1 += afy;
                }
            }
        }

        for i in 0..n {
            let node = nodes.get_mut(&node_ids[i]).unwrap();
            node.vx = (node.vx + forces[i].0 * alpha) * (1.0 - config.damping);
            node.vy = (node.vy + forces[i].1 * alpha) * (1.0 - config.damping);
        }
    }
}
