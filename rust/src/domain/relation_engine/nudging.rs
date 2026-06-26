use std::collections::HashMap;

use super::geometry::Point;
use super::vpsc::VpscSolver;

pub struct NudgeConfig {
    pub enabled: bool,
    pub min_separation: f64,
    pub nudge_final_segments: bool,
}

impl Default for NudgeConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            min_separation: 4.0,
            nudge_final_segments: true,
        }
    }
}

pub fn nudge_edges(
    edge_paths: &mut [Vec<Point>],
    _edge_ids: &[String],
    from_node_ids: &[String],
    to_node_ids: &[String],
    config: &NudgeConfig,
) {
    if !config.enabled || edge_paths.is_empty() {
        return;
    }

    let min_sep = config.min_separation;

    nudge_dimension(edge_paths, from_node_ids, to_node_ids, min_sep, true, config);
    nudge_dimension(edge_paths, from_node_ids, to_node_ids, min_sep, false, config);
}

fn nudge_dimension(
    edge_paths: &mut [Vec<Point>],
    from_node_ids: &[String],
    to_node_ids: &[String],
    min_sep: f64,
    is_x_dim: bool,
    config: &NudgeConfig,
) {
    let mut source_groups: HashMap<&str, Vec<usize>> = HashMap::new();
    for (i, from_id) in from_node_ids.iter().enumerate() {
        source_groups.entry(from_id.as_str()).or_default().push(i);
    }

    let mut target_groups: HashMap<&str, Vec<usize>> = HashMap::new();
    for (i, to_id) in to_node_ids.iter().enumerate() {
        target_groups.entry(to_id.as_str()).or_default().push(i);
    }

    let mut segments: Vec<NudgeSegment> = Vec::new();

    for (_node_id, group) in &source_groups {
        if group.len() < 2 {
            continue;
        }
        collect_segments(&mut segments, group, edge_paths, is_x_dim, true, config);
    }

    for (_node_id, group) in &target_groups {
        if group.len() < 2 {
            continue;
        }
        collect_segments(&mut segments, group, edge_paths, is_x_dim, false, config);
    }

    if segments.is_empty() {
        return;
    }

    let mut solver = VpscSolver::new();
    let mut var_map: HashMap<(usize, bool), usize> = HashMap::new();

    for seg in &segments {
        let key = (seg.edge_idx, seg.is_source);
        if var_map.contains_key(&key) {
            continue;
        }
        let current_pos = get_segment_position(edge_paths, seg.edge_idx, seg.is_source, is_x_dim);
        let var_id = solver.add_variable(current_pos, 1.0);
        var_map.insert(key, var_id);
    }

    for i in 0..segments.len() {
        for j in (i + 1)..segments.len() {
            let seg_i = &segments[i];
            let seg_j = &segments[j];

            if seg_i.edge_idx == seg_j.edge_idx && seg_i.is_source == seg_j.is_source {
                continue;
            }

            let key_i = (seg_i.edge_idx, seg_i.is_source);
            let key_j = (seg_j.edge_idx, seg_j.is_source);

            if let (Some(&var_i), Some(&var_j)) = (var_map.get(&key_i), var_map.get(&key_j)) {
                let pos_i = get_segment_position(edge_paths, seg_i.edge_idx, seg_i.is_source, is_x_dim);
                let pos_j = get_segment_position(edge_paths, seg_j.edge_idx, seg_j.is_source, is_x_dim);

                if pos_i < pos_j {
                    solver.add_constraint(var_i, var_j, min_sep, 1.0);
                } else {
                    solver.add_constraint(var_j, var_i, min_sep, 1.0);
                }
            }
        }
    }

    solver.solve();
    let positions = solver.get_positions();

    for seg in &segments {
        let key = (seg.edge_idx, seg.is_source);
        if let Some(&var_id) = var_map.get(&key) {
            let new_pos = positions[var_id];
            apply_nudge_offset(edge_paths, seg.edge_idx, seg.is_source, is_x_dim, new_pos, config);
        }
    }
}

#[derive(Debug, Clone)]
struct NudgeSegment {
    edge_idx: usize,
    is_source: bool,
    _angle: f64,
}

fn collect_segments(
    segments: &mut Vec<NudgeSegment>,
    group: &[usize],
    edge_paths: &[Vec<Point>],
    _is_x_dim: bool,
    is_source: bool,
    _config: &NudgeConfig,
) {
    for &edge_idx in group {
        let path = &edge_paths[edge_idx];
        if path.len() < 2 {
            continue;
        }

        let angle = if is_source {
            let dir = path[1] - path[0];
            dir.y.atan2(dir.x)
        } else {
            let last = path.len() - 1;
            let dir = path[last] - path[last - 1];
            dir.y.atan2(dir.x)
        };

        segments.push(NudgeSegment {
            edge_idx,
            is_source,
            _angle: angle,
        });
    }
}

