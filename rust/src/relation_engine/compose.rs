use self::nudge::{nudge_group, nudge_straight_bspline};
use crate::relation_engine::config::{NudgingConfig, RoutingConfig, RoutingMode};
use crate::relation_engine::geometry::Point;
use crate::relation_engine::types::InputNode;
use std::collections::HashMap;

pub mod bundle;
pub mod crossing;
pub mod nudge;
pub mod stagger;
pub mod zorder;

pub fn compose(
    paths: &mut [Vec<Point>],
    configs: &[RoutingConfig],
    nudge_cfg: &NudgingConfig,
    nodes: &[InputNode],
    relation_ids: &[String],
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
        "#ff6b6b", "#51cf66", "#339af0", "#fcc419", "#cc5de8", "#20c997", "#ff922b", "#748ffc",
        "#f06595", "#38d9a9",
    ];

    let mut nudge_groups_to_save: Vec<Vec<String>> = Vec::new();

    for indices in groups.values() {
        if indices.len() < 2 {
            continue;
        }
        let group_debug = nudge_group(paths, indices, nudge_cfg, nodes);
        for (g, inner_groups) in group_debug.iter().enumerate() {
            let color = palette[g % palette.len()];
            let mut group_ids = Vec::new();
            for &(gi, v_start, v_end) in inner_groups {
                let path_idx = indices[gi];
                let id = &relation_ids[path_idx];
                if !group_ids.contains(id) {
                    group_ids.push(id.clone());
                }
                let s = v_start.min(v_end);
                let e = v_start.max(v_end);
                while path_colors[path_idx].len() <= e {
                    path_colors[path_idx].push(String::new());
                }
                for si in s..e {
                    path_colors[path_idx][si] = color.to_string();
                }
            }
            if !group_ids.is_empty() {
                nudge_groups_to_save.push(group_ids);
            }
        }
    }

    // Save line groups for debugging (only in debug/test builds)
    #[cfg(any(debug_assertions, test))]
    {
        if !nudge_groups_to_save.is_empty() {
            let _ = std::fs::create_dir_all("target");
            if let Ok(file) = std::fs::File::create("target/nudge_line_groups.json") {
                let _ = serde_json::to_writer_pretty(file, &nudge_groups_to_save);
            }
        } else {
            let _ = std::fs::remove_file("target/nudge_line_groups.json");
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
