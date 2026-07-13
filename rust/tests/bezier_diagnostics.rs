use rust_lib_mycelium::domain::relation_engine::config::{RelationEngineConfig, RoutingMode};
use rust_lib_mycelium::domain::relation_engine::engine::RelationEngine;
use rust_lib_mycelium::domain::relation_engine::geometry::{Point, Rect, polyline_length, segments_intersect};
use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::relation_engine::obstacle_avoidance::compute_waypoints;
use rust_lib_mycelium::domain::relation_engine::routing::prune_collinear_waypoints;
use rust_lib_mycelium::domain::styles::PortSide;
use std::io::Write;

fn node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode { id: id.into(), x, y, width: w, height: h, is_obstacle: true }
}

fn bezier_edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: None,
        to_side: None,
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }
}

fn bezier_edge_ports(id: &str, from: &str, to: &str, fs: PortSide, ts: PortSide) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: Some(fs),
        to_side: Some(ts),
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }
}

// ── Enhanced diagnostic helper functions ──────────────────────────────

/// Normalize an angle to [-180, 180]
fn angle_diff(a: f64, b: f64) -> f64 {
    let d = (b - a) % 360.0;
    if d > 180.0 { d - 360.0 } else if d < -180.0 { d + 360.0 } else { d }
}

/// Port projection analysis: how far does the path extend in the initial
/// direction before deviating > `threshold` degrees from the port normal.
/// Returns (projection_distance_px, initial_deviation_deg, status).
/// Status: "ok" if projection ≥ 15px and initial deviation ≤ 15°,
///         "low" if projection < 15px,
///         "sharp" if initial deviation > 15° (path turns immediately).
/// Analyze end projection (walk backward from the port).
/// How far back does the path maintain alignment with the last segment direction?
fn analyze_end_projection(
    rpts: &[Point],
    cum_len: &[f64],
    seg_angles: &[f64],
    threshold: f64,
) -> (f64, f64, &'static str) {
    let rn = rpts.len();
    if rn < 3 { return (0.0, 0.0, "short"); }
    let total = cum_len.last().copied().unwrap_or(1.0);
    let final_dir = seg_angles[rn - 2]; // direction of the last segment (into port)

    let mut proj_dist = total;
    for i in (1..rn.saturating_sub(1)).rev() {
        let diff = angle_diff(final_dir, seg_angles[i - 1]).abs();
        if diff > threshold {
            proj_dist = total - cum_len[i];
            break;
        }
    }
    let final_dev = 0.0; // last segment is the reference, deviation is 0
    let status = if proj_dist < 15.0 { "low" } else { "ok" };
    (proj_dist, final_dev, status)
}

/// Port projection analysis: how far does the path extend in the initial
/// direction before deviating > `threshold` degrees from the port normal.
/// Returns (projection_distance_px, initial_deviation_deg, status).
/// Status: "ok" if projection ≥ 15px and initial deviation ≤ 15°,
///         "low" if projection < 15px,
///         "sharp" if initial deviation > 15° (path turns immediately).
fn analyze_port_projection(
    rpts: &[Point],
    cum_len: &[f64],
    seg_angles: &[f64],
    port_dir_angle: f64,
    threshold: f64,
) -> (f64, f64, &'static str) {
    let rn = rpts.len();
    if rn < 3 { return (0.0, 0.0, "short"); }
    let total = cum_len.last().copied().unwrap_or(1.0);

    let mut proj_dist = total;
    for i in 1..rn {
        let diff = angle_diff(port_dir_angle, seg_angles[i - 1]).abs();
        if diff > threshold {
            proj_dist = cum_len[i];
            break;
        }
    }
    let initial_dev = angle_diff(port_dir_angle, seg_angles[0]).abs();
    let status = if initial_dev > 15.0 { "sharp" }
    else if proj_dist < 15.0 { "low" }
    else { "ok" };
    (proj_dist, initial_dev, status)
}

/// Middle-section straightness: is the middle 50 % of the path too straight ?
/// Returns (longest_straight_span_px, total_curvature_deg, status).
/// Status: "straight" if total curvature < 15° AND longest straight span > 20 % of path.
fn analyze_mid_straightness(
    seg_angles: &[f64],
    cum_len: &[f64],
) -> (f64, f64, &'static str) {
    let rn = seg_angles.len();
    if rn < 10 { return (0.0, 0.0, "short"); }
    let total = cum_len.last().copied().unwrap_or(1.0);

    // Sum angle change in middle 50 %
    let mid_start = total * 0.25;
    let mid_end = total * 0.75;
    let si = cum_len.iter().position(|c| *c >= mid_start).unwrap_or(1).max(1);
    let ei = cum_len.iter().position(|c| *c >= mid_end).unwrap_or(rn - 1).min(rn - 1);
    if si >= ei { return (0.0, 0.0, "short"); }

    let mut curve = 0.0;
    for i in (si + 1)..=ei {
        curve += angle_diff(seg_angles[i - 1], seg_angles[i]).abs();
    }

    // Longest contiguous span where consecutive angle change < 5°
    let mut cur = 0.0;
    let mut acc = 0.0;
    for i in 1..rn {
        let ch = angle_diff(seg_angles[i - 1], seg_angles[i]).abs();
        if ch < 5.0 {
            acc += cum_len[i] - cum_len[i - 1];
        } else {
            if acc > cur { cur = acc; }
            acc = 0.0;
        }
    }
    if acc > cur { cur = acc; }

    let status = if curve < 15.0 && cur > total * 0.20 { "straight" } else { "ok" };
    (cur, curve, status)
}

/// Classify turns along the path.
/// Returns (total_turns, smooth_count, abrupt_count, max_turn_angle_deg).
/// Abrupt = turn span < 20px with accumulated angle > 30°.
fn classify_turns(seg_angles: &[f64], cum_len: &[f64]) -> (usize, usize, usize, f64) {
    let rn = seg_angles.len();
    if rn < 3 { return (0, 0, 0, 0.0); }
    let mut total = 0usize;
    let mut smooth = 0usize;
    let mut abrupt = 0usize;
    let mut max_a = 0.0f64;
    let mut i = 1;
    while i < rn {
        let ch = angle_diff(seg_angles[i - 1], seg_angles[i]).abs();
        if ch > 15.0 {
            total += 1;
            let start_len = cum_len[i - 1];
            let mut accum = ch;
            i += 1;
            while i < rn {
                let c = angle_diff(seg_angles[i - 1], seg_angles[i]).abs();
                accum += c;
                i += 1;
                if c < 5.0 { break; }
            }
            if accum > max_a { max_a = accum; }
            if i > 2 {
                let span = cum_len[i - 1] - start_len;
                if span < 20.0 && accum > 30.0 { abrupt += 1; } else { smooth += 1; }
            } else {
                smooth += 1;
            }
        } else {
            i += 1;
        }
    }
    (total, smooth, abrupt, max_a)
}

