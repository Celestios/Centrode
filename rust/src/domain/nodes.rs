use crate::domain::base_models::{Comment, Coordinates, IsTable, Size};
use crate::domain::contents::Content;
use crate::domain::styles::{NodeLayout, NodeStyle};
use crate::domain::tags::TagEdge;
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, SurrealValue)]
pub struct INode {
    pub key: String,
    pub fields: INodeFields,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct TaskNode {
    pub key: String,
    pub fields: TaskNodeFields,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct InterNode {
    pub key: String,
    pub fields: InterNodeFields,
}

impl IsTable for INode {
    const LABEL: &'static str = "INode";

    fn get_key(&self) -> &str {
        &self.key
    }
}
impl IsTable for TaskNode {
    const LABEL: &'static str = "TaskNode";

    fn get_key(&self) -> &str {
        &self.key
    }
}
impl IsTable for InterNode {
    const LABEL: &'static str = "InterNode";

    fn get_key(&self) -> &str {
        &self.key
    }
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
    pub verb: String,
    pub behavioral_features: Option<String>,
    pub position: Coordinates,
    pub style: Option<String>,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, SurrealValue)]
pub enum Nodes {
    INode(INode),
    TaskNode(TaskNode),
    InterNode(InterNode),
}

impl Nodes {
    pub fn table_and_key(&self) -> (&'static str, &str) {
        match self {
            Nodes::INode(n) => (INode::LABEL, &n.key),
            Nodes::TaskNode(n) => (TaskNode::LABEL, &n.key),
            Nodes::InterNode(n) => (InterNode::LABEL, &n.key),
        }
    }
}
