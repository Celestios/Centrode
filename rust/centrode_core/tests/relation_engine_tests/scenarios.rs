use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::styles::PortSide;
use centrode_core::domain::traits::TableKind;
use centrode_core::relation_engine::input::{InputEdge, InputNode};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use uuid::Uuid;

#[derive(Clone)]
pub struct Scenario {
    pub label: &'static str,
    pub filename: &'static str,
    pub nodes: Vec<InputNode>,
    pub edges: Vec<InputEdge>,
}

fn str_to_uuid(s: &str) -> Uuid {
    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    let hash = hasher.finish();
    Uuid::from_u128(hash as u128)
}

fn tid(table: TableKind, s: &str) -> TypedRecordId {
    TypedRecordId::new(table, str_to_uuid(s))
}

fn node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode {
        id: tid(TableKind::INode, id),
        x,
        y,
        width: w,
        height: h,
        is_obstacle: true,
    }
}

fn edge(id: &str, from: &str, to: &str, fs: Option<PortSide>, ts: Option<PortSide>) -> InputEdge {
    InputEdge {
        id: tid(TableKind::IRelation, id),
        from_node_id: tid(TableKind::INode, from),
        to_node_id: tid(TableKind::INode, to),
        from_side: fs,
        to_side: ts,
        routing_mode: None,
        bundling_mode: None,
        style: None,
    }
}