/// Count how many times the path enters each node's body.
/// Returns (source_reentries, target_extra_entries, Vec<obstacle_penetrations>).
/// source_reentries = times the path enters source node after first exit.
/// target_extra = times the path enters target node aside from the final arrival.
fn analyze_node_body_entries(
    rpts: &[Point],
    node_rects: &[(&str, Rect)],
    source_id: &str,
    target_id: &str,
) -> (usize, usize, Vec<(String, usize)>) {
    let mut source_was_in = false;
    let mut source_exited = false;
    let mut source_extra = 0usize;
    let mut target_was_in = false;
    let mut target_arrived = false;
    let mut target_extra = 0usize;

    // For obstacle nodes (not source or target), count all entries except the first
    let mut obst_counts: Vec<(String, usize)> = Vec::new();
    let mut obst_was_in: Vec<(String, bool)> = node_rects.iter()
        .filter(|(id, _)| *id != source_id && *id != target_id)
        .map(|(id, _)| (id.to_string(), false))
        .collect();
    let mut obst_entered: Vec<(String, bool)> = obst_was_in.iter()
        .map(|(id, _)| (id.clone(), false))
        .collect();

    for pt in rpts {
        for (node_id, rect) in node_rects {
            let inside = rect.contains(*pt);
            if *node_id == source_id {
                if inside && !source_was_in && source_exited { source_extra += 1; }
                if inside && !source_was_in { source_exited = false; }
                if !inside && source_was_in { source_exited = true; }
                source_was_in = inside;
            } else if *node_id == target_id {
                if inside && !target_was_in && target_arrived { target_extra += 1; }
                if inside && !target_was_in { target_arrived = true; }
                target_was_in = inside;
            } else {
                // obstacle node
                if let Some(idx) = obst_was_in.iter().position(|(id, _)| id == node_id) {
                    let (_, was_in) = obst_was_in[idx];
                    let (_, entered) = obst_entered[idx];
                    if inside && !was_in {
                        obst_entered[idx].1 = true; // mark that we entered at least once
                    }
                    if inside && !was_in && entered {
                        // re-entering after first exit
                        if let Some(ec) = obst_counts.iter_mut().find(|(id, _)| id == node_id) {
                            ec.1 += 1;
                        }
                    }
                    if !inside && was_in {
                        // exited obstacle
                    }
                    obst_was_in[idx].1 = inside;
                }
            }
        }
    }

    // Collect obstacles that were entered at all
    let ob_pen: Vec<(String, usize)> = obst_counts.into_iter().filter(|(_, c)| *c > 0).collect();

    (source_extra, target_extra, ob_pen)
}

/// Compute discrete curvature at each resampled point.
/// Returns (curvature[], continuity_violations[]).
/// curvature[i] = 1/r in px^-1 at point i (0 for straight).
/// continuity_violations = list of indices where curvature jumps > 50%.
fn compute_curvature(rpts: &[Point]) -> (Vec<f64>, Vec<usize>) {
    let rn = rpts.len();
    let mut curv = vec![0.0f64; rn];
    let mut violations = Vec::new();
    if rn < 3 { return (curv, violations); }

    for i in 1..rn.saturating_sub(1) {
        let dx = rpts[i + 1].x - rpts[i - 1].x;
        let dy = rpts[i + 1].y - rpts[i - 1].y;
        let ddx = rpts[i + 1].x - 2.0 * rpts[i].x + rpts[i - 1].x;
        let ddy = rpts[i + 1].y - 2.0 * rpts[i].y + rpts[i - 1].y;
        let v_sq = dx * dx + dy * dy;
        if v_sq > 1e-6 {
            curv[i] = (dx * ddy - dy * ddx).abs() / (v_sq * v_sq.sqrt());
        }
    }

    for i in 2..rn.saturating_sub(1) {
        if curv[i - 1] > 1e-4 && curv[i] > 1e-4 {
            let ratio = (curv[i] - curv[i - 1]).abs() / curv[i - 1].max(curv[i]);
            if ratio > 0.50 { violations.push(i); }
        }
    }

    (curv, violations)
}

/// Enhanced turn classification with kink detection and node proximity.
/// Returns (turns[], kink_count, max_curvature, curvature_continuity_breaks).
/// Each turn: {type: "kink"|"abrupt"|"smooth", angle, span, peak_curvature, dist_to_nearest_node}
fn classify_turns_detailed(
    seg_angles: &[f64],
    cum_len: &[f64],
    curvatures: &[f64],
    rpts: &[Point],
    node_rects: &[(&str, Rect)],
) -> (usize, usize, usize, f64, Vec<f64>, Vec<(usize, f64)>) {
    let rn = seg_angles.len();
    let mut total = 0usize;
    let mut kinks = 0usize;
    let mut abrupt = 0usize;
    let mut max_curv = 0.0f64;
    let mut curv_problems: Vec<(usize, f64)> = Vec::new();
    let mut all_angles: Vec<f64> = Vec::new();
    let mut j = 1;

    // Track curvature discontinuities
    for k in 2..rn.saturating_sub(1) {
        if curvatures[k - 1] > 1e-4 && curvatures[k] > 1e-4 {
            let ratio = (curvatures[k] - curvatures[k - 1]).abs() / curvatures[k - 1].max(curvatures[k]);
            if ratio > 0.50 {
                curv_problems.push((k, ratio));
            }
        }
        if curvatures[k] > max_curv { max_curv = curvatures[k]; }
    }

    while j < rn {
        let ch = angle_diff(seg_angles[j - 1], seg_angles[j]).abs();
        if ch > 15.0 {
            total += 1;
            let start_j = j;
            let start_len = cum_len[j - 1];
            let mut accum = ch;
            j += 1;
            while j < rn {
                let c = angle_diff(seg_angles[j - 1], seg_angles[j]).abs();
                accum += c;
                j += 1;
                if c < 5.0 { break; }
            }
            all_angles.push(accum);

            let span = cum_len[j - 1] - start_len;
            let point_count = j - start_j;

            if point_count <= 2 && accum > 30.0 {
                kinks += 1;
            } else if span < 20.0 && accum > 30.0 {
                abrupt += 1;
            }
        } else {
            j += 1;
        }
    }

    (total, kinks, abrupt, max_curv, all_angles, curv_problems)
}

