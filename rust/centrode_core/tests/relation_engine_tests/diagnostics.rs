use centrode_core::relation_engine::config::{
    RelationEngineConfig,
    RoutingMode,
};
use centrode_core::relation_engine::engine::RelationEngine;

fn polyline_config() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Polyline;
    config.nudging.enabled = false;
    config
}

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

fn orthogonal_with_nudging() -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.nudging.enabled = true;
    config
}

#[test]
fn run_all_polyline_diagnostics() {
    let config = polyline_config();
    let scenarios = super::scenarios::all_scenarios();
    for mut s in scenarios {
        for edge in &mut s.edges {
            edge.routing_mode = Some(RoutingMode::Polyline);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &config, None);

        if s.filename == "30_missing_node_fallback" {
            for r in &results {
                assert_eq!(
                    r.path_points.len(),
                    2,
                    "Missing node relation must have exactly 2 points"
                );
                assert_eq!(
                    r.path_points[0],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
                assert_eq!(
                    r.path_points[1],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
            }
        } else {
            for r in &results {
                super::common::verify_path_properties(r, RoutingMode::Polyline);
                super::common::verify_finalize_fields(r);
            }
        }

        super::common::render_svg(
            "polyline",
            &format!("polyline_{}", s.filename),
            s.label,
            &s.nodes,
            &s.edges,
            &results,
            &config,
        );
    }
}

#[test]
fn run_all_orthogonal_diagnostics() {
    let config = orthogonal_config();
    let scenarios = super::scenarios::all_scenarios();
    for mut s in scenarios {
        for edge in &mut s.edges {
            edge.routing_mode = Some(RoutingMode::Orthogonal);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &config, None);

        if s.filename == "30_missing_node_fallback" {
            for r in &results {
                assert_eq!(
                    r.path_points.len(),
                    2,
                    "Missing node relation must have exactly 2 points"
                );
                assert_eq!(
                    r.path_points[0],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
                assert_eq!(
                    r.path_points[1],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
            }
        } else {
            for r in &results {
                super::common::verify_path_properties(r, RoutingMode::Orthogonal);
                super::common::verify_finalize_fields(r);
            }
        }

        super::common::render_svg(
            "orthogonal",
            &format!("orthogonal_{}", s.filename),
            s.label,
            &s.nodes,
            &s.edges,
            &results,
            &config,
        );
    }
}

#[test]
fn run_all_bspline_diagnostics() {
    let config = bspline_config();
    let scenarios = super::scenarios::all_scenarios();
    for mut s in scenarios {
        for edge in &mut s.edges {
            edge.routing_mode = Some(RoutingMode::BSpline);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &config, None);

        if s.filename == "30_missing_node_fallback" {
            for r in &results {
                assert_eq!(
                    r.path_points.len(),
                    2,
                    "Missing node relation must have exactly 2 points"
                );
                assert_eq!(
                    r.path_points[0],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
                assert_eq!(
                    r.path_points[1],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
            }
        } else {
            for r in &results {
                super::common::verify_path_properties(r, RoutingMode::BSpline);
                super::common::verify_finalize_fields(r);
            }
        }

        super::common::render_svg(
            "bspline",
            &format!("bspline_{}", s.filename),
            s.label,
            &s.nodes,
            &s.edges,
            &results,
            &config,
        );
    }
}

#[test]
fn run_all_octilinear_diagnostics() {
    let config = octilinear_config();
    let scenarios = super::scenarios::all_scenarios();
    for mut s in scenarios {
        for edge in &mut s.edges {
            edge.routing_mode = Some(RoutingMode::Octilinear);
        }
        let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &config, None);

        if s.filename == "30_missing_node_fallback" {
            for r in &results {
                assert_eq!(
                    r.path_points.len(),
                    2,
                    "Missing node relation must have exactly 2 points"
                );
                assert_eq!(
                    r.path_points[0],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
                assert_eq!(
                    r.path_points[1],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
            }
        } else {
            for r in &results {
                super::common::verify_path_properties(r, RoutingMode::Octilinear);
                super::common::verify_finalize_fields(r);
            }
        }

        super::common::render_svg(
            "octilinear",
            &format!("octilinear_{}", s.filename),
            s.label,
            &s.nodes,
            &s.edges,
            &results,
            &config,
        );
    }
}

#[test]
fn run_all_bezier_diagnostics() {
    let config = bezier_config();
    let scenarios = super::scenarios::all_scenarios();
    for mut s in scenarios {
        for edge in &mut s.edges {
            edge.routing_mode = Some(RoutingMode::Bezier {
                control_point_1: None,
                control_point_2: None,
            });
        }
        let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &config, None);

        if s.filename == "30_missing_node_fallback" {
            for r in &results {
                assert_eq!(
                    r.path_points.len(),
                    2,
                    "Missing node relation must have exactly 2 points"
                );
                assert_eq!(
                    r.path_points[0],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
                assert_eq!(
                    r.path_points[1],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
            }
        } else {
            for r in &results {
                super::common::verify_path_properties(
                    r,
                    RoutingMode::Bezier {
                        control_point_1: None,
                        control_point_2: None,
                    },
                );
                super::common::verify_finalize_fields(r);
            }
        }

        super::common::render_svg(
            "bezier",
            &format!("bezier_{}", s.filename),
            s.label,
            &s.nodes,
            &s.edges,
            &results,
            &config,
        );
    }
}

#[test]
fn run_all_nudging_diagnostics() {
    let scenarios = super::scenarios::all_scenarios();

    // Test orthogonal nudging (rendered into target/relation_engine_diag/orthogonal/ to avoid nudge dir creation)
    let ortho_nudge = orthogonal_with_nudging();
    for mut s in scenarios.clone() {
        if s.filename == "29_multi_edge_nudging" {
            for edge in &mut s.edges {
                edge.routing_mode = Some(RoutingMode::Orthogonal);
            }
            let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &ortho_nudge, None);
            super::common::render_svg(
                "orthogonal",
                &format!("nudge_orthogonal_{}", s.filename),
                s.label,
                &s.nodes,
                &s.edges,
                &results,
                &ortho_nudge,
            );
            super::common::verify_nudging(&results);
        }
    }

    // Test bspline nudging (rendered into target/relation_engine_diag/bspline/ to avoid nudge dir creation)
    let mut bspline_nudge = bspline_config();
    bspline_nudge.nudging.enabled = true;
    for mut s in scenarios {
        if s.filename == "29_multi_edge_nudging" {
            for edge in &mut s.edges {
                edge.routing_mode = Some(RoutingMode::BSpline);
            }
            let results =
                RelationEngine::compute_relations(&s.nodes, &s.edges, &bspline_nudge, None);
            super::common::render_svg(
                "bspline",
                &format!("nudge_bspline_{}", s.filename),
                s.label,
                &s.nodes,
                &s.edges,
                &results,
                &bspline_nudge,
            );
            super::common::verify_nudging(&results);
        }
    }
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

#[test]
fn run_all_sinewave_diagnostics() {
    let config = sinewave_config();
    let scenarios = super::scenarios::all_scenarios();
    for mut s in scenarios {
        for edge in &mut s.edges {
            edge.routing_mode = Some(RoutingMode::SineWave {
                control_point_1: None,
                control_point_2: None,
            });
        }
        let results = RelationEngine::compute_relations(&s.nodes, &s.edges, &config, None);

        if s.filename == "30_missing_node_fallback" {
            for r in &results {
                assert_eq!(
                    r.path_points.len(),
                    2,
                    "Missing node relation must have exactly 2 points"
                );
                assert_eq!(
                    r.path_points[0],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
                assert_eq!(
                    r.path_points[1],
                    centrode_core::relation_engine::geometry::Point::new(0.0, 0.0)
                );
            }
        } else {
            for r in &results {
                super::common::verify_path_properties(
                    r,
                    RoutingMode::SineWave {
                        control_point_1: None,
                        control_point_2: None,
                    },
                );
                super::common::verify_finalize_fields(r);
            }
        }

        super::common::render_svg(
            "sinewave",
            &format!("sinewave_{}", s.filename),
            s.label,
            &s.nodes,
            &s.edges,
            &results,
            &config,
        );
    }
}
