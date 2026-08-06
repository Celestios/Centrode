//! Domain Type Declarations
//! =======================
//!
//! Declarative source of truth for domain model structs. 
//!
//! Invariants & Generation Contract:
//! ----------------------------------
//! - All domain entity models are declared inside `define_domain_types!`.
//! - The macro parses these declarations to generate concrete struct definitions, sum-type 
//!   union enums (`Nodes`, `Relations`), and automated trait implementations (`IsNode`, 
//!   `DomainEntity`, `SurqlSchema`, `SurrealValue`).
//! - Adding or modifying an entity struct within `define_domain_types!` automatically updates 
//!   the sum-type union enums and trait implementations. Do not manually create wrapper 
//!   modules for individual entities or variants.

use crate::domain::base_models::{BoundingBox, Comment, DisplayMode, Size, ViewportState};
use crate::domain::contents::Content;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{BrushType, MediaType, ShapeType, TaskState};
use crate::domain::relations::IRelationFields;
use crate::domain::styles::{NodeLayout, NodeStyle};
use crate::domain::tags::{TagEdge, TagFields};
use crate::domain::theme::ThemeFields;
use centrode_macros::define_domain_types;
use surrealdb::types::SurrealValue;

define_domain_types! {
    // -------------------------------------------------------------------------
    // NODES
    // -------------------------------------------------------------------------
    #[category(node)]
    #[table(label = "INode", fetch = ["tags"])]
    pub struct INode {
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
    }

    #[category(node)]
    pub struct TaskNode {
        pub content: Content,
        pub due_date: Option<i64>,
        pub state: TaskState,
        pub size: Size,
        pub expandable: bool,
        pub is_expanded: bool,
        pub style: Option<NodeStyle>,
        pub resolved_style: Option<NodeStyle>,
        pub layout: Option<NodeLayout>,
        pub resolved_layout: Option<NodeLayout>,
        #[surql_default = "0"]
        pub significance: u8,
    }

    #[category(node)]
    pub struct InterNode {
        pub style: Option<String>,
        pub verb: String,
        pub behavioral_features: Option<String>,
    }

    #[category(node)]
    pub struct CommentNode {
        pub text: String,
        pub size: Size,
    }

    #[category(node)]
    pub struct DrawingNode {
        pub paths: Vec<String>,
        pub brush_type: BrushType,
        pub brush_thickness: f64,
        pub brush_color: String,
        pub size: Size,
        pub locked: bool,
    }

    #[category(node)]
    pub struct ShapeNode {
        pub shape_type: ShapeType,
        pub style: Option<NodeStyle>,
        pub size: Size,
    }

    #[category(node)]
    pub struct FrameNode {
        pub title: String,
        pub style: Option<NodeStyle>,
        pub size: Size,
    }

    #[category(node)]
    pub struct MediaNode {
        pub source_url: String,
        pub media_type: MediaType,
        pub size: Size,
    }

    // -------------------------------------------------------------------------
    // RELATIONS
    // -------------------------------------------------------------------------
    #[category(relation)]
    pub struct IRelation {
        pub fields: IRelationFields,
    }

    // -------------------------------------------------------------------------
    // AUXILIARY
    // -------------------------------------------------------------------------
    #[category(auxiliary)]
    pub struct Tag {
        pub fields: TagFields,
    }

    #[category(auxiliary)]
    pub struct MapTheme {
        pub fields: ThemeFields,
    }

    #[category(auxiliary)]
    #[table(no_key)]
    pub struct MapData {
        pub map_name: String,
        pub viewport_state: ViewportState,
        pub active_theme_id: Option<String>,
        pub display_mode: DisplayMode,
        pub opt_area: Option<BoundingBox>,
    }

    #[category(auxiliary)]
    pub struct History {
        pub patch_data: Vec<u8>,
        pub created_at: i64,
    }

    #[category(auxiliary)]
    pub struct Template {
        pub name: String,
        pub created_at: i64,
        pub updated_at: i64,
        pub nodes: Vec<Nodes>,
        pub relations: Vec<IRelation>,
    }
}

impl Tag {
    pub fn new(key: TypedRecordId, name: String, color: u32) -> Self {
        let now = chrono::Utc::now().timestamp_millis();
        Self {
            key,
            fields: TagFields {
                name,
                color,
                created_at: now,
                updated_at: now,
            },
        }
    }
}

impl MapTheme {
    pub fn new(key: TypedRecordId, fields: ThemeFields) -> Self {
        Self { key, fields }
    }
}