fn render_svg(
    filename: &str,
    label: &str,
    nodes: &[InputNode],
    results: &[rust_lib_mycelium::domain::relation_engine::computed::ComputedRelation],
) {
    let colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6"];
    let mut min_x: f64 = f64::MAX;
    let mut min_y: f64 = f64::MAX;
    let mut max_x: f64 = f64::MIN;
    let mut max_y: f64 = f64::MIN;

    for n in nodes {
        min_x = min_x.min(n.x);
        min_y = min_y.min(n.y);
        max_x = max_x.max(n.x + n.width);
        max_y = max_y.max(n.y + n.height);
    }
    for r in results {
        for p in &r.path_points {
            min_x = min_x.min(p.x);
            min_y = min_y.min(p.y);
            max_x = max_x.max(p.x);
            max_y = max_y.max(p.y);
        }
    }

    let pad = 40.0;
    min_x -= pad;
    min_y -= pad;
    max_x += pad;
    max_y += pad;
    let w = max_x - min_x;
    let h = max_y - min_y;

    let mut svg = String::new();
    svg.push_str(&format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"{} {} {} {}\" width=\"{}\" height=\"{}\">",
        min_x, min_y, w, h, w.max(800.0), h.max(400.0),
    ));
    svg.push_str(&format!(
        "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" fill=\"#1a1a2e\"/>",
        min_x, min_y, w, h,
    ));
    svg.push_str(&format!(
        "<rect x=\"{}\" y=\"{}\" width=\"600\" height=\"24\" fill=\"#0a0a1e\" rx=\"4\"/>",
        min_x + 5.0, min_y + 4.0,
    ));
    svg.push_str(&format!(
        "<text x=\"{}\" y=\"{}\" font-size=\"14\" fill=\"#ffffff\">{}</text>",
        min_x + 10.0, min_y + 18.0, label,
    ));
    for n in nodes {
        let cx = n.x + n.width / 2.0;
        let cy = n.y + n.height / 2.0;
        svg.push_str(&format!(
            "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" rx=\"8\" fill=\"#16213e\" stroke=\"#e0e0e0\" stroke-width=\"1.5\"/>",
            n.x, n.y, n.width, n.height,
        ));
        svg.push_str(&format!(
            "<text x=\"{}\" y=\"{}\" font-family=\"sans-serif\" font-size=\"11\" fill=\"#ffffff\" stroke=\"#000000\" stroke-width=\"0.3\" paint-order=\"stroke fill\" text-anchor=\"middle\">{}</text>",
            n.x + n.width / 2.0, n.y + n.height / 2.0 + 4.0, n.id,
        ));
    }

    // Draw baseline (straight line between start and end) as dashed gray
    for r in results {
        let pts = &r.path_points;
        if pts.len() >= 2 {
            svg.push_str(&format!(
                "<line x1=\"{:.2}\" y1=\"{:.2}\" x2=\"{:.2}\" y2=\"{:.2}\" stroke=\"#444\" stroke-width=\"0.5\" stroke-dasharray=\"4,4\"/>",
                pts[0].x, pts[0].y, pts.last().unwrap().x, pts.last().unwrap().y,
            ));
        }
    }

    // Build node rects for waypoint computation
    let node_rects: Vec<(&str, Rect)> = nodes.iter()
        .map(|n| (n.id.as_str(), Rect { x: n.x, y: n.y, width: n.width, height: n.height }))
        .collect();
    let obs_rects: Vec<Rect> = node_rects.iter().map(|(_, r)| *r).collect();

    // Draw waypoints for each relation (computed locally)
    for r in results {
        let pts = &r.path_points;
        let n = pts.len();
        if n < 4 { continue; }
        // A* runs from stub_exit (pts[1]) to stub_entry (pts[n-2])
        let wp_from = pts[1];
        let wp_to = pts[n - 2];
        let astar_wp = compute_waypoints(wp_from, wp_to, &obs_rects, 20.0);
        let pruned_wp = prune_collinear_waypoints(&astar_wp);

        // A* waypoints as yellow crosses
        for wp in &astar_wp {
            svg.push_str(&format!(
                "<path d=\"M {:.2},{:.2} L {:.2},{:.2} M {:.2},{:.2} L {:.2},{:.2}\" \
                 stroke=\"#f1c40f\" stroke-width=\"1.5\" opacity=\"0.6\"/>",
                wp.x - 4.0, wp.y - 4.0, wp.x + 4.0, wp.y + 4.0,
                wp.x + 4.0, wp.y - 4.0, wp.x - 4.0, wp.y + 4.0,
            ));
        }
        // Pruned waypoints as orange diamonds
        for wp in &pruned_wp {
            svg.push_str(&format!(
                "<polygon points=\"{:.2},{:.2} {:.2},{:.2} {:.2},{:.2} {:.2},{:.2}\" \
                 fill=\"none\" stroke=\"#e67e22\" stroke-width=\"1.5\" opacity=\"0.8\"/>",
                wp.x, wp.y - 5.0, wp.x + 5.0, wp.y,
                wp.x, wp.y + 5.0, wp.x - 5.0, wp.y,
            ));
        }
    }

    for (ri, r) in results.iter().enumerate() {
        let color = colors[ri % colors.len()];

        let pts = &r.path_points;

        if pts.len() >= 2 {
            let mut d = format!("M {:.2},{:.2}", pts[0].x, pts[0].y);
            for p in &pts[1..] {
                d.push_str(&format!(" L {:.2},{:.2}", p.x, p.y));
            }
            svg.push_str(&format!(
                "<path d=\"{}\" fill=\"none\" stroke=\"{}\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>",
                d, color,
            ));

            for (i, p) in pts.iter().enumerate() {
                let (r_size, opacity) = if i == 0 || i == pts.len() - 1 {
                    (4.0, 1.0)
                } else if i == 1 || i == pts.len() - 2 {
                    (3.0, 0.8)
                } else {
                    (1.5, 0.4)
                };
                svg.push_str(&format!(
                    "<circle cx=\"{:.2}\" cy=\"{:.2}\" r=\"{}\" fill=\"{}\" opacity=\"{}\"/>",
                    p.x, p.y, r_size, color, opacity,
                ));
            }

            svg.push_str(&format!(
                "<circle cx=\"{:.2}\" cy=\"{:.2}\" r=\"5\" fill=\"none\" stroke=\"{}\" stroke-width=\"1.5\" opacity=\"0.7\"/>",
                pts[0].x, pts[0].y, color,
            ));
            svg.push_str(&format!(
                "<circle cx=\"{:.2}\" cy=\"{:.2}\" r=\"5\" fill=\"none\" stroke=\"{}\" stroke-width=\"1.5\" opacity=\"0.7\"/>",
                pts.last().unwrap().x, pts.last().unwrap().y, color,
            ));
        }

        svg.push_str(&format!(
            "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"10\" fill=\"{}\">{} ({} pts)</text>",
            min_x + 10.0, min_y + 34.0 + ri as f64 * 14.0, color, r.id, r.path_points.len(),
        ));
    }

    // Legend for waypoint markers
    let ly = max_y - 12.0;
    svg.push_str(&format!(
        "<path d=\"M {:.2},{:.2} L {:.2},{:.2} M {:.2},{:.2} L {:.2},{:.2}\" \
         stroke=\"#f1c40f\" stroke-width=\"1.5\" opacity=\"0.6\"/>",
        min_x + 10.0 - 4.0, ly - 4.0, min_x + 10.0 + 4.0, ly + 4.0,
        min_x + 10.0 + 4.0, ly - 4.0, min_x + 10.0 - 4.0, ly + 4.0,
    ));
    svg.push_str(&format!(
        "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"9\" fill=\"#f1c40f\">A* wp</text>",
        min_x + 18.0, ly + 3.0,
    ));
    svg.push_str(&format!(
        "<polygon points=\"{:.2},{:.2} {:.2},{:.2} {:.2},{:.2} {:.2},{:.2}\" \
         fill=\"none\" stroke=\"#e67e22\" stroke-width=\"1.5\" opacity=\"0.8\"/>",
        min_x + 65.0, ly - 5.0, min_x + 70.0, ly,
        min_x + 65.0, ly + 5.0, min_x + 60.0, ly,
    ));
    svg.push_str(&format!(
        "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"9\" fill=\"#e67e22\">pruned wp</text>",
        min_x + 75.0, ly + 3.0,
    ));

    svg.push_str("</svg>");

    let out_dir = std::path::Path::new("target").join("bezier_diag");
    std::fs::create_dir_all(&out_dir).unwrap();

    // Render PNG
    if let Err(e) = render_png(&svg, &out_dir.join(format!("{}.png", filename))) {
        eprintln!("PNG render failed for {}: {}", filename, e);
    }

    // Write enriched JSON for agent consumption
    write_enriched_json(filename, label, nodes, results);
}

