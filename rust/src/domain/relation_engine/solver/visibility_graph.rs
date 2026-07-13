use std::collections::{BinaryHeap, HashMap};

use crate::domain::relation_engine::geometry::{Point, Rect};
use super::sweep_visibility;
use crate::domain::relation_engine::state::CanvasState;

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
            for ci in 0..4 {
                let mid = (corners[ci] + corners[(ci + 1) % 4]) * 0.5;
                graph.add_node(mid, Some(oi), 4 + ci);
            }
        }

        let vertices: Vec<Point> = graph.nodes.iter().map(|n| n.point).collect();
        let vis_edges = sweep_visibility::naive_visibility_with_exemptions(
            &vertices, obstacles, margin, &[0, 1],
        );

        let n = graph.nodes.len();
        graph.adj.resize(n, Vec::new());

        for (i, j) in vis_edges {
            let cost = vertices[i].distance_to(vertices[j]);
            graph.adj[i].push(j);
            graph.adj[j].push(i);
            graph.edges.push(VisEdge { from: i, to: j, cost });
        }

        graph
    }

    fn add_node(&mut self, point: Point, obstacle_idx: Option<usize>, corner_idx: usize) -> usize {
        let idx = self.nodes.len();
        self.nodes.push(VisNode { point, obstacle_idx, corner_idx });
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

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RouteCostParams {
    pub angle_penalty: f64,
    pub segment_penalty: f64,
    pub crossing_penalty: f64,
    pub reverse_direction_penalty: f64,
}

impl Default for RouteCostParams {
    fn default() -> Self {
        Self {
            angle_penalty: 0.5,
            segment_penalty: 2.0,
            crossing_penalty: 10.0,
            reverse_direction_penalty: 5.0,
        }
    }
}

pub(crate) fn angle_between(p1: Point, p2: Point, p3: Point) -> f64 {
    let v1 = Point::new(p1.x - p2.x, p1.y - p2.y);
    let v2 = Point::new(p3.x - p2.x, p3.y - p2.y);
    let dot = v1.x * v2.x + v1.y * v2.y;
    let cross = v1.x * v2.y - v1.y * v2.x;
    cross.abs().atan2(dot.abs())
}

pub(crate) fn dim_direction(diff: f64) -> i32 {
    if diff > 1e-6 {
        1
    } else if diff < -1e-6 {
        -1
    } else {
        0
    }
}

pub fn a_star(graph: &VisibilityGraph) -> Option<Vec<Point>> {
    a_star_with_params(graph, &RouteCostParams::default(), None, None, &CanvasState::new())
}

pub fn a_star_with_params(
    graph: &VisibilityGraph,
    cost_params: &RouteCostParams,
    _src_point: Option<&Point>,
    dst_point: Option<&Point>,
    state: &CanvasState,
) -> Option<Vec<Point>> {
    use crate::domain::relation_engine::routing::polyline::PolylineRouting;
    a_star_with_strategy(graph, &PolylineRouting {}, cost_params, dst_point, state)
}

pub fn a_star_with_strategy<S: crate::domain::relation_engine::routing::RoutingStrategy + ?Sized>(
    graph: &VisibilityGraph,
    strategy: &S,
    cost_params: &RouteCostParams,
    dst_point: Option<&Point>,
    state: &CanvasState,
) -> Option<Vec<Point>> {
    let start = graph.start_idx();
    let end = graph.end_idx();
    let n = graph.node_count();

    if start >= n || end >= n {
        return None;
    }

    let actual_dst = dst_point.cloned().unwrap_or(graph.nodes[end].point);

    #[derive(Clone)]
    struct State {
        cost: f64,
        position: usize,
    }

    impl Eq for State {}
    impl PartialEq for State {
        fn eq(&self, other: &Self) -> bool {
            (self.cost - other.cost).abs() < 1e-10
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

    let grid = SpatialGrid::build(state, 100.0);
    let mut heap: BinaryHeap<State> = BinaryHeap::new();
    let mut came_from: Vec<Option<usize>> = vec![None; n];
    let mut g_score: Vec<f64> = vec![f64::INFINITY; n];

    g_score[start] = 0.0;
    let h = strategy.a_star_heuristic(graph.nodes[start].point, actual_dst, None, cost_params);
    heap.push(State { cost: h, position: start });

    while let Some(State { cost: _, position: current }) = heap.pop() {
        if current == end {
            return Some(reconstruct_path(&came_from, current, &graph.nodes));
        }

        if g_score[current] == f64::INFINITY {
            continue;
        }

        let current_point = graph.nodes[current].point;

        for &neighbor in &graph.adj[current] {
            let neighbor_point = graph.nodes[neighbor].point;
            let edge_dist = current_point.distance_to(neighbor_point);

            let prev_point = came_from[current].map(|p| graph.nodes[p].point);

            let edge_cost = strategy.a_star_edge_cost(
                cost_params,
                edge_dist,
                prev_point,
                current_point,
                neighbor_point,
                actual_dst,
                &grid,
            );

            let tentative_g = g_score[current] + edge_cost;

            if strategy.a_star_is_better(
                tentative_g,
                g_score[neighbor],
                current,
                neighbor,
                graph,
                &came_from,
            ) {
                came_from[neighbor] = Some(current);
                g_score[neighbor] = tentative_g;
                let f = tentative_g + strategy.a_star_heuristic(neighbor_point, actual_dst, Some(current_point), cost_params);
                heap.push(State { cost: f, position: neighbor });
            }
        }
    }

    None
}

pub struct SpatialGrid {
    cell_size: f64,
    cells: HashMap<(i32, i32), Vec<(Point, Point)>>,
}

impl SpatialGrid {
    pub fn build(state: &CanvasState, cell_size: f64) -> Self {
        let mut grid = Self {
            cell_size,
            cells: HashMap::new(),
        };

        for other_rel in state.relations.values() {
            let path = &other_rel.path_points;
            if path.len() < 2 {
                continue;
            }
            for window in path.windows(2) {
                let p1 = window[0];
                let p2 = window[1];

                let min_x = p1.x.min(p2.x);
                let max_x = p1.x.max(p2.x);
                let min_y = p1.y.min(p2.y);
                let max_y = p1.y.max(p2.y);

                let cell_x1 = (min_x / cell_size).floor() as i32;
                let cell_x2 = (max_x / cell_size).floor() as i32;
                let cell_y1 = (min_y / cell_size).floor() as i32;
                let cell_y2 = (max_y / cell_size).floor() as i32;

                for cx in cell_x1..=cell_x2 {
                    for cy in cell_y1..=cell_y2 {
                        grid.cells.entry((cx, cy)).or_insert_with(Vec::new).push((p1, p2));
                    }
                }
            }
        }
        grid
    }

    pub fn intersects_segment(&self, p1: Point, p2: Point) -> bool {
        let min_x = p1.x.min(p2.x);
        let max_x = p1.x.max(p2.x);
        let min_y = p1.y.min(p2.y);
        let max_y = p1.y.max(p2.y);

        let cell_x1 = (min_x / self.cell_size).floor() as i32;
        let cell_x2 = (max_x / self.cell_size).floor() as i32;
        let cell_y1 = (min_y / self.cell_size).floor() as i32;
        let cell_y2 = (max_y / self.cell_size).floor() as i32;

        for cx in cell_x1..=cell_x2 {
            for cy in cell_y1..=cell_y2 {
                if let Some(segments) = self.cells.get(&(cx, cy)) {
                    for &(wp1, wp2) in segments {
                        if crate::domain::relation_engine::geometry::segments_intersect(p1, p2, wp1, wp2) {
                            let is_shared_endpoint = p1.distance_to(wp1) < 0.1 
                                || p1.distance_to(wp2) < 0.1
                                || p2.distance_to(wp1) < 0.1
                                || p2.distance_to(wp2) < 0.1;
                            if !is_shared_endpoint {
                                return true;
                            }
                        }
                    }
                }
            }
        }
        false
    }
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
        let end = Point::new(200.0, 50.0);
        let obstacle = Rect::new(60.0, 30.0, 40.0, 40.0);
        let graph = VisibilityGraph::build(&[obstacle], start, end, 10.0);

        assert!(graph.node_count() > 2, "Should have start + end + obstacle corners");
        let path = a_star(&graph);
        assert!(path.is_some(), "Should find a path around the obstacle");
        let path = path.unwrap();
        assert!(path.len() > 2, "Path should go through intermediate points");
    }

    #[test]
    fn test_angle_between_straight() {
        let p1 = Point::new(0.0, 0.0);
        let p2 = Point::new(10.0, 0.0);
        let p3 = Point::new(20.0, 0.0);
        let angle = angle_between(p1, p2, p3);
        assert!(angle < 1e-6);
    }

    #[test]
    fn test_angle_between_right_angle() {
        let p1 = Point::new(0.0, 0.0);
        let p2 = Point::new(10.0, 0.0);
        let p3 = Point::new(10.0, 10.0);
        let angle = angle_between(p1, p2, p3);
        assert!((angle - std::f64::consts::FRAC_PI_2).abs() < 1e-6);
    }

    #[test]
    fn test_a_star_params_no_obstacles() {
        let start = Point::new(0.0, 0.0);
        let end = Point::new(100.0, 0.0);
        let graph = VisibilityGraph::build(&[], start, end, 45.0);

        let params = RouteCostParams {
            angle_penalty: 1.0,
            segment_penalty: 2.0,
            crossing_penalty: 10.0,
            reverse_direction_penalty: 5.0,
        };

        let path = a_star_with_params(&graph, &params, Some(&start), Some(&end), &CanvasState::new());
        assert!(path.is_some());
        let path = path.unwrap();
        assert_eq!(path.len(), 2);
    }
}
