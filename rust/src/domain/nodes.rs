use crate::domain::base_models::Coordinates;
use crate::domain::id::TypedRecordId;
pub use crate::domain::schema::{generate_field_schema_lines, SurqlSchema, SurqlSchemaField};
pub use crate::domain::base_models::Attachment;
pub use crate::domain::types::{
    CommentNode, ContainerNode, DrawingNode, FrameNode, INode, InterNode, MediaNode, Nodes, ShapeNode, TaskNode,
};
use centrode_macros::SurrealDbEnum;
use surrealdb::types::Value;

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum TaskState {
    Todo = 0,
    InProgress = 1,
    Done = 2,
    Blocked = 3,
    Cancelled = 4,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum ShapeType {
    Rectangle = 0,
    Circle = 1,
    Diamond = 2,
    Triangle = 3,
    Star = 4,
    Pill = 5,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum BrushType {
    Pencil = 0,
    Highlighter = 1,
    Eraser = 2,
    Calligraphy = 3,
}

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum MediaType {
    Image = 0,
    Video = 1,
    Audio = 2,
    Pdf = 3,
}

pub trait IsNode {
    fn id(&self) -> &TypedRecordId;
    fn set_id(&mut self, id: TypedRecordId);

    fn parent_container_id(&self) -> Option<&TypedRecordId>;
    fn set_parent_container_id(&mut self, val: Option<TypedRecordId>);

    fn position(&self) -> &Coordinates;
    fn position_mut(&mut self) -> &mut Coordinates;

    fn layer(&self) -> &str;
    fn set_layer(&mut self, layer: String);

    fn created_at(&self) -> i64;
    fn set_created_at(&mut self, val: i64);

    fn updated_at(&self) -> i64;
    fn set_updated_at(&mut self, val: i64);

    fn table_name(&self) -> &'static str;

    fn serialize_node(self) -> Value;
}

impl Nodes {
    pub fn dimensions(&self) -> (f64, f64) {
        match self {
            Nodes::INode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::TaskNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::CommentNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::DrawingNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::ShapeNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::FrameNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::MediaNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::ContainerNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::InterNode(_) => (0.0, 0.0),
        }
    }
}

