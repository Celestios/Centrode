use crate::domain::base_models::{Comment, Content, Coordinates};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct INode {
    // Type is String, with custom serialization logic
    #[serde(
        alias = "id",
        skip_serializing_if = "Option::is_none",
        with = "crate::domain::serde_helpers::option_thing_string"
    )]
    pub id: Option<String>,
    pub content: Content,
    pub aesthetics: Option<String>,
    pub position: Coordinates,
    pub locked: bool,
    pub tags: Vec<String>,
    pub aliases: Vec<String>,
    pub comments: Vec<Comment>,
    pub attachment: Option<String>,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskNode {
    // [CHANGED]
    #[serde(
        alias = "id",
        skip_serializing_if = "Option::is_none",
        with = "crate::domain::serde_helpers::option_thing_string"
    )]
    pub id: Option<String>,
    pub content: Content,
    pub due_date: Option<i64>,
    pub state: String, // e.g., "TODO", "DONE"
    pub position: Coordinates,
    pub aesthetics: Option<String>,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InterNode {
    #[serde(
        alias = "id",
        skip_serializing_if = "Option::is_none",
        with = "crate::domain::serde_helpers::option_thing_string"
    )]
    pub id: Option<String>,
    pub verb: String,
    pub behavioral_features: Option<String>, // e.g., "active", "inhibiting"
    pub position: Coordinates,
    pub aesthetics: Option<String>, // JSON string for distinct edge styling
    pub created_at: i64,
    pub updated_at: i64,
}

// The Enum passed from Flutter to create *any* node
#[derive(Debug, Clone)]
pub enum NodeInput {
    Info(INode),
    Task(TaskNode),
    Inter(InterNode),
}

// The Output Enum for fetching any node type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NodeOutput {
    Info(INode),
    Task(TaskNode),
    Inter(InterNode),
}

// Helper to extract the ID regardless of type
impl NodeOutput {
    pub fn id(&self) -> Option<String> {
        match self {
            // Now simply clone the string, no formatting needed
            NodeOutput::Info(n) => n.id.clone(),
            NodeOutput::Task(n) => n.id.clone(),
            NodeOutput::Inter(n) => n.id.clone(),
        }
    }
}