fn get_segment_position(
    edge_paths: &[Vec<Point>],
    edge_idx: usize,
    is_source: bool,
    is_x_dim: bool,
) -> f64 {
    let path = &edge_paths[edge_idx];
    if path.is_empty() {
        return 0.0;
    }

    let point = if is_source { path[0] } else { path[path.len() - 1] };

    if is_x_dim {
        point.x
    } else {
        point.y
    }
}

fn apply_nudge_offset(
    edge_paths: &mut [Vec<Point>],
    edge_idx: usize,
    is_source: bool,
    is_x_dim: bool,
    new_pos: f64,
    _config: &NudgeConfig,
) {
    let path = &mut edge_paths[edge_idx];
    if path.len() < 2 {
        return;
    }

    let point = if is_source { path[0] } else { path[path.len() - 1] };
    let current_pos = if is_x_dim { point.x } else { point.y };
    let delta = new_pos - current_pos;

    if delta.abs() < 1e-6 {
        return;
    }

    let total_len: f64 = path.windows(2).map(|w| w[0].distance_to(w[1])).sum();
    let decay_dist = total_len * 0.5;

    if decay_dist < 1e-6 {
        return;
    }

    let mut accum = 0.0;
    for i in 0..path.len() {
        let factor = if i == 0 {
            1.0
        } else {
            let seg_len = path[i - 1].distance_to(path[i]);
            accum += seg_len;
            (1.0 - accum / decay_dist).max(0.0)
        };

        if is_x_dim {
            path[i].x += delta * factor;
        } else {
            path[i].y += delta * factor;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nudge_disabled_does_nothing() {
        let mut paths = vec![vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)]];
        let original = paths.clone();
        let config = NudgeConfig {
            enabled: false,
            ..Default::default()
        };
        nudge_edges(
            &mut paths,
            &["e1".into()],
            &["n1".into()],
            &["n2".into()],
            &config,
        );
        assert_eq!(paths, original);
    }

    #[test]
    fn test_single_edge_no_nudge() {
        let mut paths = vec![vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)]];
        let original = paths.clone();
        let config = NudgeConfig::default();
        nudge_edges(
            &mut paths,
            &["e1".into()],
            &["n1".into()],
            &["n2".into()],
            &config,
        );
        assert_eq!(paths, original);
    }

    #[test]
    fn test_two_edges_from_same_source_get_nudged() {
        let mut paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)],
            vec![Point::new(0.0, 0.0), Point::new(100.0, 10.0)],
        ];
        let config = NudgeConfig {
            min_separation: 8.0,
            ..Default::default()
        };
        nudge_edges(
            &mut paths,
            &["e1".into(), "e2".into()],
            &["n1".into(), "n1".into()],
            &["n2".into(), "n3".into()],
            &config,
        );
        let y0 = paths[0][0].y;
        let y1 = paths[1][0].y;
        assert!(
            (y0 - y1).abs() > 1.0,
            "Edges should be separated: y0={}, y1={}",
            y0,
            y1
        );
    }

    #[test]
    fn test_vpsc_solver_separates_overlapping() {
        let mut solver = VpscSolver::new();
        let v0 = solver.add_variable(10.0, 1.0);
        let v1 = solver.add_variable(12.0, 1.0);
        solver.add_constraint(v0, v1, 5.0, 1.0);
        solver.solve();
        let pos = solver.get_positions();
        assert!(pos[1] - pos[0] >= 4.99);
    }

    #[test]
    fn test_nudge_preserves_path_length() {
        let mut paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(50.0, 0.0), Point::new(100.0, 0.0)],
            vec![Point::new(0.0, 0.0), Point::new(50.0, 0.0), Point::new(100.0, 10.0)],
        ];
        let len_before_0: f64 = paths[0].windows(2).map(|w| w[0].distance_to(w[1])).sum();
        let config = NudgeConfig {
            min_separation: 8.0,
            ..Default::default()
        };
        nudge_edges(
            &mut paths,
            &["e1".into(), "e2".into()],
            &["n1".into(), "n1".into()],
            &["n2".into(), "n3".into()],
            &config,
        );
        let len_after_0: f64 = paths[0].windows(2).map(|w| w[0].distance_to(w[1])).sum();
        let len_after_1: f64 = paths[1].windows(2).map(|w| w[0].distance_to(w[1])).sum();
        assert!(len_after_0 > 50.0, "Path 0 length after nudge: {}", len_after_0);
        assert!(len_after_1 > 50.0, "Path 1 length after nudge: {}", len_after_1);
        let ratio = len_after_0 / len_before_0;
        assert!(ratio > 0.8 && ratio < 1.5, "Length change too large: {}", ratio);
    }
}
