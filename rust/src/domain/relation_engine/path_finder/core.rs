use std::collections::{BinaryHeap, HashMap};
use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::path_finder::grid::Grid;
use crate::domain::relation_engine::path_finder::steer::{Steer, AStarContext};

#[derive(Clone, PartialEq)]
struct ANode {
    col: i32,
    row: i32,
    g: f64,
    f: f64,
}

impl Eq for ANode {}

impl Ord for ANode {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        match other.f.total_cmp(&self.f) {
            std::cmp::Ordering::Equal => {
                match self.col.cmp(&other.col) {
                    std::cmp::Ordering::Equal => self.row.cmp(&other.row),
                    ord => ord,
                }
            }
            ord => ord,
        }
    }
}

impl PartialOrd for ANode {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

fn reconstruct_path(
    came_from: &HashMap<(i32, i32), (i32, i32)>,
    grid: &Grid,
    start_key: (i32, i32),
    end_key: (i32, i32),
    start_terminus: Point,
    end_terminus: Point,
) -> Vec<Point> {
    let mut path = vec![end_terminus];
    let mut cur = end_key;
    while cur != start_key {
        let prev = *came_from.get(&cur).unwrap();
        if prev != start_key {
            path.push(grid.grid_to_world(prev.0, prev.1));
        }
        cur = prev;
    }
    path.push(start_terminus);
    path.reverse();
    path
}

pub fn a_star<S: Steer + ?Sized>(
    steer: &S,
    context: &AStarContext,
) -> Option<Vec<Point>> {
    let grid = context.grid;
    let start_terminus = context.start_terminus;
    let end_terminus = context.end_terminus;

    let (sgc, sgr) = grid.world_to_grid(start_terminus);
    let (egc, egr) = grid.world_to_grid(end_terminus);

    let start_key = (sgc, sgr);
    let end_key = (egc, egr);

    if start_key == end_key {
        return Some(vec![start_terminus, end_terminus]);
    }

    let neighbors = steer.neighbors();

    let mut open = BinaryHeap::new();
    let mut g_scores: HashMap<(i32, i32), f64> = HashMap::new();
    let mut came_from: HashMap<(i32, i32), (i32, i32)> = HashMap::new();

    g_scores.insert(start_key, 0.0);
    open.push(ANode {
        col: sgc,
        row: sgr,
        g: 0.0,
        f: steer.heuristic(start_terminus, end_terminus),
    });

    while let Some(current) = open.pop() {
        let key = (current.col, current.row);

        if key == end_key {
            let path = reconstruct_path(
                &came_from,
                grid,
                start_key,
                end_key,
                start_terminus,
                end_terminus,
            );
            return Some(path);
        }

        let current_g = g_scores[&key];
        if current_g < current.g - 1e-9 {
            continue;
        }

        let prev_key = came_from.get(&key).copied();

        for &(dc, dr, step_cost) in &neighbors {
            let nc = current.col + dc;
            let nr = current.row + dr;
            if !grid.in_bounds(nc, nr) {
                continue;
            }
            let nkey = (nc, nr);

            let transition = steer.transition_cost(
                key,
                nkey,
                (dc, dr),
                prev_key,
                step_cost,
                context,
            );

            let tentative_g = current_g + transition;

            if tentative_g < *g_scores.get(&nkey).unwrap_or(&f64::MAX) {
                g_scores.insert(nkey, tentative_g);
                came_from.insert(nkey, key);
                let nh = steer.heuristic(grid.grid_to_world(nc, nr), end_terminus);
                open.push(ANode {
                    col: nc,
                    row: nr,
                    g: tentative_g,
                    f: tentative_g + nh,
                });
            }
        }
    }
    None
}
