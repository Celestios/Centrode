use std::collections::HashMap;

use super::config::BundlingMode;
use super::geometry::{polyline_midpoint, Point};

/// A bundle of edges sharing a common path segment.
#[derive(Debug, Clone)]
pub struct Bundle {
    pub id: String,
    pub edge_ids: Vec<String>,
    /// Shared centerline path for the bundle.
    pub centerline: Vec<Point>,
    /// Points where the bundle branches to individual targets.
    pub split_points: Vec<Point>,
    /// Bundle stroke width (sum of individual widths).
    pub width: f64,
}

/// Result of bundling: maps edge ID to bundle ID and offset from centerline.
#[derive(Debug, Clone)]
pub struct BundlingResult {
    pub bundles: Vec<Bundle>,
    /// edge_id -> (bundle_id, offset_from_centerline)
    pub edge_assignments: HashMap<String, (String, f64)>,
}

/// Bundle edges according to the given mode and threshold.
pub fn bundle_edges(
    edge_ids: &[String],
    paths: &[Vec<Point>],
    from_node_ids: &[String],
    to_node_ids: &[String],
    mode: &BundlingMode,
    threshold: f64,
    base_width: f64,
) -> BundlingResult {
    match mode {
        BundlingMode::None => BundlingResult {
            bundles: Vec::new(),
            edge_assignments: HashMap::new(),
        },
        BundlingMode::SharedEndpoint => bundle_shared_endpoint(
            edge_ids,
            paths,
            from_node_ids,
            to_node_ids,
            base_width,
        ),
        BundlingMode::Proximity => {
            bundle_proximity(edge_ids, paths, threshold, base_width)
        }
    }
}

fn bundle_shared_endpoint(
    edge_ids: &[String],
    paths: &[Vec<Point>],
    from_node_ids: &[String],
    to_node_ids: &[String],
    base_width: f64,
) -> BundlingResult {
    let mut source_groups: HashMap<&str, Vec<usize>> = HashMap::new();
    let mut target_groups: HashMap<&str, Vec<usize>> = HashMap::new();

    for (i, from_id) in from_node_ids.iter().enumerate() {
        source_groups.entry(from_id.as_str()).or_default().push(i);
    }
    for (i, to_id) in to_node_ids.iter().enumerate() {
        target_groups.entry(to_id.as_str()).or_default().push(i);
    }

    let mut bundles = Vec::new();
    let mut edge_assignments: HashMap<String, (String, f64)> = HashMap::new();
    let mut bundle_counter = 0;

    // Bundle by shared source
    for (_node_id, group) in &source_groups {
        if group.len() < 2 {
            continue;
        }
        let bundle_id = format!("bundle_src_{}", bundle_counter);
        bundle_counter += 1;

        let edge_ids_in_bundle: Vec<String> = group.iter().map(|&i| edge_ids[i].clone()).collect();
        let paths_in_bundle: Vec<&[Point]> = group.iter().map(|&i| paths[i].as_slice()).collect();

        let centerline = compute_centerline(&paths_in_bundle);
        let split_points = compute_split_points(&paths_in_bundle, &centerline);
        let width = base_width * edge_ids_in_bundle.len() as f64 * 0.7;

        // Compute offsets from centerline for each edge
        for (_local_i, &edge_i) in group.iter().enumerate() {
            let offset = compute_offset_from_centerline(&paths[edge_i], &centerline);
            edge_assignments.insert(
                edge_ids[edge_i].clone(),
                (bundle_id.clone(), offset),
            );
        }

        bundles.push(Bundle {
            id: bundle_id,
            edge_ids: edge_ids_in_bundle,
            centerline,
            split_points,
            width,
        });
    }

    // Bundle by shared target (only edges not already bundled)
    for (_node_id, group) in &target_groups {
        let unbundled: Vec<usize> = group
            .iter()
            .filter(|&&i| !edge_assignments.contains_key(&edge_ids[i]))
            .copied()
            .collect();

        if unbundled.len() < 2 {
            continue;
        }

        let bundle_id = format!("bundle_tgt_{}", bundle_counter);
        bundle_counter += 1;

        let edge_ids_in_bundle: Vec<String> =
            unbundled.iter().map(|&i| edge_ids[i].clone()).collect();
        let paths_in_bundle: Vec<&[Point]> =
            unbundled.iter().map(|&i| paths[i].as_slice()).collect();

        let centerline = compute_centerline(&paths_in_bundle);
        let split_points = compute_split_points(&paths_in_bundle, &centerline);
        let width = base_width * edge_ids_in_bundle.len() as f64 * 0.7;

        for &edge_i in &unbundled {
            let offset = compute_offset_from_centerline(&paths[edge_i], &centerline);
            edge_assignments.insert(
                edge_ids[edge_i].clone(),
                (bundle_id.clone(), offset),
            );
        }

        bundles.push(Bundle {
            id: bundle_id,
            edge_ids: edge_ids_in_bundle,
            centerline,
            split_points,
            width,
        });
    }

    BundlingResult {
        bundles,
        edge_assignments,
    }
}