fn render_png(svg_data: &str, png_path: &std::path::Path) -> Result<(), Box<dyn std::error::Error>> {
    let mut opt = usvg::Options::default();
    // Load system fonts so <text> elements render as paths
    opt.fontdb_mut().load_system_fonts();
    let tree = usvg::Tree::from_data(svg_data.as_bytes(), &opt)?;
    let size = tree.size();

    let svg_w = size.width();
    let svg_h = size.height();
    let width = svg_w.max(800.0) as u32;
    let height = svg_h.max(400.0) as u32;

    let mut pixmap = tiny_skia::Pixmap::new(width, height)
        .ok_or("failed to create pixmap")?;

    let scale_x = width as f32 / svg_w;
    let scale_y = height as f32 / svg_h;
    let transform = tiny_skia::Transform::from_scale(scale_x, scale_y);

    resvg::render(&tree, transform, &mut pixmap.as_mut());

    pixmap.save_png(png_path)?;
    println!("PNG written: {}", std::fs::canonicalize(png_path)?.display());
    Ok(())
}

/// Walk along the polyline and return points at uniform `step` intervals.
fn resample_path(points: &[Point], step: f64) -> Vec<Point> {
    if points.len() < 2 || step <= 0.0 { return points.to_vec(); }

    let total = polyline_length(points);
    let mut result = Vec::new();
    result.push(points[0]);

    let mut target = step;
    let mut i = 1;
    let mut cum = 0.0;

    while target < total && i < points.len() {
        let seg_len = points[i - 1].distance_to(points[i]);
        let seg_end = cum + seg_len;
        while target <= seg_end + 1e-9 && target < total {
            let t = if seg_len > 0.0 { ((target - cum) / seg_len).clamp(0.0, 1.0) } else { 0.0 };
            result.push(points[i - 1].lerp(points[i], t));
            target += step;
        }
        cum = seg_end;
        i += 1;
    }

    let last = *points.last().unwrap();
    if result.last() != Some(&last) { result.push(last); }
    result
}

