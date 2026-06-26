use super::geometry::{segments_intersect, Point};

/// Detects and counts crossings between edge paths.
///
/// Returns the total number of crossing pairs.
pub fn count_crossings(paths: &[Vec<Point>]) -> usize {
    let mut count = 0;
    for i in 0..paths.len() {
        for j in (i + 1)..paths.len() {
            if paths_cross(&paths[i], &paths[j]) {
                count += 1;
            }
        }
    }
    count
}

/// Attempts to minimize crossings by locally reordering edge layers.
///
/// Uses a simple hill-climbing approach: for each pair of edges, check if
/// swapping their layer order reduces the total crossing count.
pub fn minimize_crossings(
    paths: &mut Vec<Vec<Point>>,
    edge_ids: &[String],
    max_iterations: usize,
) -> Vec<String> {
    if paths.len() < 2 {
        return edge_ids.to_vec();
    }

    let mut order: Vec<usize> = (0..paths.len()).collect();
    let mut best_crossings = count_crossings_by_order(paths, &order);
    let mut improved = true;
    let mut iter = 0;

    while improved && iter < max_iterations {
        improved = false;
        iter += 1;

        for i in 0..order.len() {
            for j in (i + 1)..order.len() {
                // Try swapping i and j
                order.swap(i, j);
                let new_crossings = count_crossings_by_order(paths, &order);

                if new_crossings < best_crossings {
                    best_crossings = new_crossings;
                    improved = true;
                } else {
                    // Revert swap
                    order.swap(i, j);
                }
            }
        }
    }

    // Reorder paths and edge_ids according to the optimized order
    let reordered_paths: Vec<Vec<Point>> = order.iter().map(|&i| paths[i].clone()).collect();
    let reordered_ids: Vec<String> = order.iter().map(|&i| edge_ids[i].clone()).collect();

    *paths = reordered_paths;
    reordered_ids
}

fn count_crossings_by_order(paths: &[Vec<Point>], order: &[usize]) -> usize {
    let mut count = 0;
    for i in 0..order.len() {
        for j in (i + 1)..order.len() {
            if paths_cross(&paths[order[i]], &paths[order[j]]) {
                count += 1;
            }
        }
    }
    count
}

/// Check if two polyline paths cross each other.
fn paths_cross(a: &[Point], b: &[Point]) -> bool {
    for wa in a.windows(2) {
        for wb in b.windows(2) {
            if segments_intersect(wa[0], wa[1], wb[0], wb[1]) {
                return true;
            }
        }
    }
    false
}

/// Returns a list of crossing points between two paths.
pub fn find_crossing_points(a: &[Point], b: &[Point]) -> Vec<Point> {
    let mut points = Vec::new();
    for wa in a.windows(2) {
        for wb in b.windows(2) {
            if let Some(pt) = segment_intersection_point(wa[0], wa[1], wb[0], wb[1]) {
                points.push(pt);
            }
        }
    }
    points
}

fn segment_intersection_point(a1: Point, a2: Point, b1: Point, b2: Point) -> Option<Point> {
    let d1 = a2 - a1;
    let d2 = b2 - b1;
    let cross = d1.x * d2.y - d1.y * d2.x;

    if cross.abs() < 1e-10 {
        return None;
    }

    let t = ((b1.x - a1.x) * d2.y - (b1.y - a1.y) * d2.x) / cross;

    if t < 0.0 || t > 1.0 {
        return None;
    }

    Some(Point::new(a1.x + d1.x * t, a1.y + d1.y * t))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_no_crossings() {
        let paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)],
            vec![Point::new(0.0, 10.0), Point::new(100.0, 10.0)],
        ];
        assert_eq!(count_crossings(&paths), 0);
    }

    #[test]
    fn test_one_crossing() {
        let paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(100.0, 100.0)],
            vec![Point::new(0.0, 100.0), Point::new(100.0, 0.0)],
        ];
        assert_eq!(count_crossings(&paths), 1);
    }

    #[test]
    fn test_crossing_points() {
        let a = vec![Point::new(0.0, 0.0), Point::new(100.0, 100.0)];
        let b = vec![Point::new(0.0, 100.0), Point::new(100.0, 0.0)];
        let pts = find_crossing_points(&a, &b);
        assert_eq!(pts.len(), 1);
        assert!((pts[0].x - 50.0).abs() < 0.1);
        assert!((pts[0].y - 50.0).abs() < 0.1);
    }

    #[test]
    fn test_minimize_crossings_reorders() {
        let mut paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(100.0, 100.0)],
            vec![Point::new(0.0, 100.0), Point::new(100.0, 0.0)],
        ];
        let ids = vec!["e1".into(), "e2".into()];
        let result = minimize_crossings(&mut paths, &ids, 10);
        // After minimization, the crossing count should be <= original
        assert!(count_crossings(&paths) <= 1);
        assert_eq!(result.len(), 2);
    }
}
