use rust_lib_mycelium::domain::relation_engine::computed::{ComputedRelation, PathType};
use rust_lib_mycelium::domain::relation_engine::geometry::{polyline_length, Point, Rect};
use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::relation_engine::config::{RelationEngineConfig, RoutingMode};
use std::io::Write;

pub fn verify_octilinear_path(path: &[Point]) {
    if path.len() < 3 {
        return;
    }
    for i in 1..path.len() - 2 {
        let p1 = path[i];
        let p2 = path[i + 1];
        let dx = p2.x - p1.x;
        let dy = p2.y - p1.y;
        if dx.abs() < 1e-5 && dy.abs() < 1e-5 {
            continue;
        }
        let is_ortho = dx.abs() < 1e-5 || dy.abs() < 1e-5;
        let is_diag = (dx.abs() - dy.abs()).abs() < 1e-5;
        assert!(
            is_ortho || is_diag,
            "Path segment is not octilinear! Segment from {:?} to {:?} has dx = {}, dy = {}",
            p1, p2, dx, dy
        );
    }
}

pub fn verify_straight_path(path: &[Point]) {
    assert!(path.len() >= 2, "Straight path must have at least 2 points");
    let start = path[0];
    let end = *path.last().unwrap();
    for p in path {
        let collinear = (p.x - start.x) * (end.y - start.y) - (p.y - start.y) * (end.x - start.x);
        assert!(
            collinear.abs() < 1e-6,
            "Point {:?} is not collinear with start {:?} and end {:?}",
            p, start, end
        );
    }
}

pub fn verify_path_properties(r: &ComputedRelation, mode: RoutingMode) {
    assert!(
        r.path_points.len() >= 2,
        "Path must have at least 2 points (relation ID: {})",
        r.id
    );
    match mode {
        RoutingMode::Polyline => assert_eq!(r.path_type, PathType::Straight),
        RoutingMode::Orthogonal => assert_eq!(r.path_type, PathType::Orthogonal),
        RoutingMode::BSpline => assert_eq!(r.path_type, PathType::BSpline),
        RoutingMode::Bezier { .. } => assert_eq!(r.path_type, PathType::Bezier),
        RoutingMode::SineWave { .. } => assert_eq!(r.path_type, PathType::SineWave),
        RoutingMode::Octilinear => {
            if r.path_type == PathType::Orthogonal {
                verify_octilinear_path(&r.control_points);
            }
        }
    }
}

pub fn verify_finalize_fields(r: &ComputedRelation) {
    assert!(
        r.start_tangent.x != 0.0 || r.start_tangent.y != 0.0,
        "Start tangent should be computed (relation ID: {})",
        r.id
    );
    assert!(
        r.end_tangent.x != 0.0 || r.end_tangent.y != 0.0,
        "End tangent should be computed (relation ID: {})",
        r.id
    );
    assert!(
        r.bbox.width >= 0.0 && r.bbox.height >= 0.0,
        "Bounding box dimensions must be non-negative"
    );
    assert!(
        r.start_point.x != 0.0 || r.start_point.y != 0.0,
        "Start point should be set"
    );
    assert!(
        r.end_point.x != 0.0 || r.end_point.y != 0.0,
        "End point should be set"
    );
}

pub fn verify_nudging(results: &[ComputedRelation]) {
    if results.len() <= 1 {
        return;
    }
    for i in 0..results.len() {
        for j in (i + 1)..results.len() {
            let r1 = &results[i];
            let r2 = &results[j];
            if r1.path_points == r2.path_points {
                println!("--- NUDGING VERIFICATION FAILURE DEBUG ---");
                for r in results {
                    println!("Relation {}: path={:?}", r.id, r.path_points);
                }
                panic!(
                    "Parallel relations {} and {} have identical paths. Nudging failed!",
                    r1.id, r2.id
                );
            }
        }
    }
}

