use std::collections::HashMap;
use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::types::InputNode;
use crate::domain::relation_engine::config::NudgingConfig;

/// Below this shift magnitude, a run is left alone rather than nudged.
const MIN_SHIFT: f64 = 0.5;
/// Extra clearance added around a node body when treating it as an obstacle.
const NODE_MARGIN: f64 = 5.0;
/// Tolerance used to decide whether a segment is axis-aligned vs. diagonal.
const DIR_EPS: f64 = 1e-9;
/// Tolerance for treating a segment as zero-length (and skipping it).
const ZERO_LENGTH_EPS: f64 = 1e-9;
/// Below this amount of free space, obstacle-avoidance is abandoned in
/// favor of a plain linear layout.
const MIN_FREE_SPACE: f64 = 1.0;

/// A grid direction, e.g. `(1, 0)` for rightward, `(1, 1)` for a diagonal.
type Dir = (i32, i32);

/// The axis a run travels along, relative to the coordinate grid.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Orientation {
    Horizontal,
    Vertical,
    Diagonal,
}

impl Orientation {
    fn of(dir: Dir) -> Self {
        match (dir.0 != 0, dir.1 != 0) {
            (true, false) => Orientation::Horizontal,
            (false, true) => Orientation::Vertical,
            _ => Orientation::Diagonal,
        }
    }
}

/// A single straight-line segment within one path, plus the geometry
/// needed to compare it against runs from other paths.
#[derive(Clone, Debug)]
struct Run {
    gi: usize,
    dir: Dir,
    start_v: usize,
    end_v: usize,
    perp_pos: f64,
    length: f64,
    proj_start: f64,
    proj_end: f64,
}

fn direction_key(d: Dir) -> Dir {
    (d.0.signum(), d.1.signum())
}

fn is_parallel(a: Dir, b: Dir) -> bool {
    let ka = direction_key(a);
    let kb = direction_key(b);
    ka == kb || ka == (-kb.0, -kb.1)
}

fn extract_runs(path: &[Point], gi: usize) -> Vec<Run> {
    let mut runs = Vec::new();
    if path.len() < 2 {
        return runs;
    }

    for i in 0..path.len() - 1 {
        let a = path[i];
        let b = path[i + 1];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        if dx.abs() < ZERO_LENGTH_EPS && dy.abs() < ZERO_LENGTH_EPS {
            continue;
        }

        let dir = if dx.abs() > dy.abs() + DIR_EPS {
            (dx.signum() as i32, 0)
        } else if dy.abs() > dx.abs() + DIR_EPS {
            (0, dy.signum() as i32)
        } else {
            (dx.signum() as i32, dy.signum() as i32)
        };

        let perp_pos = if dir.0 != 0 && dir.1 != 0 {
            -(dir.1 as f64) * a.x + (dir.0 as f64) * a.y
        } else if dir.0 != 0 {
            a.y
        } else {
            a.x
        };

        let (p_start, p_end) = if dir.0 != 0 { (a.x, b.x) } else { (a.y, b.y) };
        runs.push(Run {
            gi,
            dir,
            start_v: i,
            end_v: i + 1,
            perp_pos,
            length: a.distance_to(b),
            proj_start: p_start.min(p_end),
            proj_end: p_start.max(p_end),
        });
    }
    runs
}

fn projections_overlap(a: &Run, b: &Run) -> bool {
    a.proj_start.max(b.proj_start) < a.proj_end.min(b.proj_end)
}

struct UnionFind {
    parent: Vec<usize>,
}

impl UnionFind {
    fn new(n: usize) -> Self {
        Self { parent: (0..n).collect() }
    }

    fn find(&mut self, x: usize) -> usize {
        let mut root = x;
        while self.parent[root] != root {
            root = self.parent[root];
        }
        let mut cur = x;
        while self.parent[cur] != root {
            let next = self.parent[cur];
            self.parent[cur] = root;
            cur = next;
        }
        root
    }

    fn union(&mut self, a: usize, b: usize) {
        let (ra, rb) = (self.find(a), self.find(b));
        if ra != rb {
            self.parent[ra] = rb;
        }
    }
}

fn group_runs(runs: &[Run], radius: f64) -> Vec<Vec<usize>> {
    let n = runs.len();
    let mut uf = UnionFind::new(n);

    for i in 0..n {
        for j in (i + 1)..n {
            let (a, b) = (&runs[i], &runs[j]);
            if a.gi == b.gi {
                continue;
            }
            if !is_parallel(a.dir, b.dir) {
                continue;
            }
            if (a.perp_pos - b.perp_pos).abs() > radius {
                continue;
            }
            if !projections_overlap(a, b) {
                continue;
            }
            uf.union(i, j);
        }
    }

    let mut groups: HashMap<usize, Vec<usize>> = HashMap::new();
    for i in 0..n {
        let root = uf.find(i);
        groups.entry(root).or_default().push(i);
    }

    groups.into_values().filter(|g| g.len() >= 2).collect()
}