fn bundle_proximity(
    edge_ids: &[String],
    paths: &[Vec<Point>],
    threshold: f64,
    base_width: f64,
) -> BundlingResult {
    if paths.is_empty() {
        return BundlingResult {
            bundles: Vec::new(),
            edge_assignments: HashMap::new(),
        };
    }

    // Compute midpoints for each edge
    let midpoints: Vec<Point> = paths
        .iter()
        .map(|p| polyline_midpoint(p))
        .collect();

    // Simple agglomerative clustering by midpoint distance
    let mut clusters: Vec<Vec<usize>> = (0..paths.len()).map(|i| vec![i]).collect();
    let mut cluster_mids: Vec<Point> = midpoints.clone();

    let mut merged = true;
    while merged {
        merged = false;
        let mut best_dist = f64::MAX;
        let mut best_i = 0;
        let mut best_j = 1;

        for i in 0..clusters.len() {
            for j in (i + 1)..clusters.len() {
                let dist = cluster_mids[i].distance_to(cluster_mids[j]);
                if dist < best_dist {
                    best_dist = dist;
                    best_i = i;
                    best_j = j;
                }
            }
        }

        if best_dist < threshold && clusters.len() > 1 {
            // Merge j into i
            let merged_cluster = std::mem::take(&mut clusters[best_j]);
            clusters[best_i].extend(merged_cluster);
            // Recompute midpoint as average
            let avg = cluster_mids[best_i].lerp(cluster_mids[best_j], 0.5);
            cluster_mids[best_i] = avg;
            clusters.remove(best_j);
            cluster_mids.remove(best_j);
            merged = true;
        }
    }

    let mut bundles = Vec::new();
    let mut edge_assignments: HashMap<String, (String, f64)> = HashMap::new();
    let mut bundle_counter = 0;

    for cluster in &clusters {
        if cluster.len() < 2 {
            continue;
        }

        let bundle_id = format!("bundle_prox_{}", bundle_counter);
        bundle_counter += 1;

        let edge_ids_in_bundle: Vec<String> =
            cluster.iter().map(|&i| edge_ids[i].clone()).collect();
        let paths_in_bundle: Vec<&[Point]> =
            cluster.iter().map(|&i| paths[i].as_slice()).collect();

        let centerline = compute_centerline(&paths_in_bundle);
        let split_points = compute_split_points(&paths_in_bundle, &centerline);
        let width = base_width * edge_ids_in_bundle.len() as f64 * 0.7;

        for &edge_i in cluster {
            let offset = compute_offset_from_centerline(&paths[edge_i], &centerline);
            edge_assignments.insert(
                edge_ids[edge_i].clone(),
                (bundle_id.clone(), offset),
            );
        }

        bundles.push(Bundle {
            id: bundle_id,
            edge_ids: edge_ids_in_bundle,
            centerline,
            split_points,
            width,
        });
    }

    BundlingResult {
        bundles,
        edge_assignments,
    }
}

/// Compute the centerline of a bundle by averaging corresponding path points.
fn compute_centerline(paths: &[&[Point]]) -> Vec<Point> {
    if paths.is_empty() {
        return Vec::new();
    }

    // Resample all paths to the same number of points (use the longest)
    let max_len = paths.iter().map(|p| p.len()).max().unwrap_or(0);
    if max_len == 0 {
        return Vec::new();
    }

    let n = max_len.max(3);
    let mut centerline = Vec::with_capacity(n);

    for i in 0..n {
        let t = i as f64 / (n - 1) as f64;
        let mut avg_x = 0.0;
        let mut avg_y = 0.0;
        let mut count = 0;

        for path in paths {
            let idx = (t * (path.len() - 1) as f64).round() as usize;
            let idx = idx.min(path.len() - 1);
            avg_x += path[idx].x;
            avg_y += path[idx].y;
            count += 1;
        }

        centerline.push(Point::new(avg_x / count as f64, avg_y / count as f64));
    }

    centerline
}