pub fn render_svg(
    subdir: &str,
    filename: &str,
    label: &str,
    nodes: &[InputNode],
    _edges: &[InputEdge],
    results: &[ComputedRelation],
    config: &RelationEngineConfig,
) {
    let waypoint_color = "#f39c12";
    let mut min_x = f64::MAX;
    let mut min_y = f64::MAX;
    let mut max_x = f64::MIN;
    let mut max_y = f64::MIN;

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
        for p in &r.control_points {
            min_x = min_x.min(p.x);
            min_y = min_y.min(p.y);
            max_x = max_x.max(p.x);
            max_y = max_y.max(p.y);
        }
    }

    let pad = 60.0;
    min_x -= pad;
    min_y -= pad;
    max_x += pad;
    max_y += pad;
    let w = max_x - min_x;
    let h = max_y - min_y;

    // Load nudge groups to apply colors to paths
    let mut edge_colors = std::collections::HashMap::new();
    let palette = [
        "#ff6b6b", "#4dabf7", "#51cf66", "#fcc419", "#cc5de8",
        "#20c997", "#ff922b", "#748ffc", "#f06595", "#38d9a9",
    ];
    if let Ok(file) = std::fs::File::open("target/nudge_line_groups.json") {
        let parsed: Result<Vec<Vec<String>>, _> = serde_json::from_reader(file);
        if let Ok(groups) = parsed {
            for (g_idx, group) in groups.iter().enumerate() {
                let color = palette[g_idx % palette.len()];
                for id in group {
                    edge_colors.insert(id.clone(), color.to_string());
                }
            }
        }
    }

    let mut svg = String::new();
    svg.push_str(&format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"{} {} {} {}\" width=\"{}\" height=\"{}\">\n",
        min_x, min_y, w, h, w.max(800.0), h.max(400.0),
    ));
    svg.push_str(&format!(
        "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" fill=\"#1a1a2e\"/>\n",
        min_x, min_y, w, h
    ));

    // 1. Draw outer Obstacle boxes
    for n in nodes {
        if n.is_obstacle {
            let om = config.routing.outer_bbox_distance();
            svg.push_str(&format!(
                "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" rx=\"3\" fill=\"none\" stroke=\"rgba(200,100,100,0.2)\" stroke-width=\"1\" stroke-dasharray=\"6,4\"/>\n",
                n.x - om, n.y - om, n.width + 2.0 * om, n.height + 2.0 * om,
            ));
        }
    }

    // 2. Draw Node & Obstacle base shapes (No text inside node rectangles yet)
    for n in nodes {
        svg.push_str(&format!(
            "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" rx=\"6\" fill=\"#16213e\" stroke=\"#e0e0e0\" stroke-width=\"1.5\"/>\n",
            n.x, n.y, n.width, n.height,
        ));
    }

    // 3. Draw inner Obstacle bounds
    for n in nodes {
        if n.is_obstacle {
            let cx = n.x + n.width / 2.0;
            let cy = n.y + n.height / 2.0;
            let is = config.routing.inner_bbox_scale();
            let hw = n.width * is / 2.0;
            let hh = n.height * is / 2.0;
            svg.push_str(&format!(
                "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" rx=\"2\" fill=\"rgba(200,30,30,0.4)\" stroke=\"rgba(255,50,50,0.9)\" stroke-width=\"2\"/>\n",
                cx - hw, cy - hh, n.width * is, n.height * is,
            ));
        }
    }

    // 4. Draw paths, reference lines, control points, and port dots
    for r in results.iter() {
        let group_color = edge_colors.get(&r.id).cloned().unwrap_or_else(|| "#ff0000".to_string());
        let default_color = group_color.as_str();
        let pts = &r.path_points;
        let cpts = &r.control_points;
        if pts.len() >= 2 {
            // Draw straight reference line
            let (sx, sy) = (pts[0].x, pts[0].y);
            let (ex, ey) = (pts[pts.len() - 1].x, pts[pts.len() - 1].y);
            svg.push_str(&format!(
                "<line x1=\"{:.2}\" y1=\"{:.2}\" x2=\"{:.2}\" y2=\"{:.2}\" stroke=\"{}\" stroke-width=\"1\" stroke-dasharray=\"6,4\" opacity=\"0.15\"/>\n",
                sx, sy, ex, ey, default_color,
            ));

            // Draw custom color segments (if nudged via compose)
            let has_colors = !r.nudge_colors.is_empty();
            if has_colors {
                for i in 0..pts.len() - 1 {
                    let seg_color = if i < r.nudge_colors.len() && !r.nudge_colors[i].is_empty() {
                        &r.nudge_colors[i]
                    } else {
                        default_color
                    };
                    svg.push_str(&format!(
                        "<line x1=\"{:.2}\" y1=\"{:.2}\" x2=\"{:.2}\" y2=\"{:.2}\" stroke=\"{}\" stroke-width=\"2.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n",
                        pts[i].x, pts[i].y, pts[i+1].x, pts[i+1].y, seg_color,
                    ));
                }
            } else {
                let mut path_d = format!("M {:.2} {:.2}", pts[0].x, pts[0].y);
                for p in &pts[1..] {
                    path_d.push_str(&format!(" L {:.2} {:.2}", p.x, p.y));
                }
                svg.push_str(&format!(
                    "<path d=\"{}\" fill=\"none\" stroke=\"{}\" stroke-width=\"2.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n",
                    path_d, default_color
                ));
            }

            // Draw final control points
            if cpts.len() >= 2 {
                let mut cpts_d = format!("M {:.2} {:.2}", cpts[0].x, cpts[0].y);
                for p in &cpts[1..] {
                    cpts_d.push_str(&format!(" L {:.2} {:.2}", p.x, p.y));
                }
                svg.push_str(&format!(
                    "<path d=\"{}\" fill=\"none\" stroke=\"{}\" stroke-width=\"1\" stroke-dasharray=\"3,3\" opacity=\"0.6\"/>\n",
                    cpts_d, waypoint_color,
                ));
                for (i, p) in cpts.iter().enumerate() {
                    let (r_rad, fill) = if i == 0 || i == cpts.len() - 1 {
                        (4.0, "#ffffff")
                    } else {
                        (2.5, waypoint_color)
                    };
                    svg.push_str(&format!(
                        "<circle cx=\"{:.2}\" cy=\"{:.2}\" r=\"{}\" fill=\"{}\" stroke=\"{}\" stroke-width=\"1\"/>\n",
                        p.x, p.y, r_rad, fill, waypoint_color,
                    ));
                }
            }
        }
    }

    // 5. Draw node boundary port dots
    for n in nodes {
        let ps = [
            (n.x + n.width / 2.0, n.y),
            (n.x + n.width, n.y + n.height / 2.0),
            (n.x + n.width / 2.0, n.y + n.height),
            (n.x, n.y + n.height / 2.0),
            (n.x, n.y),
            (n.x + n.width, n.y),
            (n.x + n.width, n.y + n.height),
            (n.x, n.y + n.height),
        ];
        for (px, py) in &ps {
            svg.push_str(&format!(
                "<circle cx=\"{:.1}\" cy=\"{:.1}\" r=\"3\" fill=\"#555\" stroke=\"#888\" stroke-width=\"0.5\"/>\n",
                px, py,
            ));
        }
    }

    // 6. Text layer (Drawn last to bring it up in layers and be fully visible)
    for n in nodes {
        svg.push_str(&format!(
            "<text x=\"{}\" y=\"{}\" font-family=\"sans-serif\" font-weight=\"bold\" font-size=\"11\" fill=\"#ffffff\" text-anchor=\"middle\">{}</text>\n",
            n.x + n.width / 2.0, n.y + n.height / 2.0 + 4.0, n.id,
        ));
    }

    let top_y = min_y + 16.0;
    let mut lx = min_x + 10.0;
    svg.push_str(&format!(
        "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"11\" fill=\"#ffffff\">{}</text>\n",
        lx, top_y, label,
    ));
    lx += label.len() as f64 * 6.6 + 12.0;
    for r in results.iter() {
        let group_color = edge_colors.get(&r.id).cloned().unwrap_or_else(|| "#ff0000".to_string());
        let pts = &r.path_points;
        let info = format!(
            "{} ({} pts, {:.0}px)",
            r.id,
            pts.len(),
            polyline_length(pts)
        );
        svg.push_str(&format!(
            "<text x=\"{}\" y=\"{}\" font-family=\"monospace\" font-size=\"10\" fill=\"{}\">{}</text>\n",
            lx, top_y, group_color, info,
        ));
        lx += info.len() as f64 * 6.0 + 14.0;
    }

    svg.push_str("</svg>\n");

    let out_dir = std::path::Path::new("target")
        .join("relation_engine_diag")
        .join(subdir);
    std::fs::create_dir_all(&out_dir).unwrap();
    let svg_path = out_dir.join(format!("{}.svg", filename));
    std::fs::write(&svg_path, &svg).unwrap();
    println!(
        "SVG: {}",
        std::fs::canonicalize(&svg_path).unwrap().display()
    );

    if let Err(e) = render_png(&svg, &out_dir.join(format!("{}.png", filename))) {
        eprintln!("PNG render failed: {}", e);
    }
    write_enriched_json(subdir, filename, label, nodes, results);
}

