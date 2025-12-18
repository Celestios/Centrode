use serde::{Deserialize, Serialize};

// Standard attributes all nodes share (optional for input, mandatory for output)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BaseNode {
    pub id: String,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct INode {
    pub text: Option<String>,
    pub visual_formatting: Option<String>,
    pub position: Option<u32>,
    pub layer: u8,
    pub locked: bool,
    pub tags: Vec<String>,
    pub aliases: Vec<String>,
    pub comments: Vec<String>,
    pub attachment: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskNode {
    pub text: Option<String>,
    pub due_date: Option<i64>,
    pub state: String, // e.g., "TODO", "DONE"
}

// The Enum passed from Flutter to create *any* node
#[derive(Debug, Clone)]
pub enum NodeInput {
    Info(INode),
    Task(TaskNode),
}

// [NEW] The Output Enum for fetching any node type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NodeOutput {
    Info(INode),
    Task(TaskNode),
    // Future types (e.g., LinkNode, GroupNode) go here
}

// [NEW] Helper to extract the ID regardless of type
impl NodeOutput {
    pub fn id(&self) -> Option<String> {
        match self {
            NodeOutput::Info(_) => None, 
            NodeOutput::Task(_) => None,
        }
    }
}