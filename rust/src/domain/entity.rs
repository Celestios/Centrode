use crate::domain::base_models::*;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::*;
use crate::domain::relations::*;
use crate::domain::tags::*;
use crate::domain::templates::*;
use crate::domain::theme::*;
use crate::persistence::history::HistoryRecord;
use surrealdb::types::{SurrealValue, Value};

/// Single sum type for heterogeneous canvas nodes.
#[derive(Debug, Clone, SurrealValue)]
pub enum Nodes {
    INode(INode),
    TaskNode(TaskNode),
    InterNode(InterNode),
    CommentNode(CommentNode),
    DrawingNode(DrawingNode),
    ShapeNode(ShapeNode),
    FrameNode(FrameNode),
    MediaNode(MediaNode),
}

impl Nodes {
    pub const TABLES: &'static [&'static str] = &[
        "INode",
        "TaskNode",
        "InterNode",
        "CommentNode",
        "DrawingNode",
        "ShapeNode",
        "FrameNode",
        "MediaNode",
    ];

    pub fn generate_all_fields_schemas() -> Vec<(&'static str, Vec<String>)> {
        vec![
            ("INode", INode::generate_fields_schema(INode::LABEL)),
            ("TaskNode", TaskNode::generate_fields_schema(TaskNode::LABEL)),
            ("InterNode", InterNode::generate_fields_schema(InterNode::LABEL)),
            ("CommentNode", CommentNode::generate_fields_schema(CommentNode::LABEL)),
            ("DrawingNode", DrawingNode::generate_fields_schema(DrawingNode::LABEL)),
            ("ShapeNode", ShapeNode::generate_fields_schema(ShapeNode::LABEL)),
            ("FrameNode", FrameNode::generate_fields_schema(FrameNode::LABEL)),
            ("MediaNode", MediaNode::generate_fields_schema(MediaNode::LABEL)),
        ]
    }

    pub fn fetch_fields_for_table(_table: &str) -> Vec<String> {
        vec![]
    }

    pub fn from_struct_value(table: &str, value: Value) -> Result<Self, anyhow::Error> {
        match table {
            "INode" => Ok(Nodes::INode(INode::from_value(value)?)),
            "TaskNode" => Ok(Nodes::TaskNode(TaskNode::from_value(value)?)),
            "InterNode" => Ok(Nodes::InterNode(InterNode::from_value(value)?)),
            "CommentNode" => Ok(Nodes::CommentNode(CommentNode::from_value(value)?)),
            "DrawingNode" => Ok(Nodes::DrawingNode(DrawingNode::from_value(value)?)),
            "ShapeNode" => Ok(Nodes::ShapeNode(ShapeNode::from_value(value)?)),
            "FrameNode" => Ok(Nodes::FrameNode(FrameNode::from_value(value)?)),
            "MediaNode" => Ok(Nodes::MediaNode(MediaNode::from_value(value)?)),
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
            Self::INode(n) => n.id(),
            Self::TaskNode(n) => n.id(),
            Self::InterNode(n) => n.id(),
            Self::CommentNode(n) => n.id(),
            Self::DrawingNode(n) => n.id(),
            Self::ShapeNode(n) => n.id(),
            Self::FrameNode(n) => n.id(),
            Self::MediaNode(n) => n.id(),
        }
    }

    fn set_id(&mut self, id: TypedRecordId) {
        match self {
            Self::INode(n) => n.set_id(id),
            Self::TaskNode(n) => n.set_id(id),
            Self::InterNode(n) => n.set_id(id),
            Self::CommentNode(n) => n.set_id(id),
            Self::DrawingNode(n) => n.set_id(id),
            Self::ShapeNode(n) => n.set_id(id),
            Self::FrameNode(n) => n.set_id(id),
            Self::MediaNode(n) => n.set_id(id),
        }
    }

    fn position(&self) -> &Coordinates {
        match self {
            Self::INode(n) => n.position(),
            Self::TaskNode(n) => n.position(),
            Self::InterNode(n) => n.position(),
            Self::CommentNode(n) => n.position(),
            Self::DrawingNode(n) => n.position(),
            Self::ShapeNode(n) => n.position(),
            Self::FrameNode(n) => n.position(),
            Self::MediaNode(n) => n.position(),
        }
    }

    fn position_mut(&mut self) -> &mut Coordinates {
        match self {
            Self::INode(n) => n.position_mut(),
            Self::TaskNode(n) => n.position_mut(),
            Self::InterNode(n) => n.position_mut(),
            Self::CommentNode(n) => n.position_mut(),
            Self::DrawingNode(n) => n.position_mut(),
            Self::ShapeNode(n) => n.position_mut(),
            Self::FrameNode(n) => n.position_mut(),
            Self::MediaNode(n) => n.position_mut(),
        }
    }

    fn layer(&self) -> &str {
        match self {
            Self::INode(n) => n.layer(),
            Self::TaskNode(n) => n.layer(),
            Self::InterNode(n) => n.layer(),
            Self::CommentNode(n) => n.layer(),
            Self::DrawingNode(n) => n.layer(),
            Self::ShapeNode(n) => n.layer(),
            Self::FrameNode(n) => n.layer(),
            Self::MediaNode(n) => n.layer(),
        }
    }

    fn set_layer(&mut self, layer: String) {
        match self {
            Self::INode(n) => n.set_layer(layer),
            Self::TaskNode(n) => n.set_layer(layer),
            Self::InterNode(n) => n.set_layer(layer),
            Self::CommentNode(n) => n.set_layer(layer),
            Self::DrawingNode(n) => n.set_layer(layer),
            Self::ShapeNode(n) => n.set_layer(layer),
            Self::FrameNode(n) => n.set_layer(layer),
            Self::MediaNode(n) => n.set_layer(layer),
        }
    }

    fn created_at(&self) -> i64 {
        match self {
            Self::INode(n) => n.created_at(),
            Self::TaskNode(n) => n.created_at(),
            Self::InterNode(n) => n.created_at(),
            Self::CommentNode(n) => n.created_at(),
            Self::DrawingNode(n) => n.created_at(),
            Self::ShapeNode(n) => n.created_at(),
            Self::FrameNode(n) => n.created_at(),
            Self::MediaNode(n) => n.created_at(),
        }
    }

    fn set_created_at(&mut self, val: i64) {
        match self {
            Self::INode(n) => n.set_created_at(val),
            Self::TaskNode(n) => n.set_created_at(val),
            Self::InterNode(n) => n.set_created_at(val),
            Self::CommentNode(n) => n.set_created_at(val),
            Self::DrawingNode(n) => n.set_created_at(val),
            Self::ShapeNode(n) => n.set_created_at(val),
            Self::FrameNode(n) => n.set_created_at(val),
            Self::MediaNode(n) => n.set_created_at(val),
        }
    }

    fn updated_at(&self) -> i64 {
        match self {
            Self::INode(n) => n.updated_at(),
            Self::TaskNode(n) => n.updated_at(),
            Self::InterNode(n) => n.updated_at(),
            Self::CommentNode(n) => n.updated_at(),
            Self::DrawingNode(n) => n.updated_at(),
            Self::ShapeNode(n) => n.updated_at(),
            Self::FrameNode(n) => n.updated_at(),
            Self::MediaNode(n) => n.updated_at(),
        }
    }

    fn set_updated_at(&mut self, val: i64) {
        match self {
            Self::INode(n) => n.set_updated_at(val),
            Self::TaskNode(n) => n.set_updated_at(val),
            Self::InterNode(n) => n.set_updated_at(val),
            Self::CommentNode(n) => n.set_updated_at(val),
            Self::DrawingNode(n) => n.set_updated_at(val),
            Self::ShapeNode(n) => n.set_updated_at(val),
            Self::FrameNode(n) => n.set_updated_at(val),
            Self::MediaNode(n) => n.set_updated_at(val),
        }
    }

    fn table_name(&self) -> &'static str {
        match self {
            Self::INode(n) => n.table_name(),
            Self::TaskNode(n) => n.table_name(),
            Self::InterNode(n) => n.table_name(),
            Self::CommentNode(n) => n.table_name(),
            Self::DrawingNode(n) => n.table_name(),
            Self::ShapeNode(n) => n.table_name(),
            Self::FrameNode(n) => n.table_name(),
            Self::MediaNode(n) => n.table_name(),
        }
    }

    fn serialize_node(self) -> Value {
        match self {
            Self::INode(n) => n.serialize_node(),
            Self::TaskNode(n) => n.serialize_node(),
            Self::InterNode(n) => n.serialize_node(),
            Self::CommentNode(n) => n.serialize_node(),
            Self::DrawingNode(n) => n.serialize_node(),
            Self::ShapeNode(n) => n.serialize_node(),
            Self::FrameNode(n) => n.serialize_node(),
            Self::MediaNode(n) => n.serialize_node(),
        }
    }
}

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