/// Compute split points where the bundle branches to individual targets.
fn compute_split_points(paths: &[&[Point]], centerline: &[Point]) -> Vec<Point> {
    if paths.is_empty() || centerline.is_empty() {
        return Vec::new();
    }

    // Split point is where individual paths diverge from the centerline
    // Use the last point where path is close to centerline
    let mut split_points = Vec::new();

    for path in paths {
        let mut last_close_idx = 0;
        for (i, cp) in centerline.iter().enumerate() {
            let pi = (i as f64 / (centerline.len() - 1) as f64 * (path.len() - 1) as f64)
                .round() as usize;
            let pi = pi.min(path.len() - 1);
            if path[pi].distance_to(*cp) < 20.0 {
                last_close_idx = i;
            }
        }
        if last_close_idx < centerline.len() {
            split_points.push(centerline[last_close_idx]);
        }
    }

    split_points
}

/// Compute the average offset of a path from the centerline.
fn compute_offset_from_centerline(path: &[Point], centerline: &[Point]) -> f64 {
    if path.is_empty() || centerline.is_empty() {
        return 0.0;
    }

    let mut total_offset = 0.0;
    let mut count = 0;

    for (i, p) in path.iter().enumerate() {
        let ci = (i as f64 / (path.len() - 1).max(1) as f64 * (centerline.len() - 1) as f64)
            .round() as usize;
        let ci = ci.min(centerline.len() - 1);
        let diff = *p - centerline[ci];
        total_offset += diff.length();
        count += 1;
    }

    if count > 0 {
        total_offset / count as f64
    } else {
        0.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_no_bundling() {
        let edge_ids = vec!["e1".into()];
        let paths = vec![vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)]];
        let from = vec!["n1".into()];
        let to = vec!["n2".into()];

        let result = bundle_edges(
            &edge_ids,
            &paths,
            &from,
            &to,
            &BundlingMode::None,
            0.0,
            2.0,
        );
        assert!(result.bundles.is_empty());
        assert!(result.edge_assignments.is_empty());
    }

    #[test]
    fn test_shared_endpoint_bundle() {
        let edge_ids = vec!["e1".into(), "e2".into(), "e3".into()];
        let paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)],
            vec![Point::new(0.0, 0.0), Point::new(100.0, 10.0)],
            vec![Point::new(0.0, 0.0), Point::new(100.0, -10.0)],
        ];
        let from = vec!["n1".into(), "n1".into(), "n1".into()];
        let to = vec!["n2".into(), "n3".into(), "n4".into()];

        let result = bundle_edges(
            &edge_ids,
            &paths,
            &from,
            &to,
            &BundlingMode::SharedEndpoint,
            0.0,
            2.0,
        );

        assert_eq!(result.bundles.len(), 1);
        assert_eq!(result.bundles[0].edge_ids.len(), 3);
        assert!(result.edge_assignments.contains_key("e1"));
        assert!(result.edge_assignments.contains_key("e2"));
        assert!(result.edge_assignments.contains_key("e3"));
    }

    #[test]
    fn test_proximity_bundle() {
        let edge_ids = vec!["e1".into(), "e2".into(), "e3".into()];
        let paths = vec![
            vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)],
            vec![Point::new(0.0, 2.0), Point::new(100.0, 2.0)],
            vec![Point::new(0.0, 200.0), Point::new(100.0, 200.0)],
        ];
        let from = vec!["n1".into(), "n2".into(), "n3".into()];
        let to = vec!["n4".into(), "n5".into(), "n6".into()];

        let result = bundle_edges(
            &edge_ids,
            &paths,
            &from,
            &to,
            &BundlingMode::Proximity,
            50.0,
            2.0,
        );

        // e1 and e2 should be bundled (close midpoints), e3 separate
        assert!(!result.bundles.is_empty());
    }
}
