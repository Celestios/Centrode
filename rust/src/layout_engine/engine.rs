use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::domain::styles::PortSide;
use crate::layout_engine::config::LayoutConfig;
use crate::layout_engine::forces::ForceAccumulator;
use crate::layout_engine::integration;
use crate::layout_engine::port_optimizer;
use crate::layout_engine::state::LayoutState;
use crate::layout_engine::types::{
    AlignmentConstraint, AnchorSpring, Axis, LayoutEdge, LayoutPatch, LayoutTickResult, NodePhysics,
    PortPatch,
};

pub struct LayoutEngine {
    pub state: LayoutState,
    pub config: LayoutConfig,
}

impl LayoutEngine {
    pub fn new(config: LayoutConfig) -> Self {
        Self {
            state: LayoutState::new(),
            config,
        }
    }

    pub fn sync_from_canvas(
        &mut self,
        nodes: &[Nodes],
        edges: &[IRelation],
        opt_area: Option<BoundingBox>,
        live_positions: &[LayoutPatch],
    ) {
        let live_map: std::collections::HashMap<TypedRecordId, (f64, f64)> = live_positions
            .iter()
            .map(|p| (p.id.clone(), (p.x, p.y)))
            .collect();

        self.state.opt_area = opt_area;
        self.state.nodes.clear();
        self.state.energy_history.clear();

        if let Some(ref area) = self.state.opt_area {
            for node in nodes {
                if matches!(node, Nodes::InterNode(_)) {
                    continue;
                }

                let id = *node.id();
                let (x, y) = if let Some(&(lx, ly)) = live_map.get(&id) {
                    (lx, ly)
                } else {
                    let pos = node.position();
                    (pos.x as f64, pos.y as f64)
                };
                let (width, height) = node_size(node);

                if x + width >= area.min_x
                    && x <= area.max_x
                    && y + height >= area.min_y
                    && y <= area.max_y
                {
                    self.state.nodes.insert(
                        id,
                        NodePhysics {
                            id,
                            x,
                            y,
                            width,
                            height,
                            vx: 0.0,
                            vy: 0.0,
                        },
                    );
                }
            }
        }

        self.state.edges.clear();
        for rel in edges {
            if self.state.nodes.contains_key(&rel.in_)
                && self.state.nodes.contains_key(&rel.out)
            {
                let from_side = rel.fields.layout.as_ref().and_then(|l| l.from_side);
                let to_side = rel.fields.layout.as_ref().and_then(|l| l.to_side);
                self.state.edges.push(LayoutEdge {
                    id: rel.key,
                    from_id: rel.in_,
                    to_id: rel.out,
                    from_side,
                    to_side,
                });
            }
        }

        self.state.alpha = 0.5;
        self.state.iteration = 0;
    }

    pub fn add_anchor_spring(&mut self, node_id: TypedRecordId, x: f64, y: f64, strength: f64) {
        self.state.anchors.insert(
            node_id,
            AnchorSpring {
                anchor_x: x,
                anchor_y: y,
                strength,
                decay_rate: 0.05,
            },
        );
    }

    pub fn set_alignment_constraint(&mut self, node_ids: Vec<TypedRecordId>, axis: Axis) {
        self.state.alignments.push(AlignmentConstraint { node_ids, axis });
    }

    pub fn compute_auto_placement(
        &self,
        source_id: TypedRecordId,
        port_side: PortSide,
    ) -> Option<(f64, f64)> {
        let source = self.state.nodes.get(&source_id)?;
        let (source_x, source_y, s_w, s_h) = (source.x, source.y, source.width, source.height);

        let (dir_x, dir_y) = match port_side {
            PortSide::Right => (1.0, 0.0),
            PortSide::Left => (-1.0, 0.0),
            PortSide::Bottom => (0.0, 1.0),
            PortSide::Top => (0.0, -1.0),
            PortSide::TopRight => (std::f64::consts::FRAC_1_SQRT_2, -std::f64::consts::FRAC_1_SQRT_2),
            PortSide::TopLeft => (-std::f64::consts::FRAC_1_SQRT_2, -std::f64::consts::FRAC_1_SQRT_2),
            PortSide::BottomRight => (std::f64::consts::FRAC_1_SQRT_2, std::f64::consts::FRAC_1_SQRT_2),
            PortSide::BottomLeft => (-std::f64::consts::FRAC_1_SQRT_2, std::f64::consts::FRAC_1_SQRT_2),
            PortSide::Auto => (1.0, 0.0),
        };

        let dist = self.config.force.ideal_link_distance;
        let mut target_x = source_x + (s_w / 2.0) + (dir_x * dist) - 80.0;
        let mut target_y = source_y + (s_h / 2.0) + (dir_y * dist) - 40.0;

        let new_w = 160.0;
        let new_h = 80.0;

        // Collision avoidance offset against existing nodes
        for node in self.state.nodes.values() {
            if node.id == source_id {
                continue;
            }

            let margin = self.config.force.base_margin;
            let overlap_x = (new_w / 2.0 + node.width / 2.0 + margin)
                - ((target_x + new_w / 2.0) - node.cx()).abs();
            let overlap_y = (new_h / 2.0 + node.height / 2.0 + margin)
                - ((target_y + new_h / 2.0) - node.cy()).abs();

            if overlap_x > 0.0 && overlap_y > 0.0 {
                if overlap_x < overlap_y {
                    let sign = if target_x >= node.x { 1.0 } else { -1.0 };
                    target_x += overlap_x * sign;
                } else {
                    let sign = if target_y >= node.y { 1.0 } else { -1.0 };
                    target_y += overlap_y * sign;
                }
            }
        }

        // Clamp inside OptArea
        if let Some(ref area) = self.state.opt_area {
            let padding = self.config.force.wall_padding;
            target_x = target_x.clamp(area.min_x + padding, area.max_x - new_w - padding);
            target_y = target_y.clamp(area.min_y + padding, area.max_y - new_h - padding);
        }

        Some((target_x, target_y))
    }