fn group_priority(group: &[usize], runs: &[Run]) -> (usize, f64) {
    let total_len: f64 = group.iter().map(|&i| runs[i].length).sum();
    (group.len(), total_len)
}

fn sort_by_perp_pos(group: &[usize], runs: &[Run]) -> Vec<usize> {
    let mut order: Vec<usize> = (0..group.len()).collect();
    order.sort_by(|&a, &b| runs[group[a]].perp_pos.total_cmp(&runs[group[b]].perp_pos));
    order
}

fn blocked_intervals(
    group: &[usize],
    runs: &[Run],
    orientation: Orientation,
    nodes: &[InputNode],
) -> Vec<(f64, f64)> {
    if orientation == Orientation::Diagonal || nodes.is_empty() {
        return Vec::new();
    }

    let proj_min = group.iter().map(|&ri| runs[ri].proj_start).fold(f64::MAX, f64::min);
    let proj_max = group.iter().map(|&ri| runs[ri].proj_end).fold(f64::MIN, f64::max);

    let mut raw: Vec<(f64, f64)> = nodes
        .iter()
        .filter(|node| match orientation {
            Orientation::Horizontal => proj_min < node.x + node.width && proj_max > node.x,
            Orientation::Vertical => proj_min < node.y + node.height && proj_max > node.y,
            Orientation::Diagonal => unreachable!(),
        })
        .filter_map(|node| {
            let (b0, b1) = match orientation {
                Orientation::Horizontal => {
                    (node.y - NODE_MARGIN, node.y + node.height + NODE_MARGIN)
                }
                Orientation::Vertical => {
                    (node.x - NODE_MARGIN, node.x + node.width + NODE_MARGIN)
                }
                Orientation::Diagonal => unreachable!(),
            };
            (b0 < b1).then_some((b0, b1))
        })
        .collect();

    raw.sort_by(|a, b| a.0.total_cmp(&b.0));
    merge_intervals(raw)
}

fn merge_intervals(sorted: Vec<(f64, f64)>) -> Vec<(f64, f64)> {
    let mut merged: Vec<(f64, f64)> = Vec::new();
    for b in sorted {
        match merged.last_mut() {
            Some(last) if b.0 <= last.1 => last.1 = last.1.max(b.1),
            _ => merged.push(b),
        }
    }
    merged
}

fn subtract_intervals(start: f64, end: f64, blocked: &[(f64, f64)]) -> Vec<(f64, f64)> {
    let mut free = vec![(start, end)];
    for &(b0, b1) in blocked {
        let mut next = Vec::new();
        for &(fs, fe) in &free {
            if b0 >= fe || b1 <= fs {
                next.push((fs, fe));
            } else {
                if fs < b0 {
                    next.push((fs, b0));
                }
                if fe > b1 {
                    next.push((b1, fe));
                }
            }
        }
        free = next;
    }
    free
}

fn linear_targets(start_pos: f64, spread: f64, n: usize, min_spacing: f64) -> Vec<f64> {
    let spacing = min_spacing.max(spread / (n - 1) as f64);
    (0..n).map(|i| start_pos + i as f64 * spacing).collect()
}

fn place_in_free_ranges(mut offset: f64, free_ranges: &[(f64, f64)], fallback: f64) -> f64 {
    for &(fs, fe) in free_ranges {
        let len = fe - fs;
        if offset <= len {
            return fs + offset;
        }
        offset -= len;
    }
    fallback
}

fn compute_targets(min_p: f64, max_p: f64, n: usize, min_spacing: f64, blocked: &[(f64, f64)]) -> Vec<f64> {
    let spread = max_p - min_p;
    let center = (min_p + max_p) / 2.0;
    let required = min_spacing * (n - 1) as f64;
    let total_span = spread.max(required);
    let start_pos = center - total_span / 2.0;

    if blocked.is_empty() {
        return linear_targets(start_pos, spread, n, min_spacing);
    }

    let end_pos = start_pos + total_span;
    let free_ranges = subtract_intervals(start_pos, end_pos, blocked);
    let total_free: f64 = free_ranges.iter().map(|&(s, e)| (e - s).max(0.0)).sum();

    if total_free < MIN_FREE_SPACE {
        return linear_targets(start_pos, spread, n, min_spacing);
    }

    let spacing = min_spacing.max(total_free / (n - 1) as f64);
    let actual_free = spacing * (n - 1) as f64;
    let free_offset = (total_free - actual_free) / 2.0;

    (0..n)
        .map(|i| place_in_free_ranges(free_offset + i as f64 * spacing, &free_ranges, end_pos))
        .collect()
}

fn is_movable(v: usize, last: usize) -> bool {
    v != 0 && v != last
}

