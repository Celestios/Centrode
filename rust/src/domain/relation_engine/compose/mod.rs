pub mod bundle;
pub mod nudge;
pub mod crossing;
pub mod zorder;
pub mod stagger;

use std::collections::HashMap;
use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::types::InputNode;
use crate::domain::relation_engine::config::{RoutingConfig, RoutingMode, NudgingConfig};
use self::nudge::{nudge_group, nudge_straight_bspline};

pub fn compose(
    paths: &mut [Vec<Point>],
    configs: &[RoutingConfig],
    nudge_cfg: &NudgingConfig,
    nodes: &[InputNode],
) -> Vec<Vec<String>> {
    let mut groups: HashMap<u8, Vec<usize>> = HashMap::new();
    for (i, config) in configs.iter().enumerate() {
        let key = match config.routing_mode {
            RoutingMode::Orthogonal => 0,
            RoutingMode::BSpline => 2,
            _ => continue,
        };
        groups.entry(key).or_default().push(i);
    }

    let mut path_colors: Vec<Vec<String>> = vec![Vec::new(); paths.len()];
    let palette = [
        "#ff6b6b", "#51cf66", "#339af0", "#fcc419", "#cc5de8",
        "#20c997", "#ff922b", "#748ffc", "#f06595", "#38d9a9",
    ];

    for indices in groups.values() {
        if indices.len() < 2 {
            continue;
        }
        let group_debug = nudge_group(paths, indices, nudge_cfg, nodes);
        for (g, inner_groups) in group_debug.iter().enumerate() {
            let color = palette[g % palette.len()];
            for &(gi, v_start, v_end) in inner_groups {
                let path_idx = indices[gi];
                let s = v_start.min(v_end);
                let e = v_start.max(v_end);
                while path_colors[path_idx].len() <= e {
                    path_colors[path_idx].push(String::new());
                }
                for si in s..e {
                    path_colors[path_idx][si] = color.to_string();
                }
            }
        }
    }

    for (i, config) in configs.iter().enumerate() {
        if config.routing_mode == RoutingMode::BSpline {
            let amp = config.nudge_amplitude();
            let count = config.nudge_count();
            if amp > 0.0 && count >= 2 {
                nudge_straight_bspline(&mut paths[i], amp, count);
            }
        }
    }

    path_colors
}
