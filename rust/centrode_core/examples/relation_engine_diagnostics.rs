use centrode_core::relation_engine::config::{RelationEngineConfig, RoutingMode};
use centrode_core::relation_engine::engine::RelationEngine;

#[allow(dead_code)]
#[path = "../tests/relation_engine_tests/scenarios.rs"]
mod scenarios;

#[allow(dead_code)]
#[path = "../tests/relation_engine_tests/common/mod.rs"]
mod common;

fn orthogonal_config() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.nudging.enabled = false;
    config
}

fn bspline_config() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::BSpline;
    config.nudging.enabled = false;
    config
}

fn octilinear_config() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Octilinear;
    config.nudging.enabled = false;
    config
}

fn bezier_config() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Bezier {
        control_point_1: None,
        control_point_2: None,
    };
    config.nudging.enabled = false;
    config
}

fn sinewave_config() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::SineWave {
        control_point_1: None,
        control_point_2: None,
    };
    config.nudging.enabled = false;
    config
}

fn orthogonal_with_nudging() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.nudging.enabled = true;
    config
}

fn run_orthogonal(scenarios: &[scenarios::Scenario]) {
    println!("Rendering orthogonal scenarios...");
    let config = orthogonal_config();
    for s in scenarios {
        let mut edges = s.edges.clone();
        for edge in &mut edges {
            edge.routing_mode = Some(RoutingMode::Orthogonal);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &edges, &config, None);
        common::render_svg(
            "orthogonal",
            &format!("orthogonal_{}", s.filename),
            s.label,
            &s.nodes,
            &edges,
            &results,
            &config,
        );
    }
}

fn run_bspline(scenarios: &[scenarios::Scenario]) {
    println!("Rendering bspline scenarios...");
    let config = bspline_config();
    for s in scenarios {
        let mut edges = s.edges.clone();
        for edge in &mut edges {
            edge.routing_mode = Some(RoutingMode::BSpline);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &edges, &config, None);
        common::render_svg(
            "bspline",
            &format!("bspline_{}", s.filename),
            s.label,
            &s.nodes,
            &edges,
            &results,
            &config,
        );
    }
}

fn run_octilinear(scenarios: &[scenarios::Scenario]) {
    println!("Rendering octilinear scenarios...");
    let config = octilinear_config();
    for s in scenarios {
        let mut edges = s.edges.clone();
        for edge in &mut edges {
            edge.routing_mode = Some(RoutingMode::Octilinear);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &edges, &config, None);
        common::render_svg(
            "octilinear",
            &format!("octilinear_{}", s.filename),
            s.label,
            &s.nodes,
            &edges,
            &results,
            &config,
        );
    }
}

fn run_bezier(scenarios: &[scenarios::Scenario]) {
    println!("Rendering bezier scenarios...");
    let config = bezier_config();
    for s in scenarios {
        let mut edges = s.edges.clone();
        for edge in &mut edges {
            edge.routing_mode = Some(RoutingMode::Bezier {
                control_point_1: None,
                control_point_2: None,
            });
        }
        let results = RelationEngine::compute_relations(&s.nodes, &edges, &config, None);
        common::render_svg(
            "bezier",
            &format!("bezier_{}", s.filename),
            s.label,
            &s.nodes,
            &edges,
            &results,
            &config,
        );
    }
}

fn run_sinewave(scenarios: &[scenarios::Scenario]) {
    println!("Rendering sinewave scenarios...");
    let config = sinewave_config();
    for s in scenarios {
        let mut edges = s.edges.clone();
        for edge in &mut edges {
            edge.routing_mode = Some(RoutingMode::SineWave {
                control_point_1: None,
                control_point_2: None,
            });
        }
        let results = RelationEngine::compute_relations(&s.nodes, &edges, &config, None);
        common::render_svg(
            "sinewave",
            &format!("sinewave_{}", s.filename),
            s.label,
            &s.nodes,
            &edges,
            &results,
            &config,
        );
    }
}

fn run_nudging(scenarios: &[scenarios::Scenario]) {
    println!("Rendering nudging scenarios...");
    let ortho_nudge = orthogonal_with_nudging();
    for s in scenarios {
        if s.filename == "29_multi_edge_nudging" {
            let mut edges = s.edges.clone();
            for edge in &mut edges {
                edge.routing_mode = Some(RoutingMode::Orthogonal);
            }
            let results = RelationEngine::compute_relations(&s.nodes, &edges, &ortho_nudge, None);
            common::render_svg(
                "orthogonal",
                &format!("nudge_orthogonal_{}", s.filename),
                s.label,
                &s.nodes,
                &edges,
                &results,
                &ortho_nudge,
            );
        }
    }

    let mut bspline_nudge = bspline_config();
    bspline_nudge.nudging.enabled = true;
    for s in scenarios {
        if s.filename == "29_multi_edge_nudging" {
            let mut edges = s.edges.clone();
            for edge in &mut edges {
                edge.routing_mode = Some(RoutingMode::BSpline);
            }
            let results = RelationEngine::compute_relations(&s.nodes, &edges, &bspline_nudge, None);
            common::render_svg(
                "bspline",
                &format!("nudge_bspline_{}", s.filename),
                s.label,
                &s.nodes,
                &edges,
                &results,
                &bspline_nudge,
            );
        }
    }
}

fn main() {
    let all = scenarios::all_scenarios();
    println!(
        "Running relation engine visual diagnostics across {} scenarios...",
        all.len()
    );
    run_orthogonal(&all);
    run_bspline(&all);
    run_octilinear(&all);
    run_bezier(&all);
    run_nudging(&all);
    run_sinewave(&all);
    println!("All relation engine visual diagnostics rendered to target/relation_engine_diag/");
}