fn apply_diagonal_shift(run: &Run, shift: f64, dir: Dir, path: &mut [Point], last: usize) {
    let (v_start, v_end) = (run.start_v, run.end_v);
    if is_movable(v_start, last) && is_movable(v_end, last) {
        path[v_start].x += -(dir.1 as f64) * shift;
        path[v_end].y += (dir.0 as f64) * shift;
    }
}

fn apply_axis_shift(run: &Run, shift: f64, orientation: Orientation, path: &mut [Point], last: usize) {
    let movable = (run.start_v..=run.end_v).all(|v| is_movable(v, last));
    if !movable {
        return;
    }
    for v in run.start_v..=run.end_v {
        match orientation {
            Orientation::Horizontal => path[v].y += shift,
            Orientation::Vertical => path[v].x += shift,
            Orientation::Diagonal => unreachable!(),
        }
    }
}

fn apply_shift(run: &Run, shift: f64, orientation: Orientation, dir: Dir, path: &mut [Point]) {
    let last = path.len() - 1;
    match orientation {
        Orientation::Diagonal => apply_diagonal_shift(run, shift, dir, path, last),
        Orientation::Horizontal | Orientation::Vertical => {
            apply_axis_shift(run, shift, orientation, path, last)
        }
    }
}

fn even_spacing(
    group: &[usize],
    runs: &[Run],
    path_data: &mut [Vec<Point>],
    min_spacing: f64,
    nodes: &[InputNode],
) {
    let n = group.len();
    if n < 2 {
        return;
    }

    let sorted = sort_by_perp_pos(group, runs);
    let dir = runs[group[sorted[0]]].dir;
    let orientation = Orientation::of(dir);

    let pos: Vec<f64> = sorted.iter().map(|&i| runs[group[i]].perp_pos).collect();
    let blocked = blocked_intervals(group, runs, orientation, nodes);
    let targets = compute_targets(pos[0], pos[n - 1], n, min_spacing, &blocked);

    for (rank, &si) in sorted.iter().enumerate() {
        let run = &runs[group[si]];
        let shift = targets[rank] - pos[rank];
        if shift.abs() < MIN_SHIFT {
            continue;
        }
        apply_shift(run, shift, orientation, dir, &mut path_data[run.gi]);
    }
}

pub fn nudge_group(
    paths: &mut [Vec<Point>],
    indices: &[usize],
    config: &NudgingConfig,
    nodes: &[InputNode],
) -> Vec<Vec<(usize, usize, usize)>> {
    if indices.len() < 2 {
        return Vec::new();
    }

    let mut all_runs: Vec<Run> = Vec::new();
    for (gi, &idx) in indices.iter().enumerate() {
        all_runs.extend(extract_runs(&paths[idx], gi));
    }

    all_runs.retain(|run| {
        let last = paths[indices[run.gi]].len() - 1;
        run.start_v != 0 && run.end_v != last
    });

    let mut groups: Vec<(usize, f64, Vec<usize>)> = group_runs(&all_runs, config.search_radius())
        .into_iter()
        .map(|g| {
            let (size, len) = group_priority(&g, &all_runs);
            (size, len, g)
        })
        .collect();

    groups.sort_by(|a, b| b.0.cmp(&a.0).then_with(|| b.1.total_cmp(&a.1)));

    let mut path_data: Vec<Vec<Point>> = indices.iter().map(|&idx| paths[idx].clone()).collect();

    for (_, _, group) in &groups {
        even_spacing(group, &all_runs, &mut path_data, config.min_spacing(), nodes);
    }


    for (gi, &idx) in indices.iter().enumerate() {
        paths[idx] = std::mem::take(&mut path_data[gi]);
    }

    groups
        .into_iter()
        .map(|(_, _, group)| {
            group
                .into_iter()
                .map(|ri| {
                    let run = &all_runs[ri];
                    (run.gi, run.start_v, run.end_v)
                })
                .collect()
        })
        .collect()
}

pub fn nudge_straight_bspline(path: &mut Vec<Point>, amplitude: f64, count: usize) {
    if path.len() < 2 || amplitude == 0.0 || count < 2 {
        return;
    }
    let is_horizontal = path.iter().all(|p| (p.y - path[0].y).abs() < 1e-6);
    let is_vertical = path.iter().all(|p| (p.x - path[0].x).abs() < 1e-6);
    if !is_horizontal && !is_vertical {
        return;
    }
    let p_start = path[0];
    let p_end = *path.last().unwrap();
    let mut nudged = Vec::with_capacity(count);
    for i in 0..count {
        let t = i as f64 / (count - 1).max(1) as f64;
        let mut p = p_start.lerp(p_end, t);
        let nudge = amplitude * (2.0 * std::f64::consts::PI * t).sin();
        if is_horizontal {
            p.y += nudge;
        } else {
            p.x += nudge;
        }
        nudged.push(p);
    }
    *path = nudged;
}