    pub fn run_batch(&mut self) -> LayoutTickResult {
        let batch_size = self.config.batch_size;

        for _ in 0..batch_size {
            if self.state.alpha < self.config.force.alpha_min {
                break;
            }

            ForceAccumulator::accumulate(
                &mut self.state.nodes,
                &self.state.edges,
                &self.state.opt_area,
                &self.state.anchors,
                &self.state.alignments,
                &self.config.force,
                self.state.alpha,
            );

            integration::integrate_positions(&mut self.state.nodes, 1.0);

            if let Some(ref area) = self.state.opt_area {
                integration::clamp_to_walls(
                    &mut self.state.nodes,
                    area,
                    self.config.force.wall_padding,
                );
            }

            // Decay anchors
            self.state.anchors.retain(|_, anchor| {
                anchor.strength *= 1.0 - anchor.decay_rate;
                anchor.strength >= 0.01
            });

            self.state.alpha =
                integration::decay_alpha(self.state.alpha, self.config.force.alpha_decay);
            self.state.iteration += 1;
        }

        let position_patches: Vec<LayoutPatch> = self
            .state
            .nodes
            .values()
            .map(|node| LayoutPatch {
                id: node.id,
                x: node.x,
                y: node.y,
            })
            .collect();

        let mut port_patches: Vec<PortPatch> = Vec::new();
        for edge in &self.state.edges {
            let is_auto_from = edge.from_side.map_or(true, |s| s == PortSide::Auto);
            let is_auto_to = edge.to_side.map_or(true, |s| s == PortSide::Auto);

            if is_auto_from || is_auto_to {
                if let (Some(source), Some(target)) = (
                    self.state.nodes.get(&edge.from_id),
                    self.state.nodes.get(&edge.to_id),
                ) {
                    let (opt_from, opt_to) = port_optimizer::compute_optimal_ports(source, target);
                    port_patches.push(PortPatch {
                        relation_id: edge.id,
                        from_side: if is_auto_from { opt_from } else { edge.from_side.unwrap() },
                        to_side: if is_auto_to { opt_to } else { edge.to_side.unwrap() },
                    });
                }
            }
        }

        let energy = integration::compute_energy(&self.state.nodes);
        let max_disp = integration::max_velocity(&self.state.nodes);

        self.state.energy_history.push(energy);
        let oscillating = self.is_oscillating();

        let converged = self.state.alpha < self.config.force.alpha_min
            || self.state.iteration >= self.config.convergence.max_iterations
            || energy < self.config.convergence.energy_threshold
            || max_disp < self.config.convergence.displacement_threshold
            || oscillating;

        LayoutTickResult {
            position_patches,
            port_patches,
            converged,
            iteration: self.state.iteration,
            energy,
        }
    }

    fn is_oscillating(&self) -> bool {
        let window = self.config.convergence.oscillation_window as usize;
        let history = &self.state.energy_history;
        let min_warmup = window * 3;
        if history.len() < min_warmup {
            return false;
        }
        let start = history.len() - window;
        let peak = history[..start]
            .iter()
            .copied()
            .fold(0.0f64, f64::max);
        if peak < 1e-6 {
            return false;
        }
        let recent_min = history[start..]
            .iter()
            .copied()
            .fold(f64::INFINITY, f64::min);
        let recent_max = history[start..]
            .iter()
            .copied()
            .fold(0.0f64, f64::max);
        let range = recent_max - recent_min;
        range < peak * 0.05
    }
}

fn node_size(node: &Nodes) -> (f64, f64) {
    node.dimensions()
}

