use crate::domain::base_models::{Comment, Coordinates, IsTable, Size};
use crate::domain::contents::Content;
use crate::domain::styles::{NodeLayout, NodeStyle};
use crate::domain::tags::TagEdge;
use surrealdb::types::{SurrealValue, Value};

pub trait IsNode {
    fn key(&self) -> &str;
    fn set_key(&mut self, key: String);

    fn position(&self) -> &Coordinates;
    fn position_mut(&mut self) -> &mut Coordinates;

    fn layer(&self) -> &str;
    fn set_layer(&mut self, layer: String);

    fn created_at(&self) -> i64;
    fn set_created_at(&mut self, val: i64);

    fn updated_at(&self) -> i64;
    fn set_updated_at(&mut self, val: i64);

    fn table_name(&self) -> &'static str;
    fn fields_value(&self) -> Value;
}

define_nodes! {
    INode, INodeFields, "INode", ["tags"];
    TaskNode, TaskNodeFields, "TaskNode", [];
    InterNode, InterNodeFields, "InterNode", [];
    CommentNode, CommentNodeFields, "CommentNode", [];
    DrawingNode, DrawingNodeFields, "DrawingNode", [];
    ShapeNode, ShapeNodeFields, "ShapeNode", [];
    FrameNode, FrameNodeFields, "FrameNode", [];
    MediaNode, MediaNodeFields, "MediaNode", [];
}

#[derive(Debug, Clone, SurrealValue)]
pub struct INodeFields {
    pub content: Content,
    pub style: Option<NodeStyle>,
    pub resolved_style: Option<NodeStyle>,
    pub layout: Option<NodeLayout>,
    pub resolved_layout: Option<NodeLayout>,
    pub layer: String,
    pub position: Coordinates,
    pub size: Size,
    pub line_count: i32,
    pub expandable: bool,
    pub is_expanded: bool,
    pub locked: bool,
    pub tags: Vec<TagEdge>,
    pub aliases: Vec<String>,
    pub comments: Vec<Comment>,
    pub attachment: Option<String>,
    pub significance: u8,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct TaskNodeFields {
    pub content: Content,
    pub due_date: Option<i64>,
    pub state: String,
    pub position: Coordinates,
    pub size: Size,
    pub expandable: bool,
    pub is_expanded: bool,
    pub layer: String,
    pub style: Option<NodeStyle>,
    pub resolved_style: Option<NodeStyle>,
    pub layout: Option<NodeLayout>,
    pub resolved_layout: Option<NodeLayout>,
    pub significance: u8,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct InterNodeFields {
    pub position: Coordinates,
    pub style: Option<String>,
    pub verb: String,
    pub behavioral_features: Option<String>,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct CommentNodeFields {
    pub text: String,
    pub position: Coordinates,
    pub size: Size,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct DrawingNodeFields {
    pub paths: Vec<String>,
    pub position: Coordinates,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct ShapeNodeFields {
    pub shape_type: String,
    pub style: Option<NodeStyle>,
    pub position: Coordinates,
    pub size: Size,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct FrameNodeFields {
    pub title: String,
    pub style: Option<NodeStyle>,
    pub position: Coordinates,
    pub size: Size,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct MediaNodeFields {
    pub source_url: String,
    pub media_type: String,
    pub position: Coordinates,
    pub size: Size,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}