fn write_enriched_json(
    filename: &str,
    label: &str,
    nodes: &[InputNode],
    results: &[rust_lib_mycelium::domain::relation_engine::computed::ComputedRelation],
) {
    let out_dir = std::path::Path::new("target").join("bezier_diag");
    let path = out_dir.join(format!("{}.json", filename));
    let mut json = String::new();

    // Build node rects
    let node_rects: Vec<(&str, Rect)> = nodes.iter()
        .map(|n| (n.id.as_str(), Rect { x: n.x, y: n.y, width: n.width, height: n.height }))
        .collect();

    json.push_str("{\n");
    json.push_str(&format!("  \"scenario\": {:?},\n", label));
    json.push_str(&format!("  \"filename\": {:?},\n", filename));
    json.push_str("  \"nodes\": [\n");
    for (i, n) in nodes.iter().enumerate() {
        json.push_str(&format!(
            "    {{\"id\":{:?},\"x\":{:.1},\"y\":{:.1},\"w\":{:.1},\"h\":{:.1},\"is_obstacle\":{}}}",
            n.id, n.x, n.y, n.width, n.height, n.is_obstacle,
        ));
        if i < nodes.len() - 1 { json.push(','); }
        json.push('\n');
    }
    json.push_str("  ],\n");
    json.push_str("  \"relations\": [\n");

    for (ri, r) in results.iter().enumerate() {
        let pts = &r.path_points;
        let n = pts.len();
        if n == 0 { continue; }

        // Resample at uniform 2px intervals for analysis
        let rpts = resample_path(pts, 2.0);
        let rn = rpts.len();

        // ── Summary (using raw points for geometry) ──
        let path_len = polyline_length(pts);
        let straight_dist = if n >= 2 { pts[0].distance_to(pts[n - 1]) } else { 0.0 };
        let ratio = if straight_dist > 1.0 { path_len / straight_dist } else { 1.0 };
        let mut min_x = f64::MAX; let mut max_x = f64::MIN;
        let mut min_y = f64::MAX; let mut max_y = f64::MIN;
        for p in pts { min_x = min_x.min(p.x); max_x = max_x.max(p.x); min_y = min_y.min(p.y); max_y = max_y.max(p.y); }

        // ── Per-point enriched data (on resampled points) ──
        let mut seg_angles = vec![0.0f64; rn];
        let mut cum_len = vec![0.0f64; rn];
        let mut acc = 0.0;
        for i in 0..rn {
            if i < rn - 1 {
                let dx = rpts[i + 1].x - rpts[i].x;
                let dy = rpts[i + 1].y - rpts[i].y;
                seg_angles[i] = dy.atan2(dx).to_degrees();
            } else if rn > 1 {
                seg_angles[i] = seg_angles[rn - 2];
            }
            if i > 0 { acc += rpts[i - 1].distance_to(rpts[i]); }
            cum_len[i] = acc;
        }

        // ── Obstacle segments (on resampled points) ──
        let mut segment_crossings: Vec<(usize, String)> = Vec::new();
        for i in 0..rn.saturating_sub(1) {
            for (node_id, rect) in &node_rects {
                if rect.intersects_segment(rpts[i], rpts[i + 1]) {
                    segment_crossings.push((i, node_id.to_string()));
                }
            }
        }

        // ── Anomalies (on resampled points) ──
        let mut sharp_turns: Vec<(usize, f64)> = Vec::new();
        for i in 1..rn.saturating_sub(1) {
            let d = (seg_angles[i] - seg_angles[i - 1]).abs();
            let change = d.min(360.0 - d);
            if change > 30.0 { sharp_turns.push((i, change)); }
        }

        let mut self_intersections: Vec<(usize, usize)> = Vec::new();
        for i in 0..rn.saturating_sub(2) {
            for j in (i + 2)..rn.saturating_sub(1) {
                if segments_intersect(rpts[i], rpts[i + 1], rpts[j], rpts[j + 1]) {
                    self_intersections.push((i, j));
                }
            }
        }

        let overall_dx = rpts[rn - 1].x - rpts[0].x;
        let overall_dy = rpts[rn - 1].y - rpts[0].y;
        let mut backtracks: Vec<usize> = Vec::new();
        if overall_dx.abs() > 1.0 {
            for i in 1..rn { if (rpts[i].x - rpts[i - 1].x) * overall_dx < -1.0 { backtracks.push(i); } }
        }
        if overall_dy.abs() > 1.0 {
            for i in 1..rn { if (rpts[i].y - rpts[i - 1].y) * overall_dy < -1.0 { backtracks.push(i); } }
        }
        backtracks.sort_unstable();
        backtracks.dedup();

        // ── Write relation object ──
        json.push_str("    {\n");
        json.push_str(&format!("      \"id\": {:?},\n", r.id));
        json.push_str(&format!("      \"path_type\": {:?},\n", format!("{:?}", r.path_type)));
        json.push_str(&format!("      \"num_points\": {},\n", n));
        json.push_str("      \"summary\": {\n");
        json.push_str(&format!("        \"path_length\": {:.3},\n", path_len));
        json.push_str(&format!("        \"straight_distance\": {:.3},\n", straight_dist));
        json.push_str(&format!("        \"length_ratio\": {:.4},\n", ratio));
        json.push_str(&format!("        \"raw_num_points\": {},\n", n));
        json.push_str(&format!("        \"uniform_num_points\": {},\n", rn));
        json.push_str(&format!("        \"uniform_step\": 2.0,\n"));
        json.push_str(&format!("        \"bbox\": {{\"min_x\":{:.1},\"min_y\":{:.1},\"max_x\":{:.1},\"max_y\":{:.1}}},\n", min_x, min_y, max_x, max_y));
        json.push_str(&format!("        \"y_deviation\": {:.1},\n", max_y - min_y));
        json.push_str(&format!("        \"start\": {{\"x\":{:.2},\"y\":{:.2}}},\n", pts[0].x, pts[0].y));
        json.push_str(&format!("        \"end\": {{\"x\":{:.2},\"y\":{:.2}}}\n", pts[n - 1].x, pts[n - 1].y));
        json.push_str("      },\n");

        // Bezier formula parameters
        {
            let bc = RelationEngineConfig::default();
            json.push_str("      \"bezier_params\": {\n");
            json.push_str(&format!("        \"projection_factor\": {:.3},\n", bc.routing.projection_factor));
            json.push_str(&format!("        \"clamp_min\": {:.3},\n", bc.routing.clamp_min));
            json.push_str(&format!("        \"clamp_max\": {:.3},\n", bc.routing.clamp_max));
            json.push_str("        \"nudge_angle_deg\": 15.0\n");
            json.push_str("      },\n");
        }

        // Points array (resampled uniform)
        json.push_str("      \"points\": [\n");
        for i in 0..rn {
            let mut flags = Vec::new();
            if i == 0 { flags.push("start"); }
            if i == rn - 1 { flags.push("end"); }
            let inside_nodes: Vec<&str> = node_rects.iter()
                .filter(|(_, rect)| rect.contains(rpts[i]))
                .map(|(id, _)| *id)
                .collect();
            if !inside_nodes.is_empty() { flags.push("in_node"); }
            let seg_dx = if i > 0 { rpts[i].x - rpts[i - 1].x } else { 0.0 };
            let seg_dy = if i > 0 { rpts[i].y - rpts[i - 1].y } else { 0.0 };
            let seg_len = if i > 0 { rpts[i - 1].distance_to(rpts[i]) } else { 0.0 };
            json.push_str(&format!(
                "        {{\"i\":{},\"x\":{:.2},\"y\":{:.2},\"dx\":{:.2},\"dy\":{:.2},\"sl\":{:.4},\"cl\":{:.3},\"ta\":{:.1},\"in\":[{}],\"fl\":[{}]}}",
                i, rpts[i].x, rpts[i].y, seg_dx, seg_dy, seg_len, cum_len[i], seg_angles[i],
                inside_nodes.iter().map(|id| format!("\"{}\"", id)).collect::<Vec<_>>().join(","),
                flags.iter().map(|f| format!("\"{}\"", f)).collect::<Vec<_>>().join(","),
            ));
            if i < rn - 1 { json.push(','); }
            json.push('\n');
        }
        json.push_str("      ],\n");

        // Obstacle crossings
        json.push_str("      \"segment_crossings\": [\n");
        let mut crossing_entries: Vec<String> = Vec::new();
        let mut seen_entries: Vec<(usize, &str)> = Vec::new();
        for (seg_idx, node_id) in &segment_crossings {
            let key = (*seg_idx, node_id.as_str());
            if !seen_entries.contains(&key) {
                seen_entries.push(key);
                crossing_entries.push(format!(
                    "        {{\"seg\":{},\"node\":{:?},\"from\":{{\"x\":{:.2},\"y\":{:.2}}},\"to\":{{\"x\":{:.2},\"y\":{:.2}}}}}",
                    seg_idx, node_id, rpts[*seg_idx].x, rpts[*seg_idx].y, rpts[*seg_idx + 1].x, rpts[*seg_idx + 1].y,
                ));
            }
        }
        if crossing_entries.is_empty() {
            json.push_str("        []\n");
        } else {
            for (idx, entry) in crossing_entries.iter().enumerate() {
                json.push_str(entry);
                if idx < crossing_entries.len() - 1 { json.push_str(",\n"); } else { json.push('\n'); }
            }
        }
        json.push_str("      ],\n");

        // Anomalies
        json.push_str("      \"anomalies\": {\n");
        json.push_str(&format!(
            "        \"sharp_turns\": [{}],\n",
            sharp_turns.iter().map(|(i, a)| format!("{{\"pt\":{},\"angle_deg\":{:.1}}}", i, a)).collect::<Vec<_>>().join(",")
        ));
        json.push_str(&format!(
            "        \"self_intersections\": [{}],\n",
            self_intersections.iter().map(|(i, j)| format!("{{\"seg_a\":{},\"seg_b\":{}}}", i, j)).collect::<Vec<_>>().join(",")
        ));
        json.push_str(&format!(
            "        \"backtracks\": [{}]\n",
            backtracks.iter().map(|i| format!("{}", i)).collect::<Vec<_>>().join(",")
        ));
        json.push_str("      },\n");
        // ── Enhanced diagnostics ──
        let start_dir = if n >= 2 {
            (pts[1] - pts[0]).direction().to_degrees()
        } else { 0.0 };
        let _end_dir = if n >= 2 {
            (pts[n - 1] - pts[n - 2]).direction().to_degrees()
        } else { 0.0 };

        // Determine source/target node IDs from endpoint containment
        let source_id = node_rects.iter()
            .find(|(_, rect)| rect.contains(pts[0]))
            .map(|(id, _)| *id)
            .unwrap_or("?");
        let target_id = node_rects.iter()
            .find(|(_, rect)| rect.contains(pts[n - 1]))
            .map(|(id, _)| *id)
            .unwrap_or("?");

        let (sp_dist, sp_init, sp_st) = analyze_port_projection(&rpts, &cum_len, &seg_angles, start_dir, 20.0);
        let (ep_dist, _, ep_st) = analyze_end_projection(&rpts, &cum_len, &seg_angles, 20.0);
        let (mid_span, mid_curve, mid_st) = analyze_mid_straightness(&seg_angles, &cum_len);
        let (curvatures, _) = compute_curvature(&rpts);
        let (tt, kinks, ab, max_curv, angles, curv_jumps) = classify_turns_detailed(
            &seg_angles, &cum_len, &curvatures, &rpts, &node_rects,
        );
        let (s_re, t_ex, ob_pen) = analyze_node_body_entries(&rpts, &node_rects, source_id, target_id);

        let ob_json = ob_pen.iter()
            .map(|(id, c)| format!("{{\"node\":{:?},\"penetrations\":{}}}", id, c))
            .collect::<Vec<_>>().join(",");
        let curv_jumps_json = curv_jumps.iter()
            .map(|(i, r)| format!("{{\"pt\":{},\"ratio\":{:.2}}}", i, r))
            .collect::<Vec<_>>().join(",");
        let angles_json = angles.iter()
            .map(|a| format!("{:.1}", a))
            .collect::<Vec<_>>().join(",");

        // ── Waypoints (computed locally from public API) ──
        let obs_rects: Vec<Rect> = node_rects.iter().map(|(_, r)| *r).collect();
        // A* runs from stub_exit (pts[1]) to stub_entry (pts[n-2])
        let wp_from = if n >= 4 { pts[1] } else { pts[0] };
        let wp_to = if n >= 4 { pts[n - 2] } else { pts[n - 1] };
        let astar_wp = compute_waypoints(wp_from, wp_to, &obs_rects, 20.0);
        let pruned_wp = prune_collinear_waypoints(&astar_wp);
        let astar_json: String = astar_wp.iter()
            .map(|p| format!("{{\"x\":{:.1},\"y\":{:.1}}}", p.x, p.y))
            .collect::<Vec<_>>().join(",");
        let pruned_json: String = pruned_wp.iter()
            .map(|p| format!("{{\"x\":{:.1},\"y\":{:.1}}}", p.x, p.y))
            .collect::<Vec<_>>().join(",");

        json.push_str(&format!(
            "      \"diagnostics\": {{
             \"start_projection\": {{\"dist_px\":{:.1},\"initial_dev_deg\":{:.1},\"status\":{:?}}},
             \"end_projection\": {{\"dist_px\":{:.1},\"status\":{:?}}},
             \"mid_section\": {{\"straight_span_px\":{:.1},\"curvature_deg\":{:.1},\"status\":{:?}}},
             \"turn_profile\": {{\"total\":{},\"kinks\":{},\"abrupt\":{},\"smooth\":{},\"max_deg\":{:.1},\"angles\":[{}]}},
             \"curvature\": {{\"max\":{:.6},\"continuity_breaks\":[{}]}},
             \"node_body\": {{\"source_extra_entries\":{},\"target_extra_entries\":{},\"obstacle_penetrations\":[{}]}},
             \"waypoints\": {{\"astar_count\":{},\"pruned_count\":{},\"astar\":[{}],\"pruned\":[{}]}}
             }}
        ", sp_dist, sp_init, sp_st, ep_dist, ep_st, mid_span, mid_curve, mid_st,
           tt, kinks, ab, tt.saturating_sub(kinks + ab), max_curv, angles_json,
           max_curv, curv_jumps_json,
           s_re, t_ex, ob_json,
           astar_wp.len(), pruned_wp.len(), astar_json, pruned_json));

        json.push_str("    }");
        if ri < results.len() - 1 { json.push(','); }
        json.push('\n');
    }
    json.push_str("  ]\n");
    json.push_str("}\n");

    let mut f = std::fs::File::create(&path).unwrap();
    f.write_all(json.as_bytes()).unwrap();
    println!("JSON written: {}", std::fs::canonicalize(&path).unwrap().display());
}

