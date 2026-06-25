use std::collections::BinaryHeap;

use super::geometry::{Point, Rect};

#[derive(Debug, Clone)]
pub struct VisNode {
    pub point: Point,
    pub obstacle_idx: Option<usize>,
    pub corner_idx: usize,
}

#[derive(Debug, Clone)]
pub struct VisEdge {
    pub from: usize,
    pub to: usize,
    pub cost: f64,
}

#[derive(Debug, Clone)]
pub struct VisibilityGraph {
    pub nodes: Vec<VisNode>,
    pub adj: Vec<Vec<usize>>,
    pub edges: Vec<VisEdge>,
}

impl VisibilityGraph {
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            adj: Vec::new(),
            edges: Vec::new(),
        }
    }

    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }

    pub fn build(
        obstacles: &[Rect],
        start: Point,
        end: Point,
        margin: f64,
    ) -> Self {
        let mut graph = Self::new();

        graph.add_node(start, None, 0);
        graph.add_node(end, None, 1);

        for (oi, obs) in obstacles.iter().enumerate() {
            let expanded = obs.expand(margin);
            let corners = expanded.corners();
            for (ci, &corner) in corners.iter().enumerate() {
                graph.add_node(corner, Some(oi), ci);
            }
        }

        let n = graph.nodes.len();
        graph.adj.resize(n, Vec::new());

        for i in 0..n {
            for j in (i + 1)..n {
                let pi = graph.nodes[i].point;
                let pj = graph.nodes[j].point;

                if is_tangent_visible(pi, pj, i, j, obstacles, margin) {
                    let cost = pi.distance_to(pj);
                    graph.adj[i].push(j);
                    graph.adj[j].push(i);
                    graph.edges.push(VisEdge {
                        from: i,
                        to: j,
                        cost,
                    });
                }
            }
        }

        graph
    }

    fn add_node(&mut self, point: Point, obstacle_idx: Option<usize>, corner_idx: usize) -> usize {
        let idx = self.nodes.len();
        self.nodes.push(VisNode {
            point,
            obstacle_idx,
            corner_idx,
        });
        self.adj.push(Vec::new());
        idx
    }

    pub fn start_idx(&self) -> usize {
        0
    }

    pub fn end_idx(&self) -> usize {
        1
    }
}

/// Tangent-based visibility check following libavoid's approach.
/// Two points are visible if:
/// 1. Neither point is inside any expanded obstacle (unless the point IS a corner of that obstacle)
/// 2. The segment between them doesn't cross any obstacle interior
/// 3. Start/end points (idx 0, 1) are always considered outside for visibility purposes
fn is_tangent_visible(
    p1: Point,
    p2: Point,
    idx1: usize,
    idx2: usize,
    obstacles: &[Rect],
    margin: f64,
) -> bool {
    for obs in obstacles {
        let expanded = obs.expand(margin);

        let p1_in = idx1 > 1 && expanded.contains(p1);
        let p2_in = idx2 > 1 && expanded.contains(p2);

        if p1_in && p2_in {
            return false;
        }

        if p1_in || p2_in {
            let corners = expanded.corners();
            let p1_is_corner = corners.iter().any(|c| c.distance_to(p1) < 0.1);
            let p2_is_corner = corners.iter().any(|c| c.distance_to(p2) < 0.1);

            if (p1_in && !p1_is_corner) || (p2_in && !p2_is_corner) {
                return false;
            }

            if p1_is_corner || p2_is_corner {
                continue;
            }
        }

        if expanded.intersects_segment(p1, p2) {
            return false;
        }
    }
    true
}

/// A* with BinaryHeap priority queue — proper O((V+E) log V) implementation.
pub fn a_star(graph: &VisibilityGraph) -> Option<Vec<Point>> {
    let start = graph.start_idx();
    let end = graph.end_idx();
    let n = graph.node_count();

    if start >= n || end >= n {
        return None;
    }

    #[derive(Clone)]
    struct State {
        cost: f64,
        position: usize,
    }

    impl Eq for State {}
    impl PartialEq for State {
        fn eq(&self, other: &Self) -> bool {
            self.cost == other.cost
        }
    }
    impl PartialOrd for State {
        fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
            Some(self.cmp(other))
        }
    }
    impl Ord for State {
        fn cmp(&self, other: &Self) -> std::cmp::Ordering {
            other.cost.partial_cmp(&self.cost).unwrap_or(std::cmp::Ordering::Equal)
        }
    }

    let mut heap: BinaryHeap<State> = BinaryHeap::new();
    let mut came_from: Vec<Option<usize>> = vec![None; n];
    let mut g_score: Vec<f64> = vec![f64::INFINITY; n];

    g_score[start] = 0.0;
    let h = graph.nodes[start].point.distance_to(graph.nodes[end].point);

    heap.push(State { cost: h, position: start });

    while let Some(State { cost: _, position: current }) = heap.pop() {
        if current == end {
            return Some(reconstruct_path(&came_from, current, &graph.nodes));
        }

        if g_score[current] == f64::INFINITY {
            continue;
        }

        for &neighbor in &graph.adj[current] {
            let edge_cost = graph.nodes[current]
                .point
                .distance_to(graph.nodes[neighbor].point);
            let tentative_g = g_score[current] + edge_cost;

            if tentative_g < g_score[neighbor] {
                came_from[neighbor] = Some(current);
                g_score[neighbor] = tentative_g;
                let f = tentative_g + cost_heuristic(graph, neighbor, end);
                heap.push(State { cost: f, position: neighbor });
            }
        }
    }

    None
}

fn cost_heuristic(graph: &VisibilityGraph, from: usize, to: usize) -> f64 {
    graph.nodes[from].point.distance_to(graph.nodes[to].point)
}

fn reconstruct_path(
    came_from: &[Option<usize>],
    mut current: usize,
    nodes: &[VisNode],
) -> Vec<Point> {
    let mut path = vec![nodes[current].point];
    while let Some(prev) = came_from[current] {
        path.push(nodes[prev].point);
        current = prev;
    }
    path.reverse();
    path
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_visibility_no_obstacles() {
        let start = Point::new(0.0, 0.0);
        let end = Point::new(100.0, 0.0);
        let graph = VisibilityGraph::build(&[], start, end, 45.0);

        assert_eq!(graph.node_count(), 2);
        let path = a_star(&graph);
        assert!(path.is_some());
        let path = path.unwrap();
        assert_eq!(path.len(), 2);
    }

    #[test]
    fn test_visibility_around_obstacle() {
        let start = Point::new(0.0, 50.0);
        let end = Point::new(100.0, 50.0);
        let obstacle = Rect::new(40.0, 40.0, 20.0, 20.0);
        let graph = VisibilityGraph::build(&[obstacle], start, end, 45.0);

        assert!(graph.node_count() > 2);
        let path = a_star(&graph);
        assert!(path.is_some());
        let path = path.unwrap();
        assert!(path.len() > 2);
    }

    #[test]
    fn test_tangent_visibility() {
        let p1 = Point::new(0.0, 0.0);
        let p2 = Point::new(100.0, 100.0);
        let obstacle = Rect::new(40.0, 40.0, 20.0, 20.0);
        assert!(!is_tangent_visible(p1, p2, 2, 3, &[obstacle], 45.0));
    }
}