pub fn all_scenarios() -> Vec<Scenario> {
    let mut scenarios = vec![
        Scenario {
            label: "Horizontal (Right->Left, same height)",
            filename: "01_horizontal",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 700.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Horizontal offset (Right->Left, different height)",
            filename: "02_horizontal_offset",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 700.0, 380.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "With obstacle in middle",
            filename: "03_with_obstacle",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs", 400.0, 180.0, 100.0, 120.0),
                node("b", 720.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Multiple obstacles forcing S-curve",
            filename: "04_s_curve",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs1", 360.0, 130.0, 50.0, 180.0),
                node("obs2", 520.0, 180.0, 50.0, 180.0),
                node("b", 750.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Top->Bottom vertical routing",
            filename: "05_top_to_bottom",
            nodes: vec![
                node("a", 100.0, 30.0, 120.0, 80.0),
                node("b", 100.0, 340.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Bottom),
                Some(PortSide::Top),
            )],
        },
        Scenario {
            label: "U-shaped obstacle forcing backtrack",
            filename: "06_u_shape",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs_l", 350.0, 50.0, 40.0, 300.0),
                node("obs_r", 500.0, 50.0, 40.0, 300.0),
                node("obs_t", 350.0, 30.0, 190.0, 40.0),
                node("b", 750.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Top->Top same side",
            filename: "07_top_to_top",
            nodes: vec![
                node("a", 100.0, 300.0, 120.0, 80.0),
                node("b", 600.0, 300.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Top),
                Some(PortSide::Top),
            )],
        },
        Scenario {
            label: "Bottom->Bottom same side",
            filename: "08_bottom_to_bottom",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 600.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Bottom),
                Some(PortSide::Bottom),
            )],
        },
        Scenario {
            label: "Left->Right facing away",
            filename: "09_left_to_right",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 600.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Left),
                Some(PortSide::Right),
            )],
        },
        Scenario {
            label: "Right->Right same side loop",
            filename: "10_right_to_right",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 600.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Right),
            )],
        },
        Scenario {
            label: "Close nodes",
            filename: "11_close_nodes",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 350.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Far nodes",
            filename: "12_far_nodes",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("b", 1000.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Wide obstacle blocking direct path",
            filename: "13_wide_obstacle",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs", 380.0, 70.0, 300.0, 260.0),
                node("b", 900.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Tall obstacle blocking vertical",
            filename: "14_tall_obstacle_vertical",
            nodes: vec![
                node("a", 50.0, 20.0, 120.0, 80.0),
                node("obs", 60.0, 190.0, 100.0, 200.0),
                node("b", 50.0, 480.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Bottom),
                Some(PortSide::Top),
            )],
        },
        Scenario {
            label: "TopRight->BottomLeft corner ports",
            filename: "15_corner_ports",
            nodes: vec![
                node("a", 100.0, 80.0, 120.0, 80.0),
                node("b", 500.0, 300.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::TopRight),
                Some(PortSide::BottomLeft),
            )],
        },
        Scenario {
            label: "Zigzag obstacles",
            filename: "16_zigzag",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs1", 350.0, 100.0, 40.0, 120.0),
                node("obs2", 450.0, 280.0, 40.0, 120.0),
                node("obs3", 550.0, 100.0, 40.0, 120.0),
                node("b", 800.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Narrow corridor between obstacles",
            filename: "17_narrow_corridor",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs1", 360.0, 150.0, 20.0, 180.0),
                node("obs2", 420.0, 150.0, 20.0, 180.0),
                node("b", 700.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Bottom->Top vertical (port offset)",
            filename: "18_bottom_to_top",
            nodes: vec![
                node("a", 100.0, 100.0, 120.0, 80.0),
                node("b", 700.0, 100.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Bottom),
                Some(PortSide::Top),
            )],
        },
        Scenario {
            label: "TopRight->BottomLeft diagonal",
            filename: "19_tr_to_bl",
            nodes: vec![
                node("a", 50.0, 100.0, 100.0, 80.0),
                node("b", 600.0, 100.0, 100.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::TopRight),
                Some(PortSide::BottomLeft),
            )],
        },
        Scenario {
            label: "Offset obstacle above the direct line",
            filename: "20_offset_obstacle_above",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs", 400.0, 110.0, 100.0, 60.0),
                node("b", 720.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        // Scenario 21: 30 nodes and 15 relations
        {
            let mut rng = SimpleRng::new(12345);
            let mut nodes = Vec::new();
            let mut id_map = Vec::new();
            for row in 0..5 {
                for col in 0..6 {
                    let idx = row * 6 + col;
                    let id = format!("n{}", idx);
                    let x_base = col as f64 * 325.0 + 100.0;
                    let y_base = row as f64 * 250.0 + 100.0;
                    let dx = rng.next_range(-80.0, 80.0);
                    let dy = rng.next_range(-60.0, 60.0);
                    let width = rng.next_range(60.0, 150.0);
                    let height = rng.next_range(50.0, 120.0);
                    nodes.push(InputNode {
                        id: tid(TableKind::INode, &id),
                        x: x_base + dx - width / 2.0,
                        y: y_base + dy - height / 2.0,
                        width,
                        height,
                        is_obstacle: true,
                    });
                    id_map.push(id);
                }
            }

            let mut edges = Vec::new();
            let sides = [
                PortSide::Top,
                PortSide::Right,
                PortSide::Bottom,
                PortSide::Left,
            ];
            for i in 0..15 {
                let from_idx = (rng.next() as usize) % 30;
                let mut to_idx = (rng.next() as usize) % 30;
                if to_idx == from_idx {
                    to_idx = (to_idx + 1) % 30;
                }
                let from_id = &id_map[from_idx];
                let to_id = &id_map[to_idx];
                let fs = sides[(rng.next() as usize) % 4].clone();
                let ts = sides[(rng.next() as usize) % 4].clone();
                edges.push(InputEdge {
                    id: tid(TableKind::IRelation, &format!("e{}", i + 1)),
                    from_node_id: tid(TableKind::INode, from_id),
                    to_node_id: tid(TableKind::INode, to_id),
                    from_side: Some(fs),
                    to_side: Some(ts),
                    routing_mode: None,
                    bundling_mode: None,
                    style: None,
                });
            }

            Scenario {
                label: "30 Nodes, 15 Random Relations",
                filename: "21_random_large",
                nodes,
                edges,
            }
        },
        Scenario {
            label: "Orthogonal routing with obstacle",
            filename: "22_orthogonal_routing",
            nodes: vec![
                node("a", 100.0, 200.0, 120.0, 80.0),
                node("obs", 400.0, 180.0, 100.0, 120.0),
                node("b", 720.0, 200.0, 120.0, 80.0),
            ],
            edges: vec![edge(
                "e1",
                "a",
                "b",
                Some(PortSide::Right),
                Some(PortSide::Left),
            )],
        },
        Scenario {
            label: "Star one-to-many (radial)",
            filename: "23_star_radial",
            nodes: vec![
                InputNode {
                    id: tid(TableKind::INode, "hub"),
                    x: 360.0,
                    y: 260.0,
                    width: 140.0,
                    height: 100.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n0"),
                    x: 650.0,
                    y: 270.0,
                    width: 100.0,
                    height: 60.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n1"),
                    x: 520.0,
                    y: 50.0,
                    width: 100.0,
                    height: 60.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n2"),
                    x: 250.0,
                    y: 50.0,
                    width: 100.0,
                    height: 60.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n3"),
                    x: 120.0,
                    y: 280.0,
                    width: 100.0,
                    height: 60.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n4"),
                    x: 260.0,
                    y: 510.0,
                    width: 100.0,
                    height: 60.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n5"),
                    x: 530.0,
                    y: 510.0,
                    width: 100.0,
                    height: 60.0,
                    is_obstacle: true,
                },
            ],
            edges: vec![
                edge(
                    "e0",
                    "hub",
                    "n0",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e1",
                    "hub",
                    "n1",
                    Some(PortSide::TopRight),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e2",
                    "hub",
                    "n2",
                    Some(PortSide::Top),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e3",
                    "hub",
                    "n3",
                    Some(PortSide::Left),
                    Some(PortSide::Right),
                ),
                edge(
                    "e4",
                    "hub",
                    "n4",
                    Some(PortSide::BottomLeft),
                    Some(PortSide::Top),
                ),
                edge(
                    "e5",
                    "hub",
                    "n5",
                    Some(PortSide::BottomRight),
                    Some(PortSide::Top),
                ),
            ],
        },
        Scenario {
            label: "Fan-out one-to-many (arc spread)",
            filename: "24_fan_out",
            nodes: vec![
                InputNode {
                    id: tid(TableKind::INode, "hub"),
                    x: 100.0,
                    y: 300.0,
                    width: 140.0,
                    height: 100.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n0"),
                    x: 550.0,
                    y: 150.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n1"),
                    x: 620.0,
                    y: 270.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n2"),
                    x: 550.0,
                    y: 400.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n3"),
                    x: 420.0,
                    y: 90.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n4"),
                    x: 420.0,
                    y: 470.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n5"),
                    x: 280.0,
                    y: 80.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n6"),
                    x: 280.0,
                    y: 490.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
            ],
            edges: vec![
                edge(
                    "e0",
                    "hub",
                    "n0",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e1",
                    "hub",
                    "n1",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e2",
                    "hub",
                    "n2",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e3",
                    "hub",
                    "n3",
                    Some(PortSide::TopRight),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e4",
                    "hub",
                    "n4",
                    Some(PortSide::BottomRight),
                    Some(PortSide::Top),
                ),
                edge(
                    "e5",
                    "hub",
                    "n5",
                    Some(PortSide::Top),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e6",
                    "hub",
                    "n6",
                    Some(PortSide::Bottom),
                    Some(PortSide::Top),
                ),
            ],
        },
        Scenario {
            label: "Surround one-to-many (all sides)",
            filename: "25_surround",
            nodes: vec![
                InputNode {
                    id: tid(TableKind::INode, "hub"),
                    x: 300.0,
                    y: 230.0,
                    width: 140.0,
                    height: 100.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_top"),
                    x: 330.0,
                    y: 60.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_right"),
                    x: 560.0,
                    y: 260.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_bottom"),
                    x: 330.0,
                    y: 460.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_left"),
                    x: 100.0,
                    y: 260.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_tr"),
                    x: 560.0,
                    y: 60.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_bl"),
                    x: 100.0,
                    y: 460.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
            ],
            edges: vec![
                edge(
                    "e_top",
                    "hub",
                    "n_top",
                    Some(PortSide::Top),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e_right",
                    "hub",
                    "n_right",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e_bottom",
                    "hub",
                    "n_bottom",
                    Some(PortSide::Bottom),
                    Some(PortSide::Top),
                ),
                edge(
                    "e_left",
                    "hub",
                    "n_left",
                    Some(PortSide::Left),
                    Some(PortSide::Right),
                ),
                edge(
                    "e_tr",
                    "hub",
                    "n_tr",
                    Some(PortSide::TopRight),
                    Some(PortSide::BottomLeft),
                ),
                edge(
                    "e_bl",
                    "hub",
                    "n_bl",
                    Some(PortSide::BottomLeft),
                    Some(PortSide::TopRight),
                ),
            ],
        },
        Scenario {
            label: "Staircase cascade one-to-many",
            filename: "26_staircase",
            nodes: vec![
                InputNode {
                    id: tid(TableKind::INode, "hub"),
                    x: 80.0,
                    y: 150.0,
                    width: 140.0,
                    height: 100.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n0"),
                    x: 360.0,
                    y: 80.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n1"),
                    x: 520.0,
                    y: 180.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n2"),
                    x: 680.0,
                    y: 280.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n3"),
                    x: 840.0,
                    y: 380.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n4"),
                    x: 1000.0,
                    y: 480.0,
                    width: 90.0,
                    height: 50.0,
                    is_obstacle: true,
                },
            ],
            edges: vec![
                edge(
                    "e0",
                    "hub",
                    "n0",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e1",
                    "hub",
                    "n1",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e2",
                    "hub",
                    "n2",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e3",
                    "hub",
                    "n3",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e4",
                    "hub",
                    "n4",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
            ],
        },
        Scenario {
            label: "Dense cluster one-to-many",
            filename: "27_dense_cluster",
            nodes: vec![
                InputNode {
                    id: tid(TableKind::INode, "hub"),
                    x: 270.0,
                    y: 210.0,
                    width: 120.0,
                    height: 90.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n0"),
                    x: 290.0,
                    y: 60.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n1"),
                    x: 390.0,
                    y: 70.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n2"),
                    x: 460.0,
                    y: 150.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n3"),
                    x: 460.0,
                    y: 300.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n4"),
                    x: 380.0,
                    y: 380.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n5"),
                    x: 270.0,
                    y: 390.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n6"),
                    x: 160.0,
                    y: 310.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n7"),
                    x: 160.0,
                    y: 140.0,
                    width: 60.0,
                    height: 40.0,
                    is_obstacle: true,
                },
            ],
            edges: vec![
                edge(
                    "e0",
                    "hub",
                    "n0",
                    Some(PortSide::Top),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e1",
                    "hub",
                    "n1",
                    Some(PortSide::TopRight),
                    Some(PortSide::Bottom),
                ),
                edge(
                    "e2",
                    "hub",
                    "n2",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e3",
                    "hub",
                    "n3",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e4",
                    "hub",
                    "n4",
                    Some(PortSide::BottomRight),
                    Some(PortSide::Top),
                ),
                edge(
                    "e5",
                    "hub",
                    "n5",
                    Some(PortSide::Bottom),
                    Some(PortSide::Top),
                ),
                edge(
                    "e6",
                    "hub",
                    "n6",
                    Some(PortSide::BottomLeft),
                    Some(PortSide::TopRight),
                ),
                edge(
                    "e7",
                    "hub",
                    "n7",
                    Some(PortSide::TopLeft),
                    Some(PortSide::BottomRight),
                ),
            ],
        },
        Scenario {
            label: "Opposite sides one-to-many",
            filename: "28_opposite_sides",
            nodes: vec![
                InputNode {
                    id: tid(TableKind::INode, "hub"),
                    x: 350.0,
                    y: 260.0,
                    width: 120.0,
                    height: 90.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_l0"),
                    x: 100.0,
                    y: 150.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_l1"),
                    x: 100.0,
                    y: 260.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_l2"),
                    x: 100.0,
                    y: 370.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_r0"),
                    x: 620.0,
                    y: 150.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_r1"),
                    x: 620.0,
                    y: 260.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
                InputNode {
                    id: tid(TableKind::INode, "n_r2"),
                    x: 620.0,
                    y: 370.0,
                    width: 80.0,
                    height: 50.0,
                    is_obstacle: true,
                },
            ],
            edges: vec![
                edge(
                    "e_l0",
                    "hub",
                    "n_l0",
                    Some(PortSide::Left),
                    Some(PortSide::Right),
                ),
                edge(
                    "e_l1",
                    "hub",
                    "n_l1",
                    Some(PortSide::Left),
                    Some(PortSide::Right),
                ),
                edge(
                    "e_l2",
                    "hub",
                    "n_l2",
                    Some(PortSide::Left),
                    Some(PortSide::Right),
                ),
                edge(
                    "e_r0",
                    "hub",
                    "n_r0",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e_r1",
                    "hub",
                    "n_r1",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
                edge(
                    "e_r2",
                    "hub",
                    "n_r2",
                    Some(PortSide::Right),
                    Some(PortSide::Left),
                ),
            ],
        },
    ];

    // Scenario 29: Multi-edge nudging
    scenarios.push(Scenario {
        label: "Multi-edge nudging (parallel edges between same nodes)",
        filename: "29_multi_edge_nudging",
        nodes: vec![
            node("a", 100.0, 200.0, 120.0, 80.0),
            node("b", 500.0, 200.0, 120.0, 80.0),
        ],
        edges: vec![
            edge("e1", "a", "b", Some(PortSide::Top), Some(PortSide::Top)),
            edge("e2", "a", "b", Some(PortSide::Top), Some(PortSide::Top)),
            edge("e3", "a", "b", Some(PortSide::Top), Some(PortSide::Top)),
        ],
    });

    // Scenario 30: Missing node fallback
    scenarios.push(Scenario {
        label: "Missing node fallback (graceful resolution on missing node ID)",
        filename: "30_missing_node_fallback",
        nodes: vec![node("a", 100.0, 200.0, 120.0, 80.0)],
        edges: vec![edge("e1", "a", "nonexistent", None, None)],
    });

    scenarios
}

struct SimpleRng {
    state: u64,
}

impl SimpleRng {
    fn new(seed: u64) -> Self {
        Self { state: seed }
    }

    fn next(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        self.state
    }

    fn next_f64(&mut self) -> f64 {
        (self.next() as f64) / (u64::MAX as f64)
    }

    fn next_range(&mut self, min: f64, max: f64) -> f64 {
        min + self.next_f64() * (max - min)
    }
}