fn print_log(
    label: &str,
    results: &[rust_lib_mycelium::domain::relation_engine::computed::ComputedRelation],
    nodes: &[InputNode],
) {
    println!("\n============================================================");
    println!("SCENARIO: {}", label);
    println!("============================================================");
    // Build node rects for diagnostics
    let node_rects: Vec<(&str, Rect)> = nodes.iter()
        .map(|n| (n.id.as_str(), Rect { x: n.x, y: n.y, width: n.width, height: n.height }))
        .collect();

    for r in results {
        let pts = &r.path_points;
        let n = pts.len();
        println!("  Relation: {}  path_type: {:?}  points: {}", r.id, r.path_type, n);
        let mut min_y = f64::MAX;
        let mut max_y = f64::MIN;
        for p in pts { min_y = min_y.min(p.y); max_y = max_y.max(p.y); }
        println!("  y_range: [{:.1}, {:.1}]  deviation: {:.1}", min_y, max_y, max_y - min_y);

        // Diagnostics on resampled path
        let rpts = resample_path(pts, 4.0);
        let rn = rpts.len();
        let mut seg_angles = vec![0.0f64; rn];
        let mut cum_len = vec![0.0f64; rn];
        let mut acc = 0.0;
        for i in 0..rn {
            if i < rn - 1 {
                let dx = rpts[i + 1].x - rpts[i].x;
                let dy = rpts[i + 1].y - rpts[i].y;
                seg_angles[i] = dy.atan2(dx).to_degrees();
            } else if rn > 1 {
                seg_angles[i] = seg_angles[rn - 2];
            }
            if i > 0 { acc += rpts[i - 1].distance_to(rpts[i]); }
            cum_len[i] = acc;
        }

        let start_dir = if n >= 2 {
            (pts[1] - pts[0]).direction().to_degrees()
        } else { 0.0 };
        let (sp_dist, sp_init, sp_st) = analyze_port_projection(&rpts, &cum_len, &seg_angles, start_dir, 20.0);
        let (ep_dist, _, ep_st) = analyze_end_projection(&rpts, &cum_len, &seg_angles, 20.0);
        let (mid_span, mid_curve, mid_st) = analyze_mid_straightness(&seg_angles, &cum_len);
        let (curvatures, _) = compute_curvature(&rpts);
        let (tt, kinks, ab, max_curv, angles, _) = classify_turns_detailed(
            &seg_angles, &cum_len, &curvatures, &rpts, &node_rects,
        );
        let sm = tt.saturating_sub(kinks + ab);

        let proj_icon = |s: &str| if s == "ok" { "\u{2713}" } else if s == "low" { "\u{26A0} LOW" } else { "\u{26A0} SHARP" };
        let mid_icon = |s: &str| if s == "straight" { "\u{26A0} STRAIGHT" } else { "\u{2713}" };

        println!("  [PROJ]  start: {:.0}px (init_dev={:.0}\u{00b0})  {}", sp_dist, sp_init, proj_icon(sp_st));
        println!("  [PROJ]  end:   {:.0}px  {}", ep_dist, proj_icon(ep_st));
        println!("  [MID]   straight_span={:.0}px  curvature={:.0}\u{00b0}  {}", mid_span, mid_curve, mid_icon(mid_st));

        // Turn summary: kinks + abrupt + smooth
        let mut turn_warnings = Vec::new();
        if kinks > 0 { turn_warnings.push(format!("{} kink(s)", kinks)); }
        if ab > 0 { turn_warnings.push(format!("{} abrupt", ab)); }
        if sm > 0 { turn_warnings.push(format!("{} smooth", sm)); }
        println!("  [TURN]  {} turn(s): {} | curv_peak={:.4}", tt, turn_warnings.join(", "), max_curv);

        // Node body entries
        let source_id = node_rects.iter()
            .find(|(_, rect)| rect.contains(pts[0]))
            .map(|(id, _)| *id)
            .unwrap_or("?");
        let target_id = node_rects.iter()
            .find(|(_, rect)| rect.contains(pts[n - 1]))
            .map(|(id, _)| *id)
            .unwrap_or("?");
        let (s_re, t_ex, ob_pen) = analyze_node_body_entries(&rpts, &node_rects, source_id, target_id);

        let mut node_flags = Vec::new();
        if s_re > 0 { node_flags.push(format!("{} re-entries={}", source_id, s_re)); }
        if t_ex > 0 { node_flags.push(format!("{} extra-entries={}", target_id, t_ex)); }
        for (oid, cnt) in &ob_pen { node_flags.push(format!("{} penetrations={}", oid, cnt)); }
        if node_flags.is_empty() { node_flags.push("none".to_string()); }
        println!("  [NODE]  {}", node_flags.join(", "));

        // Waypoints
        let obs_rects: Vec<Rect> = node_rects.iter().map(|(_, r)| *r).collect();
        let wp_from = if n >= 4 { pts[1] } else { pts[0] };
        let wp_to = if n >= 4 { pts[n - 2] } else { pts[n - 1] };
        let wp_astar = compute_waypoints(wp_from, wp_to, &obs_rects, 20.0);
        let wp_pruned = prune_collinear_waypoints(&wp_astar);
        println!("  [WP]    astar={} pruned={}", wp_astar.len(), wp_pruned.len());

        println!();
    }
}

