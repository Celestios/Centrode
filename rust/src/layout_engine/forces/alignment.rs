use crate::layout_engine::types::{AlignmentConstraint, Axis, NodePhysics};

pub fn alignment_force(
    nodes: &[&NodePhysics],
    constraint: &AlignmentConstraint,
    k_align: f64,
) -> Vec<(f64, f64)> {
    if nodes.is_empty() {
        return Vec::new();
    }

    let target = match constraint.axis {
        Axis::Horizontal => {
            nodes.iter().map(|n| n.cy()).sum::<f64>() / (nodes.len() as f64)
        }
        Axis::Vertical => {
            nodes.iter().map(|n| n.cx()).sum::<f64>() / (nodes.len() as f64)
        }
    };

    nodes
        .iter()
        .map(|n| match constraint.axis {
            Axis::Horizontal => (0.0, -k_align * (n.cy() - target)),
            Axis::Vertical => (-k_align * (n.cx() - target), 0.0),
        })
        .collect()
}