fn render_png(
    svg_data: &str,
    png_path: &std::path::Path,
) -> Result<(), Box<dyn std::error::Error>> {
    let opt = usvg::Options::default();
    let tree = usvg::Tree::from_data(svg_data.as_bytes(), &opt)?;
    let size = tree.size();
    let svg_w = size.width();
    let svg_h = size.height();
    let width = svg_w.max(800.0) as u32;
    let height = svg_h.max(400.0) as u32;
    let mut pixmap =
        tiny_skia::Pixmap::new(width, height).ok_or("failed to create pixmap")?;
    let scale_x = width as f32 / svg_w;
    let scale_y = height as f32 / svg_h;
    let transform = tiny_skia::Transform::from_scale(scale_x, scale_y);
    resvg::render(&tree, transform, &mut pixmap.as_mut());
    pixmap.save_png(png_path)?;
    Ok(())
}

fn write_enriched_json(
    subdir: &str,
    filename: &str,
    label: &str,
    nodes: &[InputNode],
    results: &[ComputedRelation],
) {
    let out_dir = std::path::Path::new("target")
        .join("relation_engine_diag")
        .join(subdir);
    std::fs::create_dir_all(&out_dir).unwrap();
    let path = out_dir.join(format!("{}.json", filename));
    let mut json = String::new();
    json.push_str("{\n");
    json.push_str(&format!("  \"label\": {:?},\n", label));
    json.push_str(&format!("  \"filename\": {:?},\n", filename));
    json.push_str("  \"nodes\": [\n");
    for (i, n) in nodes.iter().enumerate() {
        json.push_str(&format!(
            "    {{\"id\":{:?},\"x\":{:.1},\"y\":{:.1},\"w\":{:.1},\"h\":{:.1},\"obstacle\":{}}}",
            n.id, n.x, n.y, n.width, n.height, n.is_obstacle,
        ));
        if i < nodes.len() - 1 {
            json.push(',');
        }
        json.push('\n');
    }
    json.push_str("  ],\n");
    json.push_str("  \"relations\": [\n");
    for (ri, r) in results.iter().enumerate() {
        let pts = &r.path_points;
        let n = pts.len();
        let path_len = polyline_length(pts);
        json.push_str("    {\n");
        json.push_str(&format!("      \"id\": {:?},\n", r.id));
        json.push_str(&format!("      \"num_points\": {},\n", n));
        json.push_str(&format!("      \"path_length\": {:.3},\n", path_len));
        json.push_str(&format!("      \"compose_active\": {},\n", r.compose_active));
        json.push_str("      \"points\": [\n");
        for (i, p) in pts.iter().enumerate() {
            json.push_str(&format!("        {{\"x\":{:.2},\"y\":{:.2}}}", p.x, p.y));
            if i < n - 1 {
                json.push(',');
            }
            json.push('\n');
        }
        json.push_str("      ],\n");
        json.push_str("      \"control_points\": [\n");
        for (i, p) in r.control_points.iter().enumerate() {
            json.push_str(&format!("        {{\"x\":{:.2},\"y\":{:.2}}}", p.x, p.y));
            if i < r.control_points.len() - 1 {
                json.push(',');
            }
            json.push('\n');
        }
        json.push_str("      ]\n");
        json.push_str("    }");
        if ri < results.len() - 1 {
            json.push(',');
        }
        json.push('\n');
    }
    json.push_str("  ]\n}\n");
    let mut f = std::fs::File::create(&path).unwrap();
    f.write_all(json.as_bytes()).unwrap();
}