#[test]
fn diag_horizontal_facing() {
    let label = "Horizontal facing (Right->Left, same height)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 700.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("01_horizontal_facing", label, &nodes, &results);
}

#[test]
fn diag_horizontal_offset() {
    let label = "Horizontal offset (Right->Left, different height)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 700.0, 380.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("02_horizontal_offset", label, &nodes, &results);
}

#[test]
fn diag_top_to_top() {
    let label = "Top-to-Top (same height, both exit upward)";
    let nodes = vec![
        node("a", 100.0, 300.0, 120.0, 80.0),
        node("b", 600.0, 300.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Top, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("03_top_to_top", label, &nodes, &results);
}

#[test]
fn diag_bottom_to_top() {
    let label = "Bottom->Top (close nodes, opposite vertical exits)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 500.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("04_bottom_to_top", label, &nodes, &results);
}

#[test]
fn diag_with_obstacle() {
    let label = "With obstacle in middle";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 400.0, 200.0, 100.0, 80.0),
        node("b", 720.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("05_with_obstacle", label, &nodes, &results);
}

#[test]
fn diag_close_nodes() {
    let label = "Close nodes same height";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 400.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("06_close_nodes", label, &nodes, &results);
}

#[test]
fn diag_far_nodes() {
    let label = "Far nodes same height";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 900.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("07_far_nodes", label, &nodes, &results);
}

#[test]
fn diag_right_to_right_with_obstacle() {
    let label = "Right→Right same-side loop with obstacle blocking direct return";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 280.0, 160.0, 50.0, 120.0),  // moved right +30, up -20 for more clearance
        node("b", 450.0, 200.0, 120.0, 80.0),    // moved right +50 to compensate
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Right)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("08_right_to_right_obstacle", label, &nodes, &results);
}

#[test]
fn diag_left_to_right_facing_away() {
    let label = "Left→Right (both facing outward, path arcs around)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 600.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Right)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("09_left_to_right_away", label, &nodes, &results);
}

#[test]
fn diag_bottom_to_bottom() {
    let label = "Bottom→Bottom (both exit downward, stacked layout)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 600.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Bottom)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("10_bottom_to_bottom", label, &nodes, &results);
}

