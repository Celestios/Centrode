use crate::domain::base_models::BoundingBox;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::layout_engine::config::LayoutConfig;
use crate::layout_engine::forces::ForceAccumulator;
use crate::layout_engine::integration;
use crate::layout_engine::state::LayoutState;
use crate::layout_engine::types::{LayoutEdge, LayoutPatch, LayoutTickResult, NodePhysics};

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
    ) {
        self.state.opt_area = opt_area;
        self.state.nodes.clear();
        self.state.energy_history.clear();

        if let Some(ref area) = self.state.opt_area {
            for node in nodes {
                if matches!(node, Nodes::InterNode(_)) {
                    continue;
                }

                let id = *node.id();
                let pos = node.position();
                let (x, y) = (pos.x as f64, pos.y as f64);
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
                self.state.edges.push(LayoutEdge {
                    id: rel.key,
                    from_id: rel.in_,
                    to_id: rel.out,
                });
            }
        }

        self.state.alpha = 1.0;
        self.state.iteration = 0;
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
            converged,
            iteration: self.state.iteration,
            energy,
        }
    }

    fn is_oscillating(&self) -> bool {
        let window = self.config.convergence.oscillation_window as usize;
        let history = &self.state.energy_history;
        if history.len() < window + 1 {
            return false;
        }
        let start = history.len() - window;
        let baseline = history[start - 1];
        history[start..].iter().all(|&e| e >= baseline)
    }
}

fn node_size(node: &Nodes) -> (f64, f64) {
    match node {
        Nodes::INode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::TaskNode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::CommentNode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::DrawingNode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::ShapeNode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::FrameNode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::MediaNode(n) => (n.size.width as f64, n.size.height as f64),
        Nodes::InterNode(_) => (0.0, 0.0),
    }
}
