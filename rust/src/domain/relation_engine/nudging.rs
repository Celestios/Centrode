use std::collections::HashMap;

use super::geometry::Point;

/// Nudges overlapping edges apart by applying perpendicular offsets.
///
/// Edges sharing an endpoint (same source or target node) are grouped,
/// sorted by angle, and assigned staggered offsets to create visual separation.
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

    // Group edges by shared source node
    let mut source_groups: HashMap<&str, Vec<usize>> = HashMap::new();
    for (i, from_id) in from_node_ids.iter().enumerate() {
        source_groups.entry(from_id.as_str()).or_default().push(i);
    }

    // Group edges by shared target node
    let mut target_groups: HashMap<&str, Vec<usize>> = HashMap::new();
    for (i, to_id) in to_node_ids.iter().enumerate() {
        target_groups.entry(to_id.as_str()).or_default().push(i);
    }

    // Track cumulative offsets per edge
    let mut offsets: Vec<Point> = vec![Point::zero(); edge_paths.len()];

    // Nudge at shared source endpoints
    for (_node_id, group) in &source_groups {
        if group.len() < 2 {
            continue;
        }
        let group_offsets = compute_group_offsets(group, edge_paths, from_node_ids, true, min_sep);
        for (i, idx) in group.iter().enumerate() {
            offsets[*idx] = offsets[*idx] + group_offsets[i];
        }
    }

    // Nudge at shared target endpoints
    for (_node_id, group) in &target_groups {
        if group.len() < 2 {
            continue;
        }
        let group_offsets = compute_group_offsets(group, edge_paths, to_node_ids, false, min_sep);
        for (i, idx) in group.iter().enumerate() {
            offsets[*idx] = offsets[*idx] + group_offsets[i];
        }
    }

    // Apply offsets to path points — offset decays from endpoint toward midpoint
    for (i, path) in edge_paths.iter_mut().enumerate() {
        if path.len() < 2 {
            continue;
        }
        let off = offsets[i];
        if off.x.abs() < 1e-6 && off.y.abs() < 1e-6 {
            continue;
        }
        apply_decaying_offset(path, off);
    }
}

fn compute_group_offsets(
    group: &[usize],
    edge_paths: &[Vec<Point>],
    _node_ids: &[String],
    is_source: bool,
    min_sep: f64,
) -> Vec<Point> {
    let n = group.len();
    if n < 2 {
        return vec![Point::zero(); n];
    }

    // Compute angle of each edge's first/last segment relative to the shared node
    let mut indexed_angles: Vec<(usize, f64)> = group
        .iter()
        .enumerate()
        .map(|(local_i, &edge_i)| {
            let path = &edge_paths[edge_i];
            let angle = if is_source {
                // Angle of first segment from source
                if path.len() >= 2 {
                    let dir = path[1] - path[0];
                    dir.y.atan2(dir.x)
                } else {
                    0.0
                }
            } else {
                // Angle of last segment toward target
                if path.len() >= 2 {
                    let last = path.len() - 1;
                    let dir = path[last] - path[last - 1];
                    dir.y.atan2(dir.x)
                } else {
                    0.0
                }
            };
            (local_i, angle)
        })
        .collect();

    // Sort by angle
    indexed_angles.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap());

    // Assign staggered perpendicular offsets
    let mut result = vec![Point::zero(); n];
    let total_width = (n - 1) as f64 * min_sep;
    let mut rank = 0.0;

    for (local_i, _angle) in &indexed_angles {
        let offset_y = (rank - total_width / 2.0) * 1.0; // vertical spread
        result[*local_i] = Point::new(0.0, offset_y);
        rank += min_sep;
    }

    result
}

fn apply_decaying_offset(path: &mut [Point], offset: Point) {
    let n = path.len();
    if n < 2 {
        return;
    }

    // Maximum decay distance: half the path length
    let total_len: f64 = path.windows(2).map(|w| w[0].distance_to(w[1])).sum();
    let decay_dist = total_len * 0.5;
    if decay_dist < 1e-6 {
        return;
    }

    // Apply full offset at first point, decay to zero at decay_dist along the path
    let mut accum = 0.0;
    for i in 0..n {
        let factor = if i == 0 {
            1.0
        } else {
            let seg_len = path[i - 1].distance_to(path[i]);
            accum += seg_len;
            (1.0 - accum / decay_dist).max(0.0)
        };
        path[i] = path[i] + offset * factor;
    }
}

#[derive(Debug, Clone)]
pub struct NudgeConfig {
    pub enabled: bool,
    pub min_separation: f64,
}

impl Default for NudgeConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            min_separation: 4.0,
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
        // Both edges should have different y-offsets at start
        let y0 = paths[0][0].y;
        let y1 = paths[1][0].y;
        assert!(
            (y0 - y1).abs() > 1.0,
            "Edges should be separated: y0={}, y1={}",
            y0,
            y1
        );
    }
}