#[test]
fn diag_top_to_bottom_vertical_obstacle() {
    let label = "Top→Bottom (vertical pass-through) with obstacle blocking midline";
    let nodes = vec![
        node("a", 100.0, 30.0, 120.0, 80.0),
        node("obs", 140.0, 190.0, 140.0, 40.0),
        node("b", 100.0, 340.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("11_top_to_bottom_obstacle", label, &nodes, &results);
}

#[test]
fn diag_corner_top_right_to_bottom_left() {
    let label = "TopRight→BottomLeft corner ports, cross-diagonal";
    let nodes = vec![
        node("a", 100.0, 80.0, 120.0, 80.0),
        node("b", 500.0, 300.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::TopRight, PortSide::BottomLeft)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("12_corner_topright_bottomleft", label, &nodes, &results);
}

#[test]
fn diag_left_to_bottom_cross() {
    let label = "Left→Bottom cross (A left port, B bottom port)";
    let nodes = vec![
        node("a", 100.0, 80.0, 120.0, 80.0),
        node("b", 500.0, 240.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Bottom)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("13_left_to_bottom_cross", label, &nodes, &results);
}

#[test]
fn diag_top_to_left_cross() {
    let label = "Top→Left cross (A top port, B left port)";
    let nodes = vec![
        node("a", 100.0, 80.0, 120.0, 80.0),
        node("b", 500.0, 240.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Top, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("14_top_to_left_cross", label, &nodes, &results);
}

#[test]
fn diag_multiple_obstacles_s_curve() {
    let label = "Multiple obstacles forcing S-curve detour";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs1", 360.0, 150.0, 50.0, 160.0),
        node("obs2", 520.0, 200.0, 50.0, 160.0),
        node("b", 750.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("15_multiple_obstacles_s_curve", label, &nodes, &results);
}

#[test]
fn diag_offset_obstacle_with_ports() {
    let label = "Right→Left with offset obstacle pushed to one side";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 400.0, 110.0, 100.0, 60.0),
        node("b", 700.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("16_offset_obstacle_with_ports", label, &nodes, &results);
}

#[test]
fn diag_tall_obstacle_blocking_vertical() {
    let label = "Tall obstacle blocking full vertical gap between nodes";
    let nodes = vec![
        node("a", 50.0, 20.0, 120.0, 80.0),
        node("obs", 60.0, 190.0, 100.0, 200.0),
        node("b", 50.0, 480.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("17_tall_obstacle_vertical", label, &nodes, &results);
}

#[test]
fn diag_wide_obstacle_side_detour() {
    let label = "Wide obstacle blocking direct path, must go far around";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 380.0, 70.0, 300.0, 260.0),
        node("b", 900.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("18_wide_obstacle_detour", label, &nodes, &results);
}

#[test]
fn diag_left_to_left_with_obstacle() {
    let label = "Left→Left same-side loop with obstacle below blocking detour";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 200.0, 360.0, 300.0, 50.0),
        node("b", 600.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![bezier_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results, &nodes);
    render_svg("19_left_to_left_obstacle", label, &nodes, &results);
}

// ── Randomized scenarios with varying node sizes ──────────────────────

struct RandLayout {
    label: String,
    nodes: Vec<InputNode>,
    edges: Vec<InputEdge>,
}

/// Generate a deterministic "random" layout with non-overlapping nodes.
/// Same seed = same layout.
fn generate_layout(seed: u64) -> RandLayout {
    use rand::RngExt;
    use rand::SeedableRng;
    let mut rng = rand::rngs::SmallRng::seed_from_u64(seed);

    let count = rng.random_range(4..=7);
    let mut nodes = Vec::with_capacity(count);
    let mut node_ids: Vec<String> = Vec::new();

    let max_attempts = 200;
    for i in 0..count {
        let id = format!("n{}", i);
        let w = rng.random_range(40.0..140.0);
        let h = rng.random_range(40.0..100.0);
        let is_obs = i > 0 && i < count - 1 && rng.random_bool(0.35);

        // Rejection sample until no overlap with existing nodes
        let mut placed = false;
        for _ in 0..max_attempts {
            let x = rng.random_range(40.0..900.0);
            let y = rng.random_range(40.0..500.0);
            let candidate = Rect { x, y, width: w, height: h };
            let overlaps = nodes.iter().any(|n: &InputNode| {
                let r = Rect { x: n.x, y: n.y, width: n.width, height: n.height };
                let margin = 20.0;
                candidate.x < r.x + r.width + margin
                    && candidate.x + candidate.width + margin > r.x
                    && candidate.y < r.y + r.height + margin
                    && candidate.y + candidate.height + margin > r.y
            });
            if !overlaps {
                nodes.push(InputNode { id: id.clone(), x, y, width: w, height: h, is_obstacle: is_obs });
                node_ids.push(id.clone());
                placed = true;
                break;
            }
        }
        if !placed {
            let fx = 50.0 + (i as f64 * 130.0);
            let fy = 50.0 + (i as f64 * 80.0) % 400.0;
            nodes.push(InputNode { id: id.clone(), x: fx, y: fy, width: w, height: h, is_obstacle: is_obs });
            node_ids.push(id);
        }
    }

    // Pick two distinct nodes to connect (prefer non-obstacle)
    let valid: Vec<usize> = (0..count).filter(|&i| !nodes[i].is_obstacle).collect();
    let from = if valid.len() >= 2 { valid[0] } else { 0 };
    let to = if valid.len() >= 2 { valid[1] } else { count.saturating_sub(1) };

    // Randomly assign ports or leave auto
    let sides = [PortSide::Top, PortSide::Right, PortSide::Bottom, PortSide::Left];
    let fs = if rng.random_bool(0.6) {
        Some(sides[rng.random_range(0..4)].clone())
    } else { None };
    let ts = if rng.random_bool(0.6) {
        Some(sides[rng.random_range(0..4)].clone())
    } else { None };

    let edge = InputEdge {
        id: "e1".into(),
        from_node_id: node_ids[from].clone(),
        to_node_id: node_ids[to].clone(),
        from_side: fs.clone(),
        to_side: ts.clone(),
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    };

    let label = format!(
        "Random seed={} ({} nodes, {}→{}, ports={:?}→{:?})",
        seed, count, node_ids[from], node_ids[to], fs, ts
    );

    RandLayout { label, nodes, edges: vec![edge] }
}

#[test]
fn diag_random_20() {
    let rl = generate_layout(20);
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
    print_log(&rl.label, &results, &rl.nodes);
    render_svg("20_random_scattered", &rl.label, &rl.nodes, &results);
}

#[test]
fn diag_random_21() {
    let rl = generate_layout(21);
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
    print_log(&rl.label, &results, &rl.nodes);
    render_svg("21_random_scattered", &rl.label, &rl.nodes, &results);
}

#[test]
fn diag_random_22() {
    let rl = generate_layout(22);
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
    print_log(&rl.label, &results, &rl.nodes);
    render_svg("22_random_scattered", &rl.label, &rl.nodes, &results);
}

#[test]
fn diag_random_23() {
    let rl = generate_layout(23);
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
    print_log(&rl.label, &results, &rl.nodes);
    render_svg("23_random_scattered", &rl.label, &rl.nodes, &results);
}

#[test]
fn diag_random_24() {
    let rl = generate_layout(24);
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
    print_log(&rl.label, &results, &rl.nodes);
    render_svg("24_random_scattered", &rl.label, &rl.nodes, &results);
}

#[test]
fn diag_random_25() {
    let rl = generate_layout(25);
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
    print_log(&rl.label, &results, &rl.nodes);
    render_svg("25_random_scattered", &rl.label, &rl.nodes, &results);
}
