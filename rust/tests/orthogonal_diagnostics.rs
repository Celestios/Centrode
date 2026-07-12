use rust_lib_mycelium::domain::relation_engine::config::{RelationEngineConfig, RoutingMode};
use rust_lib_mycelium::domain::relation_engine::engine::RelationEngine;
use rust_lib_mycelium::domain::relation_engine::geometry::{Rect, polyline_length, segments_intersect};
use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::styles::PortSide;
use rand::RngExt;
use rand::SeedableRng;
use std::io::Write;

fn node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode { id: id.into(), x, y, width: w, height: h, is_obstacle: true }
}

fn ortho_edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: None,
        to_side: None,
        routing_mode: Some(RoutingMode::Orthogonal),
        bundling_mode: None,
        style: None,
    }
}

fn ortho_edge_ports(id: &str, from: &str, to: &str, fs: PortSide, ts: PortSide) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: Some(fs),
        to_side: Some(ts),
        routing_mode: Some(RoutingMode::Orthogonal),
        bundling_mode: None,
        style: None,
    }
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
        "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"14\" fill=\"#aaaaaa\">{}</text>",
        min_x + 10.0, min_y + 18.0, label,
    ));

    for n in nodes {
        svg.push_str(&format!(
            "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" rx=\"8\" fill=\"#16213e\" stroke=\"#0f3460\" stroke-width=\"1.5\"/>",
            n.x, n.y, n.width, n.height,
        ));
        svg.push_str(&format!(
            "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"11\" fill=\"#e0e0e0\" text-anchor=\"middle\">{}</text>",
            n.x + n.width / 2.0, n.y + n.height / 2.0 + 4.0, n.id,
        ));
    }

    for r in results {
        let pts = &r.path_points;
        if pts.len() >= 2 {
            svg.push_str(&format!(
                "<line x1=\"{:.2}\" y1=\"{:.2}\" x2=\"{:.2}\" y2=\"{:.2}\" stroke=\"#444\" stroke-width=\"0.5\" stroke-dasharray=\"4,4\"/>",
                pts[0].x, pts[0].y, pts.last().unwrap().x, pts.last().unwrap().y,
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

    svg.push_str("</svg>");

    let out_dir = std::path::Path::new("target").join("ortho_diag");
    std::fs::create_dir_all(&out_dir).unwrap();

    if let Err(e) = render_png(&svg, &out_dir.join(format!("{}.png", filename))) {
        eprintln!("PNG render failed for {}: {}", filename, e);
    }

    write_enriched_json(filename, label, nodes, results);
}

fn render_png(svg_data: &str, png_path: &std::path::Path) -> Result<(), Box<dyn std::error::Error>> {
    let opt = usvg::Options::default();
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

fn write_enriched_json(
    filename: &str,
    label: &str,
    nodes: &[InputNode],
    results: &[rust_lib_mycelium::domain::relation_engine::computed::ComputedRelation],
) {
    let out_dir = std::path::Path::new("target").join("ortho_diag");
    let path = out_dir.join(format!("{}.json", filename));
    let mut json = String::new();

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

        let path_len = polyline_length(pts);
        let straight_dist = if n >= 2 { pts[0].distance_to(pts[n - 1]) } else { 0.0 };
        let ratio = if straight_dist > 1.0 { path_len / straight_dist } else { 1.0 };
        let mut min_x = f64::MAX; let mut max_x = f64::MIN;
        let mut min_y = f64::MAX; let mut max_y = f64::MIN;
        for p in pts { min_x = min_x.min(p.x); max_x = max_x.max(p.x); min_y = min_y.min(p.y); max_y = max_y.max(p.y); }

        let mut seg_angles = vec![0.0f64; n];
        let mut cum_len = vec![0.0f64; n];
        let mut acc = 0.0;
        for i in 0..n {
            if i < n - 1 {
                let dx = pts[i + 1].x - pts[i].x;
                let dy = pts[i + 1].y - pts[i].y;
                seg_angles[i] = dy.atan2(dx).to_degrees();
            } else if n > 1 {
                seg_angles[i] = seg_angles[n - 2];
            }
            if i > 0 { acc += pts[i - 1].distance_to(pts[i]); }
            cum_len[i] = acc;
        }

        let mut segment_crossings: Vec<(usize, String)> = Vec::new();
        for i in 0..n.saturating_sub(1) {
            for (node_id, rect) in &node_rects {
                if rect.intersects_segment(pts[i], pts[i + 1]) {
                    segment_crossings.push((i, node_id.to_string()));
                }
            }
        }

        let mut sharp_turns: Vec<(usize, f64)> = Vec::new();
        for i in 1..n.saturating_sub(1) {
            let d = (seg_angles[i] - seg_angles[i - 1]).abs();
            let change = d.min(360.0 - d);
            if change > 10.0 { sharp_turns.push((i, change)); }
        }

        let mut self_intersections: Vec<(usize, usize)> = Vec::new();
        for i in 0..n.saturating_sub(2) {
            for j in (i + 2)..n.saturating_sub(1) {
                if segments_intersect(pts[i], pts[i + 1], pts[j], pts[j + 1]) {
                    self_intersections.push((i, j));
                }
            }
        }

        let overall_dx = pts[n - 1].x - pts[0].x;
        let overall_dy = pts[n - 1].y - pts[0].y;
        let mut backtracks: Vec<usize> = Vec::new();
        if overall_dx.abs() > 1.0 {
            for i in 1..n { if (pts[i].x - pts[i - 1].x) * overall_dx < -1.0 { backtracks.push(i); } }
        }
        if overall_dy.abs() > 1.0 {
            for i in 1..n { if (pts[i].y - pts[i - 1].y) * overall_dy < -1.0 { backtracks.push(i); } }
        }
        backtracks.sort_unstable();
        backtracks.dedup();

        json.push_str("    {\n");
        json.push_str(&format!("      \"id\": {:?},\n", r.id));
        json.push_str(&format!("      \"path_type\": {:?},\n", format!("{:?}", r.path_type)));
        json.push_str(&format!("      \"num_points\": {},\n", n));
        json.push_str("      \"summary\": {\n");
        json.push_str(&format!("        \"path_length\": {:.3},\n", path_len));
        json.push_str(&format!("        \"straight_distance\": {:.3},\n", straight_dist));
        json.push_str(&format!("        \"length_ratio\": {:.4},\n", ratio));
        json.push_str(&format!("        \"bbox\": {{\"min_x\":{:.1},\"min_y\":{:.1},\"max_x\":{:.1},\"max_y\":{:.1}}},\n", min_x, min_y, max_x, max_y));
        json.push_str(&format!("        \"y_deviation\": {:.1},\n", max_y - min_y));
        json.push_str(&format!("        \"start\": {{\"x\":{:.2},\"y\":{:.2}}},\n", pts[0].x, pts[0].y));
        json.push_str(&format!("        \"end\": {{\"x\":{:.2},\"y\":{:.2}}}\n", pts[n - 1].x, pts[n - 1].y));
        json.push_str("      },\n");

        json.push_str("      \"points\": [\n");
        for i in 0..n {
            let mut flags = Vec::new();
            if i == 0 { flags.push("start"); }
            if i == n - 1 { flags.push("end"); }
            if i < 2 || i >= n - 2 { flags.push("stub"); }
            let inside_nodes: Vec<&str> = node_rects.iter()
                .filter(|(_, rect)| rect.contains(pts[i]))
                .map(|(id, _)| *id)
                .collect();
            if !inside_nodes.is_empty() { flags.push("in_node"); }
            let seg_dx = if i > 0 { pts[i].x - pts[i - 1].x } else { 0.0 };
            let seg_dy = if i > 0 { pts[i].y - pts[i - 1].y } else { 0.0 };
            let seg_len = if i > 0 { pts[i - 1].distance_to(pts[i]) } else { 0.0 };
            json.push_str(&format!(
                "        {{\"i\":{},\"x\":{:.2},\"y\":{:.2},\"dx\":{:.2},\"dy\":{:.2},\"sl\":{:.4},\"cl\":{:.3},\"ta\":{:.1},\"in\":[{}],\"fl\":[{}]}}",
                i, pts[i].x, pts[i].y, seg_dx, seg_dy, seg_len, cum_len[i], seg_angles[i],
                inside_nodes.iter().map(|id| format!("\"{}\"", id)).collect::<Vec<_>>().join(","),
                flags.iter().map(|f| format!("\"{}\"", f)).collect::<Vec<_>>().join(","),
            ));
            if i < n - 1 { json.push(','); }
            json.push('\n');
        }
        json.push_str("      ],\n");

        json.push_str("      \"segment_crossings\": [\n");
        let mut crossing_entries: Vec<String> = Vec::new();
        let mut seen_entries: Vec<(usize, &str)> = Vec::new();
        for (seg_idx, node_id) in &segment_crossings {
            let key = (*seg_idx, node_id.as_str());
            if !seen_entries.contains(&key) {
                seen_entries.push(key);
                crossing_entries.push(format!(
                    "        {{\"seg\":{},\"node\":{:?},\"from\":{{\"x\":{:.2},\"y\":{:.2}}},\"to\":{{\"x\":{:.2},\"y\":{:.2}}}}}",
                    seg_idx, node_id, pts[*seg_idx].x, pts[*seg_idx].y, pts[*seg_idx + 1].x, pts[*seg_idx + 1].y,
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
        json.push_str("      }\n");
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
) {
    println!("\n============================================================");
    println!("SCENARIO: {}", label);
    println!("============================================================");
    for r in results {
        let pts = &r.path_points;
        println!("  Relation: {}  path_type: {:?}  points: {}", r.id, r.path_type, pts.len());
        let mut min_y = f64::MAX;
        let mut max_y = f64::MIN;
        for p in pts { min_y = min_y.min(p.y); max_y = max_y.max(p.y); }
        println!("  y_range: [{:.1}, {:.1}]  deviation: {:.1}", min_y, max_y, max_y - min_y);
        for (i, p) in pts.iter().enumerate() {
            println!("    [{:3}] ({:8.2}, {:8.2})", i, p.x, p.y);
        }
    }
}

// ── Baseline: auto-resolve ──

#[test]
fn ortho_horizontal_facing() {
    let label = "Horizontal facing (Right->Left, same height)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 500.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("01_horizontal_facing", label, &nodes, &results);
}

#[test]
fn ortho_horizontal_offset() {
    let label = "Horizontal offset (Right->Left, different height)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 500.0, 350.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("02_horizontal_offset", label, &nodes, &results);
}

#[test]
fn ortho_vertical_stacked() {
    let label = "Vertical stacked (Bottom->Top, same x)";
    let nodes = vec![
        node("a", 100.0, 50.0, 120.0, 80.0),
        node("b", 100.0, 250.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("03_vertical_stacked", label, &nodes, &results);
}

#[test]
fn ortho_top_to_top() {
    let label = "Top→Top (both exit upward)";
    let nodes = vec![
        node("a", 100.0, 300.0, 120.0, 80.0),
        node("b", 400.0, 300.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Top, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("04_top_to_top", label, &nodes, &results);
}

#[test]
fn ortho_bottom_to_bottom() {
    let label = "Bottom→Bottom (both exit downward)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 400.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Bottom)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("05_bottom_to_bottom", label, &nodes, &results);
}

#[test]
fn ortho_left_to_right_facing_away() {
    let label = "Left→Right (both facing outward)";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 400.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Right)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("06_left_to_right_away", label, &nodes, &results);
}

// ── Same-side loops ──

#[test]
fn ortho_right_to_right_loop() {
    let label = "Right→Right same-side loop";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 400.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Right)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("07_right_to_right_loop", label, &nodes, &results);
}

#[test]
fn ortho_left_to_left_loop() {
    let label = "Left→Left same-side loop";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 400.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("08_left_to_left_loop", label, &nodes, &results);
}

// ── Cross ports ──

#[test]
fn ortho_top_to_bottom_facing() {
    let label = "Top→Bottom facing (through body)";
    let nodes = vec![
        node("a", 100.0, 100.0, 120.0, 80.0),
        node("b", 100.0, 300.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Top, PortSide::Bottom)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("09_top_to_bottom_facing", label, &nodes, &results);
}

#[test]
fn ortho_left_to_bottom_cross() {
    let label = "Left→Bottom cross port";
    let nodes = vec![
        node("a", 100.0, 100.0, 120.0, 80.0),
        node("b", 350.0, 240.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Bottom)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("10_left_to_bottom_cross", label, &nodes, &results);
}

#[test]
fn ortho_top_to_left_cross() {
    let label = "Top→Left cross port";
    let nodes = vec![
        node("a", 100.0, 100.0, 120.0, 80.0),
        node("b", 350.0, 240.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Top, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("11_top_to_left_cross", label, &nodes, &results);
}

#[test]
fn ortho_right_to_top_cross() {
    let label = "Right→Top cross port";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 300.0, 100.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("12_right_to_top_cross", label, &nodes, &results);
}

// ── Obstacles ──

#[test]
fn ortho_obstacle_center() {
    let label = "Obstacle blocking direct horizontal path";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 350.0, 180.0, 100.0, 120.0),
        node("b", 600.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("13_obstacle_center", label, &nodes, &results);
}

#[test]
fn ortho_obstacle_offset_high() {
    let label = "Obstacle offset high, only blocks upper route";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 350.0, 110.0, 100.0, 60.0),
        node("b", 600.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("14_obstacle_offset_high", label, &nodes, &results);
}

#[test]
fn ortho_obstacle_close_gap() {
    let label = "Obstacle close to start node, tight corridor";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 240.0, 180.0, 60.0, 120.0),
        node("b", 400.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("15_obstacle_close_gap", label, &nodes, &results);
}

#[test]
fn ortho_multiple_obstacles_s_curve() {
    let label = "Two obstacles forcing S-curve";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs1", 300.0, 150.0, 50.0, 180.0),
        node("obs2", 450.0, 200.0, 50.0, 180.0),
        node("b", 650.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("16_multiple_obstacles", label, &nodes, &results);
}

#[test]
fn ortho_wide_obstacle_detour() {
    let label = "Wide obstacle blocking direct path";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 280.0, 80.0, 300.0, 240.0),
        node("b", 700.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("17_wide_obstacle_detour", label, &nodes, &results);
}

#[test]
fn ortho_tall_obstacle_vertical() {
    let label = "Tall obstacle blocking vertical corridor";
    let nodes = vec![
        node("a", 50.0, 20.0, 120.0, 80.0),
        node("obs", 60.0, 190.0, 100.0, 200.0),
        node("b", 50.0, 480.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Bottom, PortSide::Top)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("18_tall_obstacle_vertical", label, &nodes, &results);
}

#[test]
fn ortho_right_to_right_obstacle() {
    let label = "Right→Right same-side loop with obstacle blocking return";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 280.0, 150.0, 50.0, 160.0),
        node("b", 450.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Right, PortSide::Right)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("19_right_to_right_obstacle", label, &nodes, &results);
}

#[test]
fn ortho_left_to_left_obstacle() {
    let label = "Left→Left same-side loop with obstacle below";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("obs", 200.0, 360.0, 300.0, 50.0),
        node("b", 600.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::Left, PortSide::Left)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("20_left_to_left_obstacle", label, &nodes, &results);
}

// ── Corner ports ──

#[test]
fn ortho_corner_top_left_to_bottom_right() {
    let label = "TopLeft→BottomRight corner ports, diagonal";
    let nodes = vec![
        node("a", 100.0, 100.0, 120.0, 80.0),
        node("b", 350.0, 250.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::TopLeft, PortSide::BottomRight)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("21_corner_topleft_bottomright", label, &nodes, &results);
}

#[test]
fn ortho_corner_top_right_to_bottom_left() {
    let label = "TopRight→BottomLeft corner ports, cross-diagonal";
    let nodes = vec![
        node("a", 100.0, 100.0, 120.0, 80.0),
        node("b", 350.0, 250.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge_ports("e1", "a", "b", PortSide::TopRight, PortSide::BottomLeft)];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("22_corner_topright_bottomleft", label, &nodes, &results);
}

// ── Close/extreme ──

#[test]
fn ortho_close_nodes() {
    let label = "Close nodes, tight gap";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 260.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("23_close_nodes", label, &nodes, &results);
}

#[test]
fn ortho_far_nodes() {
    let label = "Far nodes, long distance";
    let nodes = vec![
        node("a", 100.0, 200.0, 120.0, 80.0),
        node("b", 900.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    print_log(label, &results);
    render_svg("24_far_nodes", label, &nodes, &results);
}

// ── Randomized scenarios ──

struct RandLayout {
    label: String,
    nodes: Vec<InputNode>,
    edges: Vec<InputEdge>,
}

fn generate_layout(seed: u64) -> RandLayout {
    let mut rng = rand::rngs::SmallRng::seed_from_u64(seed);
    let count = rng.random_range(4..=7);
    let mut nodes = Vec::with_capacity(count);
    let mut node_ids: Vec<String> = Vec::new();

    for i in 0..count {
        let id = format!("n{}", i);
        let w = rng.random_range(40.0..140.0);
        let h = rng.random_range(40.0..100.0);
        let is_obs = i > 0 && i < count - 1 && rng.random_bool(0.35);
        let max_attempts = 200;
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

    let valid: Vec<usize> = (0..count).filter(|&i| !nodes[i].is_obstacle).collect();
    let from = if valid.len() >= 2 { valid[0] } else { 0 };
    let to = if valid.len() >= 2 { valid[1] } else { count.saturating_sub(1) };

    let sides = [PortSide::Top, PortSide::Right, PortSide::Bottom, PortSide::Left];
    let fs = if rng.random_bool(0.6) { Some(sides[rng.random_range(0..4)].clone()) } else { None };
    let ts = if rng.random_bool(0.6) { Some(sides[rng.random_range(0..4)].clone()) } else { None };

    let edge = InputEdge {
        id: "e1".into(),
        from_node_id: node_ids[from].clone(),
        to_node_id: node_ids[to].clone(),
        from_side: fs.clone(),
        to_side: ts.clone(),
        routing_mode: Some(RoutingMode::Orthogonal),
        bundling_mode: None,
        style: None,
    };

    let label = format!(
        "Random ortho seed={} ({} nodes, {}→{}, ports={:?}→{:?})",
        seed, count, node_ids[from], node_ids[to], fs, ts
    );
    RandLayout { label, nodes, edges: vec![edge] }
}

macro_rules! ortho_random_test {
    ($name:ident, $seed:expr) => {
        #[test]
        fn $name() {
            let rl = generate_layout($seed);
            let config = RelationEngineConfig::default();
            let results = RelationEngine::compute_relations(&rl.nodes, &rl.edges, &config, None);
            print_log(&rl.label, &results);
            render_svg(&format!("{}_random_ortho", $seed), &rl.label, &rl.nodes, &results);
        }
    };
}

ortho_random_test!(ortho_random_20, 20);
ortho_random_test!(ortho_random_21, 21);
ortho_random_test!(ortho_random_22, 22);
ortho_random_test!(ortho_random_23, 23);
ortho_random_test!(ortho_random_24, 24);
ortho_random_test!(ortho_random_25, 25);
