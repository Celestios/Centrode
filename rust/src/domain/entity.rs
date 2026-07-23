use crate::domain::base_models::*;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::*;
use crate::domain::relations::*;
use crate::domain::tags::*;
use crate::domain::templates::*;
use crate::domain::theme::*;
use crate::persistence::history::HistoryRecord;
use surrealdb::types::{SurrealValue, Value};

macro_rules! register_domain_entities {
    ($( $variant:ident ),+ $(,)?) => {
        #[derive(Debug, Clone, SurrealValue)]
        pub enum Nodes {
            $( $variant($variant), )+
        }

        impl Nodes {
            pub const TABLES: &'static [&'static str] = &[
                $( stringify!($variant), )+
            ];

            pub fn generate_all_fields_schemas() -> Vec<(&'static str, Vec<String>)> {
                vec![
                    $( (stringify!($variant), $variant::generate_fields_schema($variant::LABEL)), )+
                ]
            }

            pub fn fetch_fields_for_table(_table: &str) -> Vec<String> {
                vec![]
            }

            pub fn from_struct_value(table: &str, value: Value) -> Result<Self, anyhow::Error> {
                match table {
                    $( stringify!($variant) => Ok(Nodes::$variant($variant::from_value(value)?)), )+
                    other => Err(anyhow::anyhow!("Unknown node table: {}", other)),
                }
            }

            pub fn table_and_key(&self) -> (&'static str, String) {
                (self.table_name(), self.id().to_string())
            }
        }

        impl IsNode for Nodes {
            fn id(&self) -> &TypedRecordId {
                match self {
                    $( Self::$variant(n) => n.id(), )+
                }
            }

            fn set_id(&mut self, id: TypedRecordId) {
                match self {
                    $( Self::$variant(n) => n.set_id(id), )+
                }
            }

            fn position(&self) -> &Coordinates {
                match self {
                    $( Self::$variant(n) => n.position(), )+
                }
            }

            fn position_mut(&mut self) -> &mut Coordinates {
                match self {
                    $( Self::$variant(n) => n.position_mut(), )+
                }
            }

            fn layer(&self) -> &str {
                match self {
                    $( Self::$variant(n) => n.layer(), )+
                }
            }

            fn set_layer(&mut self, layer: String) {
                match self {
                    $( Self::$variant(n) => n.set_layer(layer), )+
                }
            }

            fn created_at(&self) -> i64 {
                match self {
                    $( Self::$variant(n) => n.created_at(), )+
                }
            }

            fn set_created_at(&mut self, val: i64) {
                match self {
                    $( Self::$variant(n) => n.set_created_at(val), )+
                }
            }

            fn updated_at(&self) -> i64 {
                match self {
                    $( Self::$variant(n) => n.updated_at(), )+
                }
            }

            fn set_updated_at(&mut self, val: i64) {
                match self {
                    $( Self::$variant(n) => n.set_updated_at(val), )+
                }
            }

            fn table_name(&self) -> &'static str {
                match self {
                    $( Self::$variant(n) => n.table_name(), )+
                }
            }

            fn serialize_node(self) -> Value {
                match self {
                    $( Self::$variant(n) => n.serialize_node(), )+
                }
            }
        }
    };
}

register_domain_entities!(
    INode,
    TaskNode,
    InterNode,
    CommentNode,
    DrawingNode,
    ShapeNode,
    FrameNode,
    MediaNode,
);

/// Single sum type for relation edges.
#[derive(Debug, Clone, SurrealValue)]
pub enum Relations {
    IRelation(IRelation),
}

/// Single sum type for auxiliary workspace & system entities.
#[derive(Debug, Clone, SurrealValue)]
pub enum Auxiliary {
    Tag(Tag),
    MapTheme(Theme),
    MapData(MapData),
    History(HistoryRecord),
    Template(Template),
}

/// Top-level sum type for generic FFI stream events.
#[derive(Debug, Clone, SurrealValue)]
pub enum DomainEntity {
    Node(Nodes),
    Relation(Relations),
    Auxiliary(Auxiliary),
}
