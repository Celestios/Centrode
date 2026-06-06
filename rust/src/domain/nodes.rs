use crate::domain::base_models::{Comment, Coordinates, IsTable, RecordStrings, Size};
use crate::domain::contents::Content;
use crate::domain::styles::{NodeLayout, NodeStyle};
use crate::domain::tags::TagEdge;
use surrealdb::types::{SurrealValue, Value};
pub use crate::domain::schema::{SurqlSchema, SurqlSchemaField, generate_field_schema_lines};

pub trait IsNode {
    fn id(&self) -> &RecordStrings;
    fn set_id(&mut self, id: RecordStrings);

    fn key(&self) -> &str {
        &self.id().key
    }

    fn set_key(&mut self, key: String) {
        let mut current_id = self.id().clone();
        current_id.key = key;
        self.set_id(current_id);
    }

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

define_nodes! {
    INode, "INode", ["tags"] {
        pub content: Content,
        pub style: Option<NodeStyle>,
        pub resolved_style: Option<NodeStyle>,
        pub layout: Option<NodeLayout>,
        pub resolved_layout: Option<NodeLayout>,
        pub size: Size,
        #[surql_default = "1"]
        pub line_count: i32,
        pub expandable: bool,
        pub is_expanded: bool,
        pub locked: bool,
        #[surql_type = "array<record<Tag>>"]
        pub tags: Vec<TagEdge>,
        #[surql_type = "array<string>"]
        pub aliases: Vec<String>,
        pub comments: Vec<Comment>,
        pub attachment: Option<String>,
        #[surql_default = "0"]
        pub significance: u8,
    };

    TaskNode, "TaskNode", [] {
        pub content: Content,
        pub due_date: Option<i64>,
        #[surql_type = "any"]
        pub state: String,
        pub size: Size,
        pub expandable: bool,
        pub is_expanded: bool,
        pub style: Option<NodeStyle>,
        pub resolved_style: Option<NodeStyle>,
        pub layout: Option<NodeLayout>,
        pub resolved_layout: Option<NodeLayout>,
        #[surql_default = "0"]
        pub significance: u8,
    };

    InterNode, "InterNode", [] {
        pub style: Option<String>,
        pub verb: String,
        pub behavioral_features: Option<String>,
    };

    CommentNode, "CommentNode", [] {
        pub text: String,
        pub size: Size,
    };

    DrawingNode, "DrawingNode", [] {
        pub paths: Vec<String>,
        pub brush_type: String,
        pub brush_thickness: f64,
        pub brush_color: String,
        pub size: Size,
        pub locked: bool,
    };

    ShapeNode, "ShapeNode", [] {
        pub shape_type: String,
        pub style: Option<NodeStyle>,
        pub size: Size,
    };

    FrameNode, "FrameNode", [] {
        pub title: String,
        pub style: Option<NodeStyle>,
        pub size: Size,
    };

    MediaNode, "MediaNode", [] {
        pub source_url: String,
        pub media_type: String,
        pub size: Size,
    };
}


